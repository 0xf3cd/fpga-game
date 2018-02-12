`include "./Head.v"
`include "./Tools/Decimal_Counter.v"

module Scores_Counter(CLK,START,RESET,STOP,COUNTER_RESULT);
	input CLK;//100MHz
	input START;
	input RESET;
	input STOP;
	output [15:0]COUNTER_RESULT;

	wire clk_1Hz;
	wire clk_0;
	Divider #(30,100000000)get_1Hz(CLK,clk_1Hz);
	assign clk_0=0;

	//reg [15:0]counter_result=0;
	reg counter_reset=0;
	wire counter_clk;
	reg is_counting=1;
	assign counter_clk=is_counting?clk_1Hz:clk_0;
	Decimal_Counter counter(counter_clk,counter_reset,COUNTER_RESULT);
	//assign COUNTER_RESULT=counter_result;

	parameter WAIT_TO_START=2'b00;
	parameter COUNTING=2'b01;
	parameter PAUSE=2'b11;

	reg [1:0]current_state=WAIT_TO_START;
	reg [1:0]next_state;

	always @(posedge CLK)begin
		if(RESET)begin
			current_state<=WAIT_TO_START;
		end
		else begin
			current_state<=next_state;
		end
	end

	always @(current_state or START or STOP)begin
		case(current_state)
			WAIT_TO_START:begin
				if(START)begin
					next_state=COUNTING;
				end
				else begin
					next_state=WAIT_TO_START;
				end
			end
			COUNTING:begin
				if(STOP)begin
					next_state=PAUSE;
				end
				else begin
					next_state=COUNTING;
				end
			end
			PAUSE:begin
				next_state=PAUSE;
			end
			default:begin
				next_state=WAIT_TO_START;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				counter_reset<=1;
			end
			COUNTING:begin
				counter_reset<=0;
			end
			PAUSE:begin
				counter_reset<=0;
			end
			default:begin
				counter_reset<=1;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				is_counting<=0;
			end
			COUNTING:begin
				is_counting<=1;
			end
			PAUSE:begin
				is_counting<=0;
			end
			default:begin
				is_counting<=0;
			end
		endcase
	end
endmodule