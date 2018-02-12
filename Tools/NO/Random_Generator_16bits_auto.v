module Random_Generator_16bits_auto(CLK,RANDOM_RESULT);
	input CLK;
	output reg [15:0]RANDOM_RESULT;

	/*
	经验证，反馈系数为0111000111010110时随机循环达到最大，为65535
	*/
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
				RANDOM_RESULT<=16'b0101110100001001;
			end
			default:begin
				RANDOM_RESULT[0]<=RANDOM_RESULT[15];
				RANDOM_RESULT[1]<=RANDOM_RESULT[0]^RANDOM_RESULT[15];
				RANDOM_RESULT[2]<=RANDOM_RESULT[1]^RANDOM_RESULT[15];
				RANDOM_RESULT[3]<=RANDOM_RESULT[2]^RANDOM_RESULT[15];
				RANDOM_RESULT[4]<=RANDOM_RESULT[3];
				RANDOM_RESULT[5]<=RANDOM_RESULT[4];
				RANDOM_RESULT[6]<=RANDOM_RESULT[5];
				RANDOM_RESULT[7]<=RANDOM_RESULT[6]^RANDOM_RESULT[15];
				RANDOM_RESULT[8]<=RANDOM_RESULT[7]^RANDOM_RESULT[15];
				RANDOM_RESULT[9]<=RANDOM_RESULT[8]^RANDOM_RESULT[15];
				RANDOM_RESULT[10]<=RANDOM_RESULT[9];
				RANDOM_RESULT[11]<=RANDOM_RESULT[10]^RANDOM_RESULT[15];
				RANDOM_RESULT[12]<=RANDOM_RESULT[11];
				RANDOM_RESULT[13]<=RANDOM_RESULT[12]^RANDOM_RESULT[15];
				RANDOM_RESULT[14]<=RANDOM_RESULT[13]^RANDOM_RESULT[15];
				RANDOM_RESULT[15]<=RANDOM_RESULT[14];
			end
		endcase
	end
endmodule