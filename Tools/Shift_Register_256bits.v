module Shift_Register_256bits(CLK,ENABLE,RESET,RESET_VALUE,IN,OUT);
	input CLK;
	input ENABLE;
	input RESET;
	input [255:0]RESET_VALUE;
	input IN;
	output OUT;

	reg [255:0]saver=0;

	always @(posedge CLK)begin
		if(RESET)begin
			saver<=RESET_VALUE;
		end
		else begin
			if(ENABLE)begin
				saver<={saver[254:0],IN};
			end
			else begin
				saver<=saver;
			end
		end
	end

	assign OUT=saver[255];
endmodule