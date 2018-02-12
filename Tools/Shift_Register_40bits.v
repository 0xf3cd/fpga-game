module Shift_Register_40bits(CLK,IN,ENABLE,OUT);//带有保持功能的移位寄存器
	input CLK;
	input IN;
	input ENABLE;
	output reg[39:0]OUT=0;

	always @(posedge CLK)begin
		if(ENABLE)begin
			OUT<={OUT[38:0],IN};
		end
		else begin
			OUT<=OUT;
		end
	end
endmodule