module BCD_Counter(CLK,RESET,RESULT,CARRY);
	input CLK;
	input RESET;
	output reg [3:0]RESULT;
	output reg CARRY=0;

	always @(posedge CLK or posedge RESET)begin
		if(RESET)begin
			RESULT<=4'b0000;
			CARRY<=0;
		end
		else begin
			if(RESULT==4'b1001)begin
				RESULT<=4'b0000;
				CARRY<=1;
			end
			else begin
				RESULT<=RESULT+1;
				CARRY<=0;
			end
		end
	end
endmodule