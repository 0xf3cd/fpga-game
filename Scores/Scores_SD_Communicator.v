`include "./Head.v"
`include "./Scores/Scores_Writer.v"
`include "./Scores/Scores_Reader.v"

module Scores_SD_Communicator(CLK,TO_GET_PREVIOUS_SCORES,TO_SAVE_SCORES,RESET,SD_HAS_INITIALIZED,SD_IS_READING,SD_IS_WRITING,SD_READ_DATA,SCORES_TO_WRITE,SD_TO_READ,
							  SD_READ_ADDRESS,PREVIOUS_SCORES,GET_PREVIOUS_SCORES_FINISH,SD_TO_WRITE,SD_WRITE_ADDRESS,SD_WRITE_DATA,SAVE_SCORES_FINISH);
	input CLK;
	input TO_GET_PREVIOUS_SCORES;
	input TO_SAVE_SCORES;
	input RESET;
	input SD_HAS_INITIALIZED;
	input SD_IS_READING;
	input SD_IS_WRITING;
	input [15:0]SD_READ_DATA;
	input [15:0]SCORES_TO_WRITE;
	output SD_TO_READ;
	output [31:0]SD_READ_ADDRESS;
	output [15:0]PREVIOUS_SCORES;
	output reg GET_PREVIOUS_SCORES_FINISH;
	output SD_TO_WRITE;
	output [31:0]SD_WRITE_ADDRESS;
	output [15:0]SD_WRITE_DATA;
	output reg SAVE_SCORES_FINISH;

	/*
	TO_GET_PREVIOUS_SCORES有效时，从SD卡中读取之前存储在卡中的分数数据
	GET_PREVIOUS_SCORES_FINISH有效时说明读取完毕
	TO_SAVE_SCORES有效时，将当前分数数据存入SD卡
	SAVE_SCORES_FINISH有效时说明写入成功
	RESET有效时进行复位
	*/

	reg read_start=0;
	wire read_finish;
	Scores_Reader reader(.CLK(CLK),
						 .TO_GET(read_start),
						 .RESET(RESET),
						 .SD_HAS_INITIALIZED(SD_HAS_INITIALIZED),
						 .SD_IS_READING(SD_IS_READING),
						 .READ_DATA(SD_READ_DATA[15:0]),
						 .SD_TO_READ(SD_TO_READ),
						 .READ_FINISH(read_finish),
						 .SD_READ_ADDRESS(SD_READ_ADDRESS[31:0]),
						 .PREVIOUS_SCORES(PREVIOUS_SCORES[15:0]));

	reg write_start=0;
	wire write_finish;
	Scores_Writer writer(.CLK(CLK),
						 .TO_WRITE(write_start),
						 .RESET(RESET),
						 .SD_HAS_INITIALIZED(SD_HAS_INITIALIZED),
						 .SD_IS_WRITING(SD_IS_WRITING),
						 .SCORES_TO_WRITE(SCORES_TO_WRITE[15:0]),
						 .SD_TO_WRITE(SD_TO_WRITE),
						 .WRITE_FINISH(write_finish),
						 .SD_WRITE_ADDRESS(SD_WRITE_ADDRESS[31:0]),
						 .DATA_TO_WRITE(SD_WRITE_DATA[15:0]));


	parameter WAIT_TO_START=3'b000;
	parameter READ_EXECUTE=3'b001;
	parameter READ_FINISH=3'b011;
	parameter WAIT_TO_WRITE=3'b010;
	parameter WRITE_EXECUTE=3'b110;
	parameter WRITE_FINISH=3'b111;

	reg [2:0]current_state=WAIT_TO_START;
	reg [2:0]next_state;

	always @(posedge CLK)begin
		if(RESET)begin
			current_state<=WAIT_TO_START;
		end
		else begin
			current_state<=next_state;
		end
	end 

	always @(current_state or TO_GET_PREVIOUS_SCORES or read_finish or TO_SAVE_SCORES or write_finish)begin
		case(current_state)
			WAIT_TO_START:begin
				if(TO_GET_PREVIOUS_SCORES)begin
					next_state=READ_EXECUTE;
				end
				else begin
					next_state=WAIT_TO_START;
				end
			end
			READ_EXECUTE:begin
				if(read_finish)begin
					next_state=READ_FINISH;
				end
				else begin
					next_state=READ_EXECUTE;
				end
			end
			READ_FINISH:begin
				next_state=WAIT_TO_WRITE;
			end
			WAIT_TO_WRITE:begin
				if(TO_SAVE_SCORES)begin
					next_state=WRITE_EXECUTE;
				end
				else begin
					next_state=WAIT_TO_WRITE;
				end
			end
			WRITE_EXECUTE:begin
				if(write_finish)begin
					next_state=WRITE_FINISH;
				end
				else begin
					next_state=WRITE_EXECUTE;
				end
			end
			WRITE_FINISH:begin
				next_state=WRITE_FINISH;
			end
			default:begin
				next_state=WAIT_TO_START;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				GET_PREVIOUS_SCORES_FINISH<=0;
				read_start<=0;
			end
			READ_EXECUTE:begin
				GET_PREVIOUS_SCORES_FINISH<=0;
				read_start<=1;
			end
			READ_FINISH:begin
				GET_PREVIOUS_SCORES_FINISH<=1;
				read_start<=0;
			end
			WAIT_TO_WRITE:begin
				GET_PREVIOUS_SCORES_FINISH<=1;
				read_start<=0;
			end
			WRITE_EXECUTE:begin
				GET_PREVIOUS_SCORES_FINISH<=1;
				read_start<=0;
			end
			WRITE_FINISH:begin
				GET_PREVIOUS_SCORES_FINISH<=1;
				read_start<=0;
			end
			default:begin
				GET_PREVIOUS_SCORES_FINISH<=0;
				read_start<=0;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				SAVE_SCORES_FINISH<=0;
				write_start<=0;
			end
			READ_EXECUTE:begin
				SAVE_SCORES_FINISH<=0;
				write_start<=0;
			end
			READ_FINISH:begin
				SAVE_SCORES_FINISH<=0;
				write_start<=0;
			end
			WAIT_TO_WRITE:begin
				SAVE_SCORES_FINISH<=0;
				write_start<=0;
			end
			WRITE_EXECUTE:begin
				SAVE_SCORES_FINISH<=0;
				write_start<=1;
			end
			WRITE_FINISH:begin
				SAVE_SCORES_FINISH<=1;
				write_start<=0;
			end
			default:begin
				SAVE_SCORES_FINISH<=0;
				write_start<=0;
			end
		endcase
	end
endmodule