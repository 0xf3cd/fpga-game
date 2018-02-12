`include "./Head.v"
//`include "./Tools/Divider.v"
`include "./VGA/VGA_Output/VGA_Counter.v"
`include "./VGA/VGA_Output/Position_Judge.v"
`include "./VGA/VGA_Output/Block_Color_Selector.v"
`include "./VGA/VGA_Output/Square_Color_Selector.v"
`include "./Tools/Random_Generator_12bits_auto.v"

module VGA_Output(CLK,ENABLE,RESET,BLOCK_SHAPE,BLOCK_START_X,BLOCK_COLOR,SQUARE_START_Y,SQUARE_SIZE,SQUARE_COLOR,H_SYNC,V_SYNC,RGB);
	input CLK;//100MHz
	input ENABLE;
	input RESET;
	input [4*`SHAPE_ENCODE_LENGTH-1:0]BLOCK_SHAPE;//代各4个图形的编号，每种图形编码为4位
	input [4*`COORDINATE_LENGTH-1:0]BLOCK_START_X;//4个图形的左上角x坐标
	input [4*`COLOR_ENCODE_LENGTH-1:0]BLOCK_COLOR;//代表4个图形的颜色，每个颜色编码为3位
	input [`COORDINATE_LENGTH-1:0]SQUARE_START_Y;//要显示的方块左上角的Y坐标
	input [`SQUARE_SIZE_LENGTH-1:0]SQUARE_SIZE;//要显示的方块边长
	input [`SQUARE_STATE_ENCODE_LENGTH-1:0]SQUARE_COLOR;//方块的颜色
	output H_SYNC;//行同步信号
	output V_SYNC;//场同步信号
	output reg [`RGB_LENGTH-1:0]RGB;

	/*
	约定左上角第一个点坐标为(0,0)
	实际显示的时候，H_counter-143 V_counter-32 为x,y坐标
	That is to say,(143,32)对应屏幕左上角第一个点
	*/

	/*
	每次传入需要显示的4个障碍物的相关信息，以及方块的y坐标
	VGA的25MHz时钟下降沿到来时将相关颜色信息写入RGB接口

	初始态为UNACTIVATED，需要将ENABLE设为有效才能跳出
	任何时候如果RESET置为1则回到UNACTIVATED态

	传入的x,y坐标应从143,32开始

	传入时钟为板载100MHz时钟
	*/

	wire VGA_clk;//25MHz的VGA时钟
	Divider #(2,4) VGA_clk_divider(CLK,VGA_clk);

	wire valid;//为1时说明不在消隐区，可以显示
	wire [`COORDINATE_LENGTH-1:0]x;//当前扫描点的x坐标
	wire [`COORDINATE_LENGTH-1:0]y;//当前扫描点的y坐标
	VGA_Counter V_counter_H_counter(.CLK(VGA_clk),
									.H_SYNC(H_SYNC),
									.V_SYNC(V_SYNC),
									.VALID(valid),
									.X(x),
									.Y(y));
	

	//以下为判断当前扫描位置是否在BLOCK或者SQUARE等需要显示的图形区域
	wire in_block_1;
	wire in_block_2;
	wire in_block_3;
	wire in_block_4;
	wire in_square;
	wire is_empty;
	wire [5:0]point_area;//以独热码编码方式记录当前点所在位置
	assign point_area={in_block_1,in_block_2,in_block_3,in_block_4,in_square,is_empty};
	Position_Judge position_judge(.BLOCK_SHAPE(BLOCK_SHAPE),
								  .BLOCK_START_X(BLOCK_START_X),
								  .SQUARE_START_Y(SQUARE_START_Y),
								  .SQUARE_SIZE(SQUARE_SIZE),
								  .X(x),
								  .Y(y),
								  .IN_BLOCK_1(in_block_1),
								  .IN_BLOCK_2(in_block_2),
								  .IN_BLOCK_3(in_block_3),
								  .IN_BLOCK_4(in_block_4),
								  .IN_SQUARE(in_square),
								  .IS_EMPTY(is_empty));


	//以下为状态机描述
	//由于场同步和行同步信号已由之上的语句负责，所以状态机只负责显示图像
	parameter UNACTIVATED=3'b000;
	parameter INVALID=3'b001;
	parameter OUTPUT_BLOCK_1=3'b011;
	parameter OUTPUT_BLOCK_2=3'b010;
	parameter OUTPUT_BLOCK_3=3'b110;
	parameter OUTPUT_BLOCK_4=3'b111;
	parameter OUTPUT_SQAURE=3'b101;
	parameter OUTPUT_EMPTY=3'b100;

	reg [2:0]current_state=UNACTIVATED;
	reg [2:0]next_state;


	always @(negedge VGA_clk)begin//避免竞争冒险，下降沿时状态翻转同时有所输出
		if(RESET)begin
			current_state<=UNACTIVATED;
		end
		else begin
			current_state<=next_state;
		end
	end

	always @(current_state or ENABLE or valid or point_area)begin//组合逻辑描述状态转移条件
		case(current_state)
			UNACTIVATED:begin
				if(ENABLE)begin
					next_state=OUTPUT_EMPTY;
				end
				else begin
					next_state=UNACTIVATED;
				end
			end
			default:begin//其余所有情况，需要根据当前扫描坐标来确定显示情况
				if(!valid)begin
					next_state=INVALID;
				end
				else begin
					case(point_area)
						6'b100000:begin
							next_state=OUTPUT_BLOCK_1;
						end
						6'b010000:begin
							next_state=OUTPUT_BLOCK_2;
						end
						6'b001000:begin
							next_state=OUTPUT_BLOCK_3;
						end
						6'b000100:begin
							next_state=OUTPUT_BLOCK_4;
						end
						6'b000010:begin
							next_state=OUTPUT_SQAURE;
						end
						6'b000001:begin
							next_state=OUTPUT_EMPTY;
						end
						default:begin
							next_state=OUTPUT_EMPTY;
						end
					endcase
				end
			end
		endcase
	end

	//以下语句描述每个状态下写入RGB的情况
	wire [`RGB_LENGTH-1:0]block1_color;
	wire [`RGB_LENGTH-1:0]block2_color;
	wire [`RGB_LENGTH-1:0]block3_color;
	wire [`RGB_LENGTH-1:0]block4_color;
	wire [`RGB_LENGTH-1:0]square_color;
	wire [`RGB_LENGTH-1:0]random_color_rgb;

	wire color_generate_clk;
	Divider #(22,5000000)get_color_generate_clk(VGA_clk,color_generate_clk);
	Random_Generator_12bits_auto get_random_color(color_generate_clk,random_color_rgb);
	
	Block_Color_Selector color_selector_1(BLOCK_COLOR[4*`COLOR_ENCODE_LENGTH-1:3*`COLOR_ENCODE_LENGTH],block1_color);
	Block_Color_Selector color_selector_2(BLOCK_COLOR[3*`COLOR_ENCODE_LENGTH-1:2*`COLOR_ENCODE_LENGTH],block2_color);
	Block_Color_Selector color_selector_3(BLOCK_COLOR[2*`COLOR_ENCODE_LENGTH-1:`COLOR_ENCODE_LENGTH],block3_color);
	Block_Color_Selector color_selector_4(BLOCK_COLOR[`COLOR_ENCODE_LENGTH*1-1:0],block4_color);
	Square_Color_Selector square_color_selector(SQUARE_COLOR,random_color_rgb,square_color);
	always @(negedge VGA_clk)begin
		case(next_state)
			UNACTIVATED:begin
				RGB<=`WHITE_RGB;
			end
			INVALID:begin
				RGB<=`BLACK_RGB;
			end
			OUTPUT_BLOCK_1:begin
				RGB<=block1_color;
			end
			OUTPUT_BLOCK_2:begin
				RGB<=block2_color;
			end
			OUTPUT_BLOCK_3:begin
				RGB<=block3_color;
			end
			OUTPUT_BLOCK_4:begin
				RGB<=block4_color;
			end
			OUTPUT_SQAURE:begin
				RGB<=square_color;
			end
			OUTPUT_EMPTY:begin
				RGB<=`WHITE_RGB;
			end
			default:begin
				RGB<=`WHITE_RGB;
			end
		endcase
	end
endmodule