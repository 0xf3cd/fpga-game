module Counter #(parameter WIDTH=6)(CLK,ENABLE,RESET,RESULT);//上升沿计数
	input CLK;
	input ENABLE;
	input RESET;
	output reg [WIDTH-1:0]RESULT;

	always @(posedge CLK)begin
		if(RESET)begin
			RESULT<=0;
		end
		else begin
			if(ENABLE)begin
				RESULT<=RESULT+1;
			end
			else begin
				RESULT<=RESULT;
			end
		end
	end
endmodule

