module Shift_Register_4096bits(CLK,IN,ENABLE,OUT);
	input CLK;
	input IN;
	input ENABLE;
	output reg[4095:0]OUT=0;

	always @(posedge CLK)begin
		if(ENABLE)begin
			OUT<={OUT[4094:0],IN};
			//OUT<={IN,OUT[4095:1]};
		end
		else begin
			OUT<=OUT;
		end
	end
endmodule