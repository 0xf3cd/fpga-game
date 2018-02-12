`include "./Head.v"
`include "./7_Segment_Output/Each_Seven_Segment_Output.v"

module Seven_Segment_Output(CLK,TO_OUTPUT,ACTIVE,ENABLE);
	input CLK;//100MHz 
	input [31:0]TO_OUTPUT;
	output reg[7:0]ACTIVE;//8个7段数码管是否被激活的控制信号
	output [6:0]ENABLE;//A-G的通断控制

	/*
	该模块功能是将传入的8个4位8421BCD编码对应的十进制数字显示至七段数码管上
	*/

	wire [3:0]thousands_1=TO_OUTPUT[31:28];
	wire [3:0]hundreds_1=TO_OUTPUT[27:24];
	wire [3:0]tens_1=TO_OUTPUT[23:20];
	wire [3:0]ones_1=TO_OUTPUT[19:16];
	wire [3:0]thousands_2=TO_OUTPUT[15:12];
	wire [3:0]hundreds_2=TO_OUTPUT[11:8];
	wire [3:0]tens_2=TO_OUTPUT[7:4];
	wire [3:0]ones_2=TO_OUTPUT[3:0];
	reg [3:0]output_place;

	Each_Seven_Segment_Output output_one_place(output_place[3:0],ENABLE[6:0]);

	wire seg_clk;
	Divider #(18,100000)seg_clk_divider(CLK,seg_clk);

	//状态机部分
	parameter OUTPUT_THOUSANDS_1=3'b000;
	parameter OUTPUT_HUNDREDS_1=3'b001;
	parameter OUTPUT_TENS_1=3'b011;
	parameter OUTPUT_ONES_1=3'b010;
	parameter OUTPUT_THOUSANDS_2=3'b110;
	parameter OUTPUT_HUNDREDS_2=3'b111;
	parameter OUTPUT_TENS_2=3'b101;
	parameter OUTPUT_ONES_2=3'b100;

	reg [2:0]current_state=OUTPUT_THOUSANDS_1;
	reg [2:0]next_state;

	always @(posedge seg_clk)begin
		current_state<=next_state;
	end

	always @(current_state)begin
		case(current_state)
			OUTPUT_THOUSANDS_1:begin
				next_state=OUTPUT_HUNDREDS_1;
			end
			OUTPUT_HUNDREDS_1:begin
				next_state=OUTPUT_TENS_1;
			end
			OUTPUT_TENS_1:begin
				next_state=OUTPUT_ONES_1;
			end
			OUTPUT_ONES_1:begin
				next_state=OUTPUT_THOUSANDS_2;
			end
			OUTPUT_THOUSANDS_2:begin
				next_state=OUTPUT_HUNDREDS_2;
			end
			OUTPUT_HUNDREDS_2:begin
				next_state=OUTPUT_TENS_2;
			end
			OUTPUT_TENS_2:begin
				next_state=OUTPUT_ONES_2;
			end
			OUTPUT_ONES_2:begin
				next_state=OUTPUT_THOUSANDS_1;
			end
		endcase
	end

	always @(posedge seg_clk)begin
		case(next_state)
			OUTPUT_THOUSANDS_1:begin
				ACTIVE<=8'b01111111;
				output_place<=thousands_1;
			end
			OUTPUT_HUNDREDS_1:begin
				ACTIVE<=8'b10111111;
				output_place<=hundreds_1;
			end
			OUTPUT_TENS_1:begin
				ACTIVE<=8'b11011111;
				output_place<=tens_1;
			end
			OUTPUT_ONES_1:begin
				ACTIVE<=8'b11101111;
				output_place<=ones_1;
			end
			OUTPUT_THOUSANDS_2:begin
				ACTIVE<=8'b11110111;
				output_place<=thousands_2;
			end
			OUTPUT_HUNDREDS_2:begin
				ACTIVE<=8'b11111011;
				output_place<=hundreds_2;
			end
			OUTPUT_TENS_2:begin
				ACTIVE<=8'b11111101;
				output_place<=tens_2;
			end
			OUTPUT_ONES_2:begin	
				ACTIVE<=8'b11111110;
				output_place<=ones_2;
			end
		endcase
	end
endmodule