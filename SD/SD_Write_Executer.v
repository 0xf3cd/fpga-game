`include "./Head.v"
`include "./Tools/Shift_Register_N_bits.v"

module SD_Write_Executer #(parameter DATA_TO_WRITE_LENGTH=16)(CLK,START,DATA_TO_WRITE,DI,WRITE_FINISH);
	input CLK;
	input START;
	input [DATA_TO_WRITE_LENGTH-1:0]DATA_TO_WRITE;
	output reg DI=1;
	output reg WRITE_FINISH=0;

	/*
	START有效时，开始发送数据
	由于CMD24写指令的要求，先将DI置0，而后开始发送需要写入的数据
	写入完毕WRITE_FINISH置1
	*/

	reg saver_enable=0;
	reg saver_reset=0;
	wire saver_out;
	Shift_Register_N_bits #(.WIDTH(DATA_TO_WRITE_LENGTH))saver(CLK,saver_enable,saver_reset,DATA_TO_WRITE,1'b1,saver_out);

	reg counter_enable=0;
	reg counter_reset=0;
	wire [12:0]counter_result;
	Counter #(.WIDTH(13)) counter(~CLK,counter_enable,counter_reset,counter_result);//下降沿计数


	parameter IDLE=3'b000;
	parameter LOAD=3'b001;
	parameter WRITE_VALID_DATA=3'b011;
	parameter WRITE_REST_DATA=3'b010;
	parameter FINISH=3'b110;

	reg [2:0]current_state=IDLE;
	reg [2:0]next_state;
	
	always @(negedge CLK)begin
		current_state<=next_state;
	end

	always @(current_state or START or counter_result)begin
		case(current_state)
			IDLE:begin
				if(START)begin
					next_state=LOAD;
				end
				else begin
					next_state=IDLE;
				end
			end
			LOAD:begin
				next_state=WRITE_VALID_DATA;
			end
			WRITE_VALID_DATA:begin
				if(counter_result==DATA_TO_WRITE_LENGTH)begin
					next_state=WRITE_REST_DATA;
				end
				else begin
					next_state=WRITE_VALID_DATA;
				end
			end
			WRITE_REST_DATA:begin
				if(counter_result==13'd4096)begin
					next_state=FINISH;
				end
				else begin
					next_state=WRITE_REST_DATA;
				end
			end
			FINISH:begin
				next_state=IDLE;
			end
			default:begin
				next_state=IDLE;
			end
		endcase
	end

	always @(negedge CLK)begin
		case(next_state)
			IDLE:begin
				WRITE_FINISH<=0;
			end
			LOAD:begin
				WRITE_FINISH<=0;
			end
			WRITE_VALID_DATA:begin
				WRITE_FINISH<=0;
			end
			WRITE_REST_DATA:begin
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

	//计数器控制部分
	always @(negedge CLK)begin
		case(next_state)
			IDLE:begin
				counter_reset<=1;
				counter_enable<=0;
			end
			LOAD:begin
				counter_reset<=0;
				counter_enable<=1;
			end
			WRITE_VALID_DATA:begin
				counter_reset<=0;
				counter_enable<=1;
			end
			WRITE_REST_DATA:begin
				counter_reset<=0;
				counter_enable<=1;
			end
			FINISH:begin
				counter_reset<=1;
				counter_enable<=0;
			end
			default:begin
				counter_reset<=1;
				counter_enable<=0;
			end
		endcase
	end

	//saver控制部分
	always @(negedge CLK)begin
		case(next_state)
			IDLE:begin
				saver_reset<=1;
				saver_enable<=0;
			end
			LOAD:begin
				saver_reset<=1;
				saver_enable<=0;
			end
			WRITE_VALID_DATA:begin
				saver_reset<=0;
				saver_enable<=1;
			end
			WRITE_REST_DATA:begin
				saver_reset<=0;
				saver_enable<=1;
			end
			FINISH:begin
				saver_reset<=1;
				saver_enable<=0;
			end
			default:begin
				saver_reset<=1;
				saver_enable<=0;
			end
		endcase
	end

	always @(negedge CLK)begin
		case(next_state)
			IDLE:begin
				DI<=1;
			end
			LOAD:begin
				DI<=0;
			end
			WRITE_VALID_DATA:begin
				DI<=saver_out;
			end
			WRITE_REST_DATA:begin
				DI<=1;
			end
			FINISH:begin
				DI<=1;
			end
			default:begin
				DI<=1;
			end
		endcase
	end
endmodule