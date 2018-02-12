`include "./Head.v"
//`include "./Tools/Divider.v"
`include "./Tools/Random_Generator_N_bits_auto.v"
`include "./Tools/Random_Generator_16bits.v"

module Block_Controller(CLK,START,RESET,SQUARE_READY,OVER,BLOCK_SHAPE,BLOCK_START_X,BLOCK_COLOR);
	input CLK;//100Hz
	input START;
	input RESET;
	input SQUARE_READY;
	input OVER;
	output [4*`SHAPE_ENCODE_LENGTH-1:0]BLOCK_SHAPE;//代各4个图形的编号，每种图形编码为4位
	output [4*`COORDINATE_LENGTH-1:0]BLOCK_START_X;//4个图形的左上角x坐标
	output [4*`COLOR_ENCODE_LENGTH-1:0]BLOCK_COLOR;//代表4个图形的颜色，每个颜色编码为3位

	/*
	上电后，障碍块在固定区域自由变动
	START有效后，停止变动
	SQUARE_READY有效，代表方块已就位，此时障碍块开始移动
	OVER有效时代表游戏结束，障碍块停止动
	RESET有效代表重置，此时障碍块回到在固定区域自由变动的状态
	*/

	parameter every_time_move_length=10'd2;//每次障碍块移动的长度

	reg [`SHAPE_ENCODE_LENGTH-1:0]shape_1=`SHAPE_0;
	reg [`SHAPE_ENCODE_LENGTH-1:0]shape_2=`SHAPE_0;
	reg [`SHAPE_ENCODE_LENGTH-1:0]shape_3=`SHAPE_0;
	reg [`SHAPE_ENCODE_LENGTH-1:0]shape_4=`SHAPE_0;
	reg [`COORDINATE_LENGTH-1:0]coordinate_1=`INITIAL_BLOCK_1_X;
	reg [`COORDINATE_LENGTH-1:0]coordinate_2=`INITIAL_BLOCK_2_X;
	reg [`COORDINATE_LENGTH-1:0]coordinate_3=`INITIAL_BLOCK_3_X;
	reg [`COORDINATE_LENGTH-1:0]coordinate_4=`INITIAL_BLOCK_4_X;
	reg [`COLOR_ENCODE_LENGTH-1:0]color_1=`PINK;//虽然身为一个21岁的男子
	reg [`COLOR_ENCODE_LENGTH-1:0]color_2=`PINK;//可是我喜欢粉色
	reg [`COLOR_ENCODE_LENGTH-1:0]color_3=`PINK;//你仿佛有些许意见
	reg [`COLOR_ENCODE_LENGTH-1:0]color_4=`PINK;

	assign BLOCK_SHAPE={shape_1,shape_2,shape_3,shape_4};
	assign BLOCK_START_X={coordinate_1,coordinate_2,coordinate_3,coordinate_4};
	assign BLOCK_COLOR={color_1,color_2,color_3,color_4};
	
	//以下为随机数生成部分
	wire random_clk;
	Divider #(6,40)get_random_clk(CLK,random_clk);

	//方便后期调整图形和颜色编码，所以使用了define定下了编码长度
	wire [4*`COLOR_ENCODE_LENGTH-1:0]temp_color;
	wire [4*`SHAPE_ENCODE_LENGTH-1:0]temp_shape;
	Random_Generator_N_bits_auto #(.N(4*`COLOR_ENCODE_LENGTH))temp_color_getter(random_clk,temp_color);
	Random_Generator_N_bits_auto #(.N(4*`SHAPE_ENCODE_LENGTH))temp_shape_getter(random_clk,temp_shape);

	reg random_generator_reset=0;
	wire [`COLOR_ENCODE_LENGTH-1:0]color_random;
	wire [`SHAPE_ENCODE_LENGTH-1:0]shape_random;
	wire [15:0]random_result;
	Random_Generator_16bits random_getter(~random_clk,random_generator_reset,temp_shape,random_result);
	assign color_random=random_result[`COLOR_ENCODE_LENGTH-1:0];
	assign shape_random=random_result[15:`SHAPE_ENCODE_LENGTH+1];


	//判断第一个障碍块是否消失于视野之外
	wire blocks_ought_to_change;
	assign blocks_ought_to_change=(coordinate_1<(10'd143+every_time_move_length-`BLOCK_WIDTH));

	//状态机描述
	parameter FREE_CHANGE=2'b00;
	parameter WAIT_SQUARE_READY=2'b01;
	parameter MOVE=2'b11;
	parameter GAME_OVER=2'b10;

	reg [1:0]current_state=FREE_CHANGE;
	reg [1:0]next_state;

	always @(posedge CLK)begin
		if(RESET)begin
			current_state<=FREE_CHANGE;
		end
		else begin
			current_state<=next_state;
		end
	end

	always @(current_state or START or SQUARE_READY or OVER)begin
		case(current_state)
			FREE_CHANGE:begin
				if(START)begin
					next_state=WAIT_SQUARE_READY;
				end
				else begin
					next_state=FREE_CHANGE;
				end
			end
			WAIT_SQUARE_READY:begin
				if(SQUARE_READY)begin
					next_state=MOVE;
				end
				else begin
					next_state=WAIT_SQUARE_READY;
				end
			end
			MOVE:begin
				if(~OVER)begin
					next_state=MOVE;
				end
				else begin
					next_state=GAME_OVER;
				end
			end
			GAME_OVER:begin
				next_state=GAME_OVER;
			end
			default:begin
				next_state=FREE_CHANGE;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			FREE_CHANGE:begin
				random_generator_reset<=0;
			end
			WAIT_SQUARE_READY:begin
				random_generator_reset<=1;
			end
			MOVE:begin
				random_generator_reset<=0;
			end
			GAME_OVER:begin
				random_generator_reset<=0;
			end
			default:begin
				random_generator_reset<=0;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			FREE_CHANGE:begin
				{coordinate_1,coordinate_2,coordinate_3,coordinate_4}<=
				{`INITIAL_BLOCK_1_X,`INITIAL_BLOCK_2_X,`INITIAL_BLOCK_3_X,`INITIAL_BLOCK_4_X};
			end
			WAIT_SQUARE_READY:begin
				{coordinate_1,coordinate_2,coordinate_3,coordinate_4}<=
				{coordinate_1,coordinate_2,coordinate_3,coordinate_4};
			end
			MOVE:begin
				if(blocks_ought_to_change)begin
					{coordinate_1,coordinate_2,coordinate_3,coordinate_4}<=
					{coordinate_2,coordinate_3,coordinate_4,10'd782};
				end
				else begin
					{coordinate_1,coordinate_2,coordinate_3,coordinate_4}<=
					{coordinate_1-every_time_move_length,coordinate_2-every_time_move_length,
						coordinate_3-every_time_move_length,coordinate_4-every_time_move_length};//每次左移
				end
			end
			GAME_OVER:begin
				{coordinate_1,coordinate_2,coordinate_3,coordinate_4}<=
				{coordinate_1,coordinate_2,coordinate_3,coordinate_4};
			end
			default:begin
				{coordinate_1,coordinate_2,coordinate_3,coordinate_4}<=
				{coordinate_1,coordinate_2,coordinate_3,coordinate_4};
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			FREE_CHANGE:begin
				{shape_1,shape_2,shape_3,shape_4}<=temp_shape;
			end
			WAIT_SQUARE_READY:begin
				{shape_1,shape_2,shape_3,shape_4}<=
				{shape_1,shape_2,shape_3,shape_4};
			end
			MOVE:begin
				if(blocks_ought_to_change)begin
					{shape_1,shape_2,shape_3,shape_4}<=
					{shape_2,shape_3,shape_4,shape_random};
				end
				else begin
					{shape_1,shape_2,shape_3,shape_4}<=
					{shape_1,shape_2,shape_3,shape_4};
				end
			end
			GAME_OVER:begin
				{shape_1,shape_2,shape_3,shape_4}<=
				{shape_1,shape_2,shape_3,shape_4};
			end
			default:begin
				{shape_1,shape_2,shape_3,shape_4}<=
				{shape_1,shape_2,shape_3,shape_4};
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			FREE_CHANGE:begin
				{color_1,color_2,color_3,color_4}<=temp_color;
			end
			WAIT_SQUARE_READY:begin
				{color_1,color_2,color_3,color_4}<=
				{color_1,color_2,color_3,color_4};
			end
			MOVE:begin
				if(blocks_ought_to_change)begin
					{color_1,color_2,color_3,color_4}<=
					{color_2,color_3,color_4,color_random};
				end
				else begin
					{color_1,color_2,color_3,color_4}<=
					{color_1,color_2,color_3,color_4};
				end		
			end
			GAME_OVER:begin
				{color_1,color_2,color_3,color_4}<=
				{color_1,color_2,color_3,color_4};
			end
			default:begin
				{color_1,color_2,color_3,color_4}<=
				{color_1,color_2,color_3,color_4};
			end
		endcase
	end
endmodule