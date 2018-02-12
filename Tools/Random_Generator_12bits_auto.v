module Random_Generator_12bits_auto(CLK,RANDOM_RESULT);
	input CLK;
	output reg [11:0]RANDOM_RESULT;

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
				RANDOM_RESULT<=12'b011010001001;
			end
			default:begin
				RANDOM_RESULT[0]<=RANDOM_RESULT[11];
				RANDOM_RESULT[1]<=RANDOM_RESULT[0]^RANDOM_RESULT[11];
				RANDOM_RESULT[2]<=RANDOM_RESULT[1];
				RANDOM_RESULT[3]<=RANDOM_RESULT[2];
				RANDOM_RESULT[4]<=RANDOM_RESULT[3]^RANDOM_RESULT[11];
				RANDOM_RESULT[5]<=RANDOM_RESULT[4];
				RANDOM_RESULT[6]<=RANDOM_RESULT[5];
				RANDOM_RESULT[7]<=RANDOM_RESULT[6]^RANDOM_RESULT[11];
				RANDOM_RESULT[8]<=RANDOM_RESULT[7];
				RANDOM_RESULT[9]<=RANDOM_RESULT[8];
				RANDOM_RESULT[10]<=RANDOM_RESULT[9];
				RANDOM_RESULT[11]<=RANDOM_RESULT[10];
			end
		endcase
	end
endmodule