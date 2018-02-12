`include "./Head.v"

module SD_Command_Sender(CLK,ENABLE,RESET,RESET_VALUE,OUT,FINISH);//下降沿发送数据
	input CLK;
	input ENABLE;
	input RESET;
	input [47:0]RESET_VALUE;
	output reg OUT=1;
	output reg FINISH=0;

	/*
	*当RESET有效时，RESET_VALUE的值将在时钟下降沿被打入命令发送队列
	*之后ENABLE有效则开始在时钟下降沿逐位发送数据
	*发送完毕后FINISH置为1
	*/

	reg send_counter_enable=0;
	reg send_counter_reset=0;
	wire [5:0]send_counter_result;
	wire send_finish;

	Counter #(.WIDTH(6)) send_counter(~CLK,send_counter_enable,send_counter_reset,send_counter_result);
	assign send_finish=(send_counter_result==6'd48);


	reg send_enable=0;
	reg [47:0]cmd_saver;
	always @(negedge CLK or posedge RESET)begin//在下降沿写入数据，避免竞争冒险
		if(RESET)begin
			OUT<=1;
			cmd_saver<=RESET_VALUE;
		end
		else begin
			if(send_enable)begin
				OUT<=cmd_saver[47];
				cmd_saver<={cmd_saver[46:0],1'b1};
			end
			else begin
				OUT<=OUT;
				cmd_saver<=cmd_saver;
			end
		end
	end

	parameter IDLE=2'b00;
	parameter SEND_CMD=2'b01;
	parameter SEND_CMD_FINISH=2'b11;

	reg [1:0]current_state=IDLE;
	reg [1:0]next_state;

	always @(negedge CLK)begin
		current_state<=next_state;
	end

	always @(current_state or ENABLE or send_finish)begin
		case(current_state)
			IDLE:begin
				if(ENABLE)begin
					next_state=SEND_CMD;
				end
				else begin
					next_state=IDLE;
				end
			end
			SEND_CMD:begin
				if(send_finish)begin
					next_state=SEND_CMD_FINISH;
				end
				else begin
					next_state=SEND_CMD;
				end
			end
			SEND_CMD_FINISH:begin
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
				send_counter_reset<=1;
				send_counter_enable<=0;
			end
			SEND_CMD:begin
				send_counter_reset<=0;
				send_counter_enable<=1;
			end
			SEND_CMD_FINISH:begin
				send_counter_reset<=1;
				send_counter_enable<=0;
			end
			default:begin
				send_counter_reset<=1;
				send_counter_enable<=0;
			end
		endcase	
	end

	always @(negedge CLK)begin
		case(next_state)
			IDLE:begin
				send_enable<=0;
			end
			SEND_CMD:begin
				send_enable<=1;
			end
			SEND_CMD_FINISH:begin
				send_enable<=0;
			end
			default:begin
				send_enable<=0;
			end
		endcase	
	end

	always @(negedge CLK)begin
		case(next_state)
			IDLE:begin
				FINISH<=0;
			end
			SEND_CMD:begin
				FINISH<=0;
			end
			SEND_CMD_FINISH:begin
				FINISH<=1;
			end
			default:begin
				FINISH<=0;
			end
		endcase	
	end
endmodule