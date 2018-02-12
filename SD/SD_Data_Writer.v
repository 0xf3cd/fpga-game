`include "./Head.v"
`include "./SD/SD_Write_Executer.v"

module SD_Data_Writer#(parameter DATA_TO_WRITE_LENGTH=16)(CLK,DO,RESET,DATA_TO_WRITE,WRITE_START,DI,WRITE_FINISH);
	input CLK;
	input DO;
	input RESET;
	input [DATA_TO_WRITE_LENGTH-1:0]DATA_TO_WRITE;
	input WRITE_START;
	output DI;
	output reg WRITE_FINISH;

	/*
	模块功能：
	每次使用前必须复位！
	WRITE_START有效时，开始向SD卡写入数据
	写入完毕后WRITE_FINISH置为1
	*/

	reg DO_rise=0;
	reg DO_rise_reset=0;
	always @(posedge DO or posedge DO_rise_reset)begin
		if(DO_rise_reset)begin
			DO_rise<=0;
		end
		else begin
			DO_rise<=1;
		end
	end

	/*
	START有效时，开始发送数据
	由于CMD24写指令的要求，先将DI置0，而后开始发送需要写入的数据
	写入完毕WRITE_FINISH置1
	*/
	reg sender_start=0;
	wire sender_finish;
	SD_Write_Executer #(.DATA_TO_WRITE_LENGTH(DATA_TO_WRITE_LENGTH))sender(.CLK(CLK),
																 		   .START(sender_start),
																		   .DATA_TO_WRITE(DATA_TO_WRITE),
																           .DI(DI),
																		   .WRITE_FINISH(sender_finish));
	
	parameter IDLE=2'b00;
	parameter WRITE=2'b01;
	parameter WAIT_DO_HIGH=2'b11;
	parameter FINISH=2'b10;

	reg [1:0]current_state=IDLE;
	reg [1:0]next_state;

	always @(posedge CLK or posedge RESET)begin
		if(RESET)begin
			current_state<=IDLE;
		end
		else begin
			current_state<=next_state;
		end	
	end

	
	always @(current_state or WRITE_START or sender_finish or DO_rise)begin
		case(current_state)
			IDLE:begin
				if(WRITE_START)begin
					next_state=WRITE;
				end
				else begin
					next_state=IDLE;
				end
			end
			WRITE:begin
				if(sender_finish)begin
					next_state=WAIT_DO_HIGH;
				end
				else begin
					next_state=WRITE;
				end
			end
			WAIT_DO_HIGH:begin
				if(DO_rise)begin
					next_state=FINISH;
				end
				else begin
					next_state=WAIT_DO_HIGH;
				end
			end
			FINISH:begin
				next_state=FINISH;
			end
			default:begin
				next_state=IDLE;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			IDLE:begin
				DO_rise_reset<=0;
			end
			WRITE:begin
				DO_rise_reset<=1;//利用其上升沿，使DO_rise复位
			end
			WAIT_DO_HIGH:begin
				DO_rise_reset<=0;
			end
			FINISH:begin
				DO_rise_reset<=0;
			end
			default:begin
				DO_rise_reset<=0;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			IDLE:begin
				sender_start<=0;
			end
			WRITE:begin
				sender_start<=1;
			end
			WAIT_DO_HIGH:begin
				sender_start<=0;
			end
			FINISH:begin
				sender_start<=0;
			end
			default:begin
				sender_start<=0;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			IDLE:begin
				WRITE_FINISH<=0;
			end
			WRITE:begin
				WRITE_FINISH<=0;
			end
			WAIT_DO_HIGH:begin
				WRITE_FINISH<=0;
			end
			FINISH:begin
				WRITE_FINISH<=1;
			end
			default:begin
				WRITE_FINISH<=0;
			end
		endcase
	end
endmodule