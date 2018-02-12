`include "./Head.v"
`include "./SD/SD.v"
`include "./MP3/MP3.v"
`include "./Scores/Scores.v"

module Periphery(CLK,SD_DO,MP3_SO,MP3_DREQ,START,HURT,OVER,RESTART,SD_CS,SD_CLK,SD_DI,MP3_CLK,MP3_RESET_n,
		MP3_DCS,MP3_CS,MP3_SI,SEGMENT_ACTIVE,AG_ENABLE);
	input CLK;//100MHz
	input SD_DO;
	input MP3_SO;
	input MP3_DREQ;
	input START;
	input HURT;
	input OVER;
	input RESTART;
	output SD_CS;
	output SD_CLK;
	output SD_DI;
	output MP3_CLK;
	output MP3_RESET_n;
	output MP3_DCS;
	output MP3_CS;
	output MP3_SI;
	output [7:0]SEGMENT_ACTIVE;//8个7段数码管是否被激活的控制信号
	output [6:0]AG_ENABLE;//A-G的通断控制

	wire sd_to_write;
	wire sd_to_read;
	wire sd_is_reading;
	wire sd_is_writing;
	wire [31:0]sd_read_address;
	wire [31:0]sd_write_address;
	wire sd_has_initialized;
	wire [4095:0]data;
	wire [15:0]data_to_write;
	//reg sd_to_initialize=0;
	
	SD #(.DATA_TO_WRITE_LENGTH(16))SD_
		(.CLK(CLK),
		 .DO(SD_DO),
		 .START_TO_INITIALIZE(1),//一上电就开始初始化
		 .TO_READ(sd_to_read),
		 .TO_WRITE(sd_to_write),
		 .READ_ADDRESS(sd_read_address),
		 .WRITE_ADDRESS(sd_write_address),
		 .DATA_TO_WRITE(data_to_write),
		 .DI(SD_DI),
		 .SD_CLK(SD_CLK),
		 .CS(SD_CS),
		 .HAS_INITIALIZED(sd_has_initialized),
		 .IS_READING(sd_is_reading),
		 .IS_WRITING(sd_is_writing),
		 .DATA_READ(data));


    wire sd_to_read_mp3;  
    wire [31:0]sd_read_address_mp3;
	reg mp3_start=0;
	reg mp3_reset=0;
	MP3 MP3_(.CLK(CLK),
			 .MP3_SO(MP3_SO),
			 .MP3_DREQ(MP3_DREQ),
			 .SD_HAS_INITIALIZED(sd_has_initialized),
			 .SD_IS_READING(sd_is_reading),
			 .START(mp3_start),
			 .RESET(mp3_reset),
			 .SD_READ_DATA(data),
			 .MP3_SCLK(MP3_CLK),
			 .MP3_RESET_n(MP3_RESET_n),
			 .MP3_DCS(MP3_DCS),
			 .MP3_CS(MP3_CS),
			 .MP3_SI(MP3_SI),
			 .SD_TO_READ(sd_to_read_mp3),
			 .SD_READ_ADDRESS(sd_read_address_mp3));


	wire sd_to_read_score;
	wire [31:0]sd_read_address_score;
	wire read_scores_finish;
	wire save_scores_finish;
	reg score_start=0;
	reg score_reset=0;
	reg score_over=0;
	Scores scores_counter(.CLK(CLK),
						  .START(score_start),
						  .RESET(score_reset),
						  .OVER(score_over),
						  .SD_HAS_INITIALIZED(sd_has_initialized),
						  .SD_IS_READING(sd_is_reading),
						  .SD_IS_WRITING(sd_is_writing),
						  .SD_READ_DATA(data[4095:4080]),
						  .SEGMENT_ACTIVE(SEGMENT_ACTIVE),
						  .AG_ENABLE(AG_ENABLE),
						  .SD_TO_READ(sd_to_read_score),
						  .SD_READ_ADDRESS(sd_read_address_score),
						  .SD_TO_WRITE(sd_to_write),
						  .SD_WRITE_DATA(data_to_write),
						  .SD_WRITE_ADDRESS(sd_write_address),
						  .READ_FINISH(read_scores_finish),
						  .WRITE_FINISH(save_scores_finish));

	parameter SCORE_USING=1'b0;
	parameter MP3_USING=1'b1;
	reg who_is_using_sd=SCORE_USING;
			 
	assign sd_to_read=(who_is_using_sd==SCORE_USING)?sd_to_read_score:sd_to_read_mp3;
	assign sd_read_address=(who_is_using_sd==SCORE_USING)?sd_read_address_score:sd_read_address_mp3;


	wire play_finish;
	reg counter_enable=0;
	reg counter_reset=0;
	wire [26:0]counter_result;
	Counter #(.WIDTH(27)) time_counter(CLK,counter_enable,counter_reset,counter_result);
	assign play_finish=counter_result[26];//(counter_result>26'd30000000);

    parameter IDLE=8'b00000001;
    parameter READ_PREVIOUS_SCORE=8'b00000010;
    parameter SD_USER_CHANGE_TO_MP3=8'b00000100;
    parameter WAIT_TO_PLAY_MUSIC=8'b00001000;
    parameter PLAY_MUSIC=8'b00010000;
    parameter SD_USER_CHANGE_TO_SCORE=8'b00100000;
    parameter SAVE_CURRENT_SCORE=8'b01000000;
    parameter GAME_OVER=8'b10000000;

    reg [7:0]current_state=IDLE;
    reg [7:0]next_state;

    always @(negedge CLK)begin
    	current_state<=next_state;
    end

    always @(current_state or START or HURT or play_finish or read_scores_finish or OVER or save_scores_finish)begin
    	case(current_state)
    		IDLE:begin
    			if(START)begin
    				next_state=READ_PREVIOUS_SCORE;
    			end
    			else begin
    				next_state=IDLE;
    			end
    		end
    		READ_PREVIOUS_SCORE:begin
    			if(read_scores_finish)begin
    				next_state=SD_USER_CHANGE_TO_MP3;
    			end
    			else begin
    				next_state=READ_PREVIOUS_SCORE;
    			end
    		end
    		SD_USER_CHANGE_TO_MP3:begin
    			next_state=WAIT_TO_PLAY_MUSIC;
    		end
    		WAIT_TO_PLAY_MUSIC:begin
    			if(OVER)begin
    				next_state=SD_USER_CHANGE_TO_SCORE;
    			end
    			else begin
    				if(HURT)begin
    					next_state=PLAY_MUSIC;
    				end
    				else begin
    					next_state=WAIT_TO_PLAY_MUSIC;
    				end
    			end
    		end
    		PLAY_MUSIC:begin
    			if(play_finish)begin
    				next_state=WAIT_TO_PLAY_MUSIC;
    			end
    			else begin
    				next_state=PLAY_MUSIC;
    			end
    		end
    		SD_USER_CHANGE_TO_SCORE:begin
    			next_state=SAVE_CURRENT_SCORE;
    		end
    		SAVE_CURRENT_SCORE:begin
    			if(save_scores_finish)begin
    				next_state=GAME_OVER;
    			end
    			else begin
    				next_state=SAVE_CURRENT_SCORE;
    			end
    		end
    		GAME_OVER:begin
    			if(RESTART)begin
    				next_state=IDLE;
    			end
    			else begin
    				next_state=GAME_OVER;
    			end		
    		end
    		default:begin
    			next_state=IDLE;
    		end
    	endcase
    end

     always @(negedge CLK)begin
    	case(next_state)
    		IDLE:begin
    			counter_reset<=1;
    			counter_enable<=0;
    		end
    		READ_PREVIOUS_SCORE:begin
    			counter_reset<=1;
    			counter_enable<=0;
    		end
    		SD_USER_CHANGE_TO_MP3:begin
    			counter_reset<=1;
    			counter_enable<=0;
    		end
    		WAIT_TO_PLAY_MUSIC:begin
    			counter_reset<=1;
    			counter_enable<=0;
    		end
    		PLAY_MUSIC:begin
    			counter_reset<=0;
    			counter_enable<=1;
    		end
    		SD_USER_CHANGE_TO_SCORE:begin
    			counter_reset<=1;
    			counter_enable<=0;
    		end
    		SAVE_CURRENT_SCORE:begin
    			counter_reset<=1;
    			counter_enable<=0;
    		end
    		GAME_OVER:begin
    			counter_reset<=1;
    			counter_enable<=0;
    		end
    		default:begin
    			counter_reset<=1;
    			counter_enable<=0;
    		end
    	endcase
    end

    always @(negedge CLK)begin
    	case(next_state)
    		IDLE:begin
    			mp3_start<=0;
    			mp3_reset<=1;
    		end
    		READ_PREVIOUS_SCORE:begin
    			mp3_start<=0;
    			mp3_reset<=1;
    		end
    		SD_USER_CHANGE_TO_MP3:begin
    			mp3_start<=0;
    			mp3_reset<=1;
    		end
    		WAIT_TO_PLAY_MUSIC:begin
    			mp3_start<=0;
    			mp3_reset<=1;
    		end
    		PLAY_MUSIC:begin
    			mp3_start<=1;
    			mp3_reset<=0;
    		end
    		SD_USER_CHANGE_TO_SCORE:begin
    			mp3_start<=0;
    			mp3_reset<=1;
    		end
    		SAVE_CURRENT_SCORE:begin
    			mp3_start<=0;
    			mp3_reset<=1;
    		end
    		GAME_OVER:begin
    			mp3_start<=0;
    			mp3_reset<=1;
    		end
    		default:begin
    			mp3_start<=0;
    			mp3_reset<=1;
    		end
    	endcase
    end

    
    always @(negedge CLK)begin
    	case(next_state)
    		IDLE:begin
    			score_over<=0;
   				score_reset<=1;
    			score_start<=0;
    		end
    		READ_PREVIOUS_SCORE:begin
    			score_over<=0;
   				score_reset<=0;
    			score_start<=1;
    		end
    		SD_USER_CHANGE_TO_MP3:begin
    			score_over<=0;
   				score_reset<=0;
    			score_start<=1;
    		end
    		WAIT_TO_PLAY_MUSIC:begin
    			score_over<=0;
   				score_reset<=0;
    			score_start<=1;
    		end
    		PLAY_MUSIC:begin
    			score_over<=0;
   				score_reset<=0;
    			score_start<=1;
    		end
    		SD_USER_CHANGE_TO_SCORE:begin
    			score_over<=1;
   				score_reset<=0;
    			score_start<=0;
    		end
    		SAVE_CURRENT_SCORE:begin
    			score_over<=1;
   				score_reset<=0;
    			score_start<=0;
    		end
    		GAME_OVER:begin
    			score_over<=1;
   				score_reset<=0;
    			score_start<=0;
    		end
    		default:begin
    			score_over<=0;
   				score_reset<=1;
    			score_start<=0;
    		end
    	endcase
    end

    always @(negedge CLK)begin
    	case(next_state)
    		IDLE:begin
    			who_is_using_sd<=SCORE_USING;
    		end
    		READ_PREVIOUS_SCORE:begin
    			who_is_using_sd<=SCORE_USING;
    		end
    		SD_USER_CHANGE_TO_MP3:begin
    			who_is_using_sd<=MP3_USING;
    		end
    		WAIT_TO_PLAY_MUSIC:begin
    			who_is_using_sd<=MP3_USING;
    		end
    		PLAY_MUSIC:begin
    			who_is_using_sd<=MP3_USING;
    		end
    		SD_USER_CHANGE_TO_SCORE:begin
    			who_is_using_sd<=SCORE_USING;
    		end
    		SAVE_CURRENT_SCORE:begin
    			who_is_using_sd<=SCORE_USING;
    		end
    		GAME_OVER:begin
    			who_is_using_sd<=SCORE_USING;
    		end
    		default:begin
    			who_is_using_sd<=SCORE_USING;
    		end
    	endcase
    end
endmodule