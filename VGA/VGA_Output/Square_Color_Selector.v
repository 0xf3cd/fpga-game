`include "./Head.v"

module Square_Color_Selector(COLOR,RANDOM_RGB,RGB);
	input [`SQUARE_STATE_ENCODE_LENGTH-1:0]COLOR;
	input [11:0]RANDOM_RGB;
	output reg [`RGB_LENGTH-1:0]RGB;

	always @(COLOR or RANDOM_RGB)begin
		case(COLOR)
			`SQUARE_STRONG:begin
				RGB=`BLACK_RGB;
			end
			`SQUARE_OKAY:begin
				RGB=`DARK_GREY_RGB;
			end
			`SQUARE_WEAK:begin
				RGB=`LIGHT_GREY_RGB;
			end
			`SQUARE_INVINCIBLE:begin
				RGB=RANDOM_RGB;
			end
			default:begin
				RGB=`BLACK_RGB;
			end
		endcase
	end
endmodule