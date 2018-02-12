module Random_Generator_N_bits_auto #(parameter N=16)(CLK,RANDOM_RESULT);
	input CLK;
	output reg[N-1:0]RANDOM_RESULT;

	parameter INITIALIZE=1'b0;
	parameter AUTO_GENERATE=1'b1;

	reg current_state=INITIALIZE;
	reg next_state;

	always @(posedge CLK)begin
		current_state<=next_state;
	end

	always @(current_state)begin
		if(current_state==INITIALIZE)begin
			next_state=AUTO_GENERATE;
		end
		else begin
			next_state=AUTO_GENERATE;
		end
	end

	always @(posedge CLK)begin
		case(current_state)
			INITIALIZE:begin
				RANDOM_RESULT[0]<=1'b1;
				RANDOM_RESULT[N-2:1]<=0;
				RANDOM_RESULT[N-1]<=1'b1;
			end
			default:begin
				RANDOM_RESULT[0]<=RANDOM_RESULT[N-1];
				RANDOM_RESULT[1]<=RANDOM_RESULT[0]^RANDOM_RESULT[N-1];
				RANDOM_RESULT[N-3:2]<=RANDOM_RESULT[N-4:1];
				RANDOM_RESULT[N-2]<=RANDOM_RESULT[N-3]^RANDOM_RESULT[N-1];
				RANDOM_RESULT[N-1]<=RANDOM_RESULT[N-2];
			end
		endcase
	end
endmodule
