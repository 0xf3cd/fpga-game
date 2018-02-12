module Shift_Register_N_bits #(parameter WIDTH=16)(CLK,ENABLE,RESET,RESET_VALUE,IN,OUT);
	input CLK;
	input ENABLE;
	input RESET;
	input [WIDTH-1:0]RESET_VALUE;
	input IN;
	output OUT;

	reg [WIDTH-1:0]saver=0;

	always @(posedge CLK)begin
		if(RESET)begin
			saver<=RESET_VALUE;
		end
		else begin
			if(ENABLE)begin
				saver<={saver[WIDTH-2:0],IN};
			end
			else begin
				saver<=saver;
			end
		end
	end

	assign OUT=saver[WIDTH-1];
endmodule