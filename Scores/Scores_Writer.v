`include "./Head.v"

module Scores_Writer(CLK,TO_WRITE,RESET,SD_HAS_INITIALIZED,SD_IS_WRITING,SCORES_TO_WRITE,SD_TO_WRITE,WRITE_FINISH,SD_WRITE_ADDRESS,DATA_TO_WRITE);
	input CLK;
	input TO_WRITE;
	input RESET;
	input SD_HAS_INITIALIZED;
	input SD_IS_WRITING;
	input [15:0]SCORES_TO_WRITE;
	output reg SD_TO_WRITE;
	output reg WRITE_FINISH;
	output [31:0]SD_WRITE_ADDRESS;
	output [15:0]DATA_TO_WRITE;

	assign SD_WRITE_ADDRESS=`SCORES_WRITE_ADDRESS;
	assign DATA_TO_WRITE=SCORES_TO_WRITE;

	parameter WAIT_TO_WRITE=2'b00;
	parameter REQUEST=2'b01;
	parameter WAIT_SD_WRITE_FINISH=2'b11;
	parameter FINISH=2'b10;

	reg [1:0]current_state=WAIT_TO_WRITE;
	reg [1:0]next_state;

	always @(posedge CLK)begin
		if(RESET)begin
			current_state<=WAIT_TO_WRITE;
		end
		else begin
			current_state<=next_state;
		end
	end

	always @(current_state or TO_WRITE or SD_HAS_INITIALIZED or SD_IS_WRITING)begin
		case(current_state)
			WAIT_TO_WRITE:begin
				if(TO_WRITE&SD_HAS_INITIALIZED&(~SD_IS_WRITING))begin
					next_state=REQUEST;
				end
				else begin
					next_state=WAIT_TO_WRITE;
				end
			end
			REQUEST:begin
				if(SD_IS_WRITING)begin
					next_state=WAIT_SD_WRITE_FINISH;
				end
				else begin
					next_state=REQUEST;
				end
			end
			WAIT_SD_WRITE_FINISH:begin
				if(~SD_IS_WRITING)begin
					next_state=FINISH;
				end
				else begin
					next_state=WAIT_SD_WRITE_FINISH;
				end
			end
			FINISH:begin
				next_state=FINISH;
			end
			default:begin
				next_state=WAIT_TO_WRITE;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_TO_WRITE:begin
				SD_TO_WRITE<=0;
				WRITE_FINISH<=0;
			end
			REQUEST:begin
				SD_TO_WRITE<=1;
				WRITE_FINISH<=0;
			end
			WAIT_SD_WRITE_FINISH:begin
				SD_TO_WRITE<=0;
				WRITE_FINISH<=0;
			end
			FINISH:begin
				SD_TO_WRITE<=0;
				WRITE_FINISH<=1;
			end
			default:begin
				SD_TO_WRITE<=0;
				WRITE_FINISH<=0;
			end
		endcase
	end
endmodule