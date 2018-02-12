module Shift_Register_48bits(CLK,IN,RESET,RESET_VALUE,OUT);
	input CLK;
	input IN;
	input RESET;
	input [47:0]RESET_VALUE;
	output OUT;

	reg [47:0]data_saver=0;

	always @(posedge CLK)begin
		if(RESET)begin
			data_saver<=RESET_VALUE;
		end
		else begin
			data_saver<={data_saver[46:0],IN};
		end
	end

	assign OUT=data_saver[47];
endmodule