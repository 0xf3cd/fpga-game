`include "./Head.v"

module SD_Read_Response_Receiver(CLK,DO,ACTIVATE,RECEIVED);
	input CLK;
	input DO;
	input ACTIVATE;
	output reg RECEIVED=0;

	/*
	当ACTIVATE有效时，将进行R1响应接收动作
	接收完毕后RECEIVED为1
	*/

	reg is_counting=0;
	reg counter_enable_reset=0;

	reg counter_enable=0;
	reg counter_reset=0;
	wire [3:0]counter_result;
	Counter #(.WIDTH(4))counter(~CLK,counter_enable,counter_reset,counter_result);

	always @(DO or counter_enable_reset or is_counting)begin//锁存器
		if(counter_enable_reset)begin
			counter_enable=0;
		end
		else if((~DO)&is_counting)begin
			counter_enable=1;
		end
		else begin
			counter_enable=counter_enable;
		end
	end

	parameter WAIT_ACTIVATE=2'b00;
	parameter COUNTING=2'b01;
	parameter FINISH=2'b11;

	reg [1:0]current_state=WAIT_ACTIVATE;
	reg [1:0]next_state;

	always @(negedge CLK)begin
		current_state<=next_state;
	end

	always @(current_state or ACTIVATE or counter_result)begin
		case(current_state)
			WAIT_ACTIVATE:begin
				if(ACTIVATE)begin
					next_state=COUNTING;
				end
				else begin
					next_state=WAIT_ACTIVATE;
				end
			end
			COUNTING:begin
				if(counter_result==4'd7)begin
					next_state=FINISH;
				end
				else begin
					next_state=COUNTING;
				end
			end
			FINISH:begin
				next_state=WAIT_ACTIVATE;
			end
			default:begin
				next_state=WAIT_ACTIVATE;
			end
		endcase
	end

	always @(negedge CLK)begin
		case(next_state)
			WAIT_ACTIVATE:begin
				RECEIVED<=0;
			end
			COUNTING:begin
				RECEIVED<=0;
			end
			FINISH:begin
				RECEIVED<=1;
			end
			default:begin
				RECEIVED<=0;
			end
		endcase
	end

	always @(negedge CLK)begin
		case(next_state)
			WAIT_ACTIVATE:begin
				counter_enable_reset<=1;
				is_counting<=0;
				counter_reset<=1;
			end
			COUNTING:begin
				counter_enable_reset<=0;
				is_counting<=1;
				counter_reset<=0;
			end
			FINISH:begin
				counter_enable_reset<=1;
				is_counting<=0;
				counter_reset<=1;
			end
			default:begin
				counter_enable_reset<=1;
				is_counting<=0;
				counter_reset<=1;
			end
		endcase
	end
endmodule