`include "./Head.v"

module Scores_Reader(CLK,TO_GET,RESET,SD_HAS_INITIALIZED,SD_IS_READING,READ_DATA,SD_TO_READ,READ_FINISH,SD_READ_ADDRESS,PREVIOUS_SCORES);
	input CLK;
	input TO_GET;
	input RESET;
	input SD_HAS_INITIALIZED;
	input SD_IS_READING;
	input [15:0]READ_DATA;
	output reg SD_TO_READ;
	output reg READ_FINISH;
	output [31:0]SD_READ_ADDRESS;
	output [15:0]PREVIOUS_SCORES;

	/*
	用于读取之前游戏最高分
	TO_GET有效时开始读取
	最终读到的数据由PREVIOUS_SCORED输出
	RESET有效时回到等待读取状态
	*/

	assign SD_READ_ADDRESS=`SCORES_READ_ADDRESS;

	reg [15:0]scores_saver=0;
	assign PREVIOUS_SCORES=scores_saver;

	parameter WAIT_TO_GET=3'b000;
	parameter REQUEST=3'b001;
	parameter WAIT_SD_READ_FINISH=3'b011;
	parameter STORE=3'b010;
	parameter STORE_FINISH=3'b110;

	reg [2:0]current_state=WAIT_TO_GET;
	reg [2:0]next_state;

	always @(posedge CLK)begin
		if(RESET)begin
			current_state<=WAIT_TO_GET;
		end
		else begin
			current_state<=next_state;
		end
	end

	always @(current_state or TO_GET or SD_HAS_INITIALIZED or SD_IS_READING)begin
		case(current_state)
			WAIT_TO_GET:begin
				if(TO_GET&SD_HAS_INITIALIZED&(~SD_IS_READING))begin
					next_state=REQUEST;
				end
				else begin
					next_state=WAIT_TO_GET;
				end
			end
			REQUEST:begin
				if(SD_IS_READING)begin
					next_state=WAIT_SD_READ_FINISH;
				end
				else begin
					next_state=REQUEST;
				end
			end
			WAIT_SD_READ_FINISH:begin
				if(~SD_IS_READING)begin//读取完毕
					next_state=STORE;
				end
				else begin
					next_state=WAIT_SD_READ_FINISH;
				end
			end
			STORE:begin
				next_state=STORE_FINISH;
			end
			STORE_FINISH:begin
				next_state=STORE_FINISH;
			end
			default:begin
				next_state=WAIT_TO_GET;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_TO_GET:begin
				SD_TO_READ<=0;
			end
			REQUEST:begin
				SD_TO_READ<=1;
			end
			WAIT_SD_READ_FINISH:begin
				SD_TO_READ<=0;
			end
			STORE:begin
				SD_TO_READ<=0;
			end
			STORE_FINISH:begin
				SD_TO_READ<=0;
			end
			default:begin
				SD_TO_READ<=0;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_TO_GET:begin
				READ_FINISH<=0;
			end
			REQUEST:begin
				READ_FINISH<=0;
			end
			WAIT_SD_READ_FINISH:begin
				READ_FINISH<=0;
			end
			STORE:begin
				READ_FINISH<=0;
			end
			STORE_FINISH:begin
				READ_FINISH<=1;
			end
			default:begin
				READ_FINISH<=0;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_TO_GET:begin
				scores_saver<=0;
			end
			REQUEST:begin
				scores_saver<=0;
			end
			WAIT_SD_READ_FINISH:begin
				scores_saver<=0;
			end
			STORE:begin
				scores_saver<=READ_DATA;
			end
			STORE_FINISH:begin
				scores_saver<=scores_saver;
			end
			default:begin
				scores_saver<=0;
			end
		endcase
	end
endmodule