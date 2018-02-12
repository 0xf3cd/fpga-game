`include "./Head.v"

module Each_Seven_Segment_Output(TO_OUTPUT,ENABLE);
	input [3:0]TO_OUTPUT;
	output reg[6:0]ENABLE;

	//控制7段数码管通断的编码
	parameter ZERO_ENCODE=7'b0000001;
	parameter ONE_ENCODE=7'b1001111;
	parameter TWO_ENCODE=7'b0010010;
	parameter THREE_ENCODE=7'b0000110;
	parameter FOUR_ENCODE=7'b1001100;
	parameter FIVE_ENCODE=7'b0100100;
	parameter SIX_ENCODE=7'b0100000;
	parameter SEVEN_ENCODE=7'b0001111;
	parameter EIGHT_ENCODE=7'b0000000;
	parameter NINE_ENCODE=7'b0000100;

	always @(TO_OUTPUT)begin
		case(TO_OUTPUT)
			'd0:begin
				ENABLE=ZERO_ENCODE;
			end
			'd1:begin
				ENABLE=ONE_ENCODE;
			end
			'd2:begin
				ENABLE=TWO_ENCODE;
			end
			'd3:begin
				ENABLE=THREE_ENCODE;
			end
			'd4:begin
				ENABLE=FOUR_ENCODE;
			end
			'd5:begin
				ENABLE=FIVE_ENCODE;
			end
			'd6:begin
				ENABLE=SIX_ENCODE;
			end
			'd7:begin
				ENABLE=SEVEN_ENCODE;
			end
			'd8:begin
				ENABLE=EIGHT_ENCODE;
			end
			'd9:begin
				ENABLE=NINE_ENCODE;
			end
			default:begin
				ENABLE=7'bxxxxxxx;
			end
		endcase
	end
endmodule