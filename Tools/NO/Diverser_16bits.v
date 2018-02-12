module Diverser_16bits(IN,OUT);
	input [0:15]IN;
	output [15:0]OUT;

	assign OUT[0]=IN[0];
	assign OUT[1]=IN[1];
	assign OUT[2]=IN[2];
	assign OUT[3]=IN[3];
	assign OUT[4]=IN[4];
	assign OUT[5]=IN[5];
	assign OUT[6]=IN[6];
	assign OUT[7]=IN[7];
	assign OUT[8]=IN[8];
	assign OUT[9]=IN[9];
	assign OUT[10]=IN[10];
	assign OUT[11]=IN[11];
	assign OUT[12]=IN[12];
	assign OUT[13]=IN[13];
	assign OUT[14]=IN[14];
	assign OUT[15]=IN[15];
endmodule