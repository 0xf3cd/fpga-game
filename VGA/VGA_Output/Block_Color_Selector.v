`include "./Head.v"

module Block_Color_Selector(COLOR,RGB);
	input [`COLOR_ENCODE_LENGTH-1:0]COLOR;
	output reg [`RGB_LENGTH-1:0]RGB;
	
	always @(COLOR)begin
		case(COLOR)
			`PINK:begin
				RGB=`PINK_RGB;
			end
			`YELLOW:begin
				RGB=`YELLOW_RGB;
			end
			`ORANGE:begin
				RGB=`ORANGE_RGB;
			end
			`CYAN:begin
				RGB=`CYAN_RGB;
			end
			`RED:begin
				RGB=`RED_RGB;
			end
			`BLUE:begin
				RGB=`BLUE_RGB;
			end
			`VIOLET:begin
				RGB=`VIOLET_RGB;
			end
			`ROSE:begin
				RGB=`ROSE_RGB;
			end
			default:begin
				RGB=`ROSE_RGB;
			end
		endcase
	end
endmodule