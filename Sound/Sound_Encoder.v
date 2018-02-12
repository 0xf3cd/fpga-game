`include "./Head.v"
`include "./Sound/Sound_Counter.v"

module Sound_Encoder(CLK,WAVE,LEVEL);
	input CLK;//100Hz
	input WAVE;
	output reg [`SOUND_LEVEL_ENCODE_LENGTH-1:0]LEVEL;

	/*
	该模块作用是将声音传感器收集到的声音频率信号抽象为6个等级
	每0.02s采样一次，采样时间为为0.01s,统计期间声波上升沿的个数
	由上升沿个数的多寡决定最终分级
	*/

	reg counter_reset;
	wire [`SOUND_COUNTER_WIDTH-1:0]wave_counter;
	Sound_Counter sound_counter(WAVE,counter_reset,wave_counter);

	parameter RESET=1'b0;
	parameter UPDATE=1'b1;

	reg current_state=RESET;
	reg next_state;

	always @(posedge CLK)begin
		current_state<=next_state;
	end

	always @(current_state)begin
		case(current_state)
			RESET:begin
				next_state=UPDATE;
			end
			UPDATE:begin
				next_state=RESET;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			RESET:begin
				counter_reset<=1;
			end
			UPDATE:begin
				counter_reset<=0;
			end
		endcase
	end

	always @(negedge CLK)begin
		case(current_state)
            RESET:begin
                LEVEL<=LEVEL;
            end
            UPDATE:begin
                if(wave_counter<`LEVEL_BOUNDARY_0)begin
                    LEVEL<=`NO_SOUND;
                end
                else if(wave_counter>=`LEVEL_BOUNDARY_0 && wave_counter<`LEVEL_BOUNDARY_1)begin
                    LEVEL<=`LEVEL_1;
                end
                else if(wave_counter>=`LEVEL_BOUNDARY_1 && wave_counter<`LEVEL_BOUNDARY_2)begin
                    LEVEL<=`LEVEL_2;
                end
                else if(wave_counter>=`LEVEL_BOUNDARY_2 && wave_counter<`LEVEL_BOUNDARY_3)begin
                    LEVEL<=`LEVEL_3;
                end
                else if(wave_counter>=`LEVEL_BOUNDARY_3 && wave_counter<`LEVEL_BOUNDARY_4)begin
                    LEVEL<=`LEVEL_4;
                end
                else begin
                    LEVEL<=`LEVEL_5;
                end
            end
        endcase
	end
endmodule
