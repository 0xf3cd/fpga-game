`include "./Head.v"

module Sound_Counter(WAVE,RESET,RESULT);
	input WAVE;
	input RESET;
	output reg [`SOUND_COUNTER_WIDTH-1:0]RESULT;

	always @(posedge WAVE or posedge RESET)begin
		if(RESET)begin
			RESULT<=0;
		end
		else begin
			RESULT<=RESULT+1;
		end
	end
endmodule