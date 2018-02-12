module Divider #(parameter WIDTH=4,N = 20)(I_CLK, O_CLK);
	input I_CLK;
	output reg O_CLK=0;
    
	reg [WIDTH-1:0] counter=0;
    
	always@(posedge I_CLK) begin
		if(counter==N/2-1) begin
			counter<='b0;
			O_CLK<=~O_CLK;
		end
		else begin
			counter<=counter+'b1;
		end
	end
endmodule