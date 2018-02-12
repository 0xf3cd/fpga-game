module Shift_Register_8bits(CLK,IN,RESET,ENABLE,OUT);
	input CLK;
	input IN;
	input RESET;//有效时所有位置1
	input ENABLE;
	output reg [7:0]OUT=0;

	always @(posedge CLK or posedge RESET)begin
		if(RESET)begin
			OUT<=8'b11111111;
		end
		else begin
			if(ENABLE)begin
				OUT<={OUT[6:0],IN};
			end
			else begin
				OUT<=OUT;
			end
		end
	end
endmodule

