`include "./Head.v"
`include "./Scores/Scores_SD_Communicator.v"
`include "./Scores/Scores_Counter.v"
`include "./7_Segment_Output/Seven_Segment_Output.v"

module Scores(CLK,START,RESET,OVER,SD_HAS_INITIALIZED,SD_IS_READING,SD_IS_WRITING,SD_READ_DATA,
				SEGMENT_ACTIVE,AG_ENABLE,SD_TO_READ,SD_READ_ADDRESS,SD_TO_WRITE,SD_WRITE_DATA,
				SD_WRITE_ADDRESS,READ_FINISH,WRITE_FINISH);
	input CLK;//100MHz
	input START;
	input RESET;
	input OVER;
	input SD_HAS_INITIALIZED;
	input SD_IS_READING;
	input SD_IS_WRITING;
	input [15:0]SD_READ_DATA;
	output [7:0]SEGMENT_ACTIVE;//8个7段数码管是否被激活的控制信号
	output [6:0]AG_ENABLE;//A-G的通断控制
	output SD_TO_READ;
	output [31:0]SD_READ_ADDRESS;
	output SD_TO_WRITE;
	output [15:0]SD_WRITE_DATA;
	output [31:0]SD_WRITE_ADDRESS;
	output READ_FINISH;
	output WRITE_FINISH;

	
	reg to_get_previous_scores=0;
	reg to_save_scores=0;
	wire get_previous_scores_finish;
	wire save_scores_finish;
	wire [15:0]previous_scores;
	wire [15:0]scores_to_write;
	Scores_SD_Communicator sd_communicator(.CLK(CLK),
										   .TO_GET_PREVIOUS_SCORES(to_get_previous_scores),
										   .TO_SAVE_SCORES(to_save_scores),
										   .RESET(RESET),
										   .SD_HAS_INITIALIZED(SD_HAS_INITIALIZED),
										   .SD_IS_READING(SD_IS_READING),
										   .SD_IS_WRITING(SD_IS_WRITING),
										   .SD_READ_DATA(SD_READ_DATA),
										   .SCORES_TO_WRITE(scores_to_write),
										   .SD_TO_READ(SD_TO_READ),
										   .SD_READ_ADDRESS(SD_READ_ADDRESS),
										   .PREVIOUS_SCORES(previous_scores),
										   .GET_PREVIOUS_SCORES_FINISH(get_previous_scores_finish),
										   .SD_TO_WRITE(SD_TO_WRITE),
										   .SD_WRITE_ADDRESS(SD_WRITE_ADDRESS),
										   .SD_WRITE_DATA(SD_WRITE_DATA),
										   .SAVE_SCORES_FINISH(save_scores_finish));

	
	wire [15:0]current_scores;
	reg counter_start=0;
	reg counter_stop=0;
	Scores_Counter counter(.CLK(CLK),
						   .START(counter_start),
						   .RESET(RESET),
						   .STOP(counter_stop),
						   .COUNTER_RESULT(current_scores));

	Seven_Segment_Output scores_output(.CLK(CLK),
									   .TO_OUTPUT({previous_scores,current_scores}),
									   .ACTIVE(SEGMENT_ACTIVE),
									   .ENABLE(AG_ENABLE));

	wire current_higher_than_previous;
	assign current_higher_than_previous=(current_scores>previous_scores);//综合出一个比较器电路，判断当前得分是否高于历史最高分
	assign scores_to_write=(current_higher_than_previous)?current_scores:previous_scores;

	assign WRITE_FINISH=save_scores_finish;
	assign READ_FINISH=get_previous_scores_finish;

	parameter WAIT_TO_START=3'b000;
	parameter READ_PREVIOUS_SCORES=3'b001;
	parameter WORKING=3'b011;
	parameter WRITE_CURRENT_SCORES=3'b010;
	parameter GAME_OVER=3'b110;

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

	always @(*)begin
		case(current_state)
			WAIT_TO_START:begin
				if(START)begin
					next_state=READ_PREVIOUS_SCORES;
				end
				else begin
					next_state=WAIT_TO_START;
				end
			end
			READ_PREVIOUS_SCORES:begin
				if(get_previous_scores_finish)begin
					next_state=WORKING;
				end
				else begin
					next_state=READ_PREVIOUS_SCORES;
				end
			end
			WORKING:begin
				if(OVER)begin
					next_state=WRITE_CURRENT_SCORES;
				end
				else begin
					next_state=WORKING;
				end
			end
			WRITE_CURRENT_SCORES:begin
				if(save_scores_finish)begin
					next_state=GAME_OVER;
				end
				else begin
					next_state=WRITE_CURRENT_SCORES;
				end
			end
			GAME_OVER:begin
				next_state=GAME_OVER;
			end
			default:begin
				next_state=WAIT_TO_START;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				to_get_previous_scores<=0;
				to_save_scores<=0;
			end
			READ_PREVIOUS_SCORES:begin
				to_get_previous_scores<=1;
				to_save_scores<=0;
			end
			WORKING:begin
				to_get_previous_scores<=0;
				to_save_scores<=0;
			end
			WRITE_CURRENT_SCORES:begin
				to_get_previous_scores<=0;
				to_save_scores<=1;
			end
			GAME_OVER:begin
				to_get_previous_scores<=0;
				to_save_scores<=0;
			end
			default:begin
				to_get_previous_scores<=0;
				to_save_scores<=0;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				counter_start<=0;
				counter_stop<=0;
			end
			READ_PREVIOUS_SCORES:begin
				counter_start<=0;
				counter_stop<=0;
			end
			WORKING:begin
				counter_start<=1;
				counter_stop<=0;
			end
			WRITE_CURRENT_SCORES:begin
				counter_start<=0;
				counter_stop<=1;
			end
			GAME_OVER:begin
				counter_start<=0;
				counter_stop<=1;
			end
			default:begin
				counter_start<=0;
				counter_stop<=0;
			end
		endcase
	end
endmodule