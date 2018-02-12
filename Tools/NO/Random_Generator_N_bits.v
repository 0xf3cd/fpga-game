module Random_Generator_N_bits #(parameter N=16)(CLK,RESET,SEED,RANDOM_RESULT);
	input CLK;
	input RESET;
	input [N-1:0]SEED;
	output reg[N-1:0]RANDOM_RESULT=0;

	always @(posedge CLK)begin
		if(RESET)begin
			RANDOM_RESULT<=SEED;
		end
		else begin
			RANDOM_RESULT[0]<=RANDOM_RESULT[N-1];
			RANDOM_RESULT[1]<=RANDOM_RESULT[0]^RANDOM_RESULT[N-1];
			RANDOM_RESULT[N-3:2]<=RANDOM_RESULT[N-4:1];
			RANDOM_RESULT[N-2]<=RANDOM_RESULT[N-3]^RANDOM_RESULT[N-1];
			RANDOM_RESULT[N-1]<=RANDOM_RESULT[N-2];
		end
	end
endmodule