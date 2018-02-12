`include "./Tools/BCD_Counter.v"

module Decimal_Counter(CLK,RESET,RESULT);
	input CLK;
	input RESET;
	output [15:0]RESULT;

	wire carry_1;
	wire carry_2;
	wire carry_3;
	
	BCD_Counter counter_1(CLK,RESET,RESULT[3:0],carry_1);
	BCD_Counter counter_2(carry_1,RESET,RESULT[7:4],carry_2);
	BCD_Counter counter_3(carry_2,RESET,RESULT[11:8],carry_3);
	BCD_Counter counter_4(carry_3,RESET,RESULT[15:12],);
endmodule