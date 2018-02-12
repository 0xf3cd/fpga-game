`include "./Head.v"
`include "./VGA/VGA_Control/Square_Controller.v"
`include "./VGA/VGA_Control/Block_Controller.v"
//`include "./Tools/Divider.v"

module VGA_Controller(CLK,SOUND_WAVE,RESET,START,HURT,RECOVER,INVINCIBLE,OVER,BLOCK_SHAPE,BLOCK_START_X,BLOCK_COLOR,SQUARE_START_Y,SQUARE_SIZE,SQUARE_COLOR,GAME_READY);
	input CLK;
	input SOUND_WAVE;
	input RESET;
	input START;
	input HURT;
	input RECOVER;
	input INVINCIBLE;
	input OVER;
	output [4*`SHAPE_ENCODE_LENGTH-1:0]BLOCK_SHAPE;//代各4个图形的编号，每种图形编码为4位
	output [4*`COORDINATE_LENGTH-1:0]BLOCK_START_X;//4个图形的左上角x坐标
	output [4*`COLOR_ENCODE_LENGTH-1:0]BLOCK_COLOR;//代表4个图形的颜色，每个颜色编码为3位
	output [`COORDINATE_LENGTH-1:0]SQUARE_START_Y;//要显示的方块左上角的Y坐标
	output [`SQUARE_SIZE_LENGTH-1:0]SQUARE_SIZE;//要显示的方块边长
	output [`SQUARE_STATE_ENCODE_LENGTH-1:0]SQUARE_COLOR;//方块的颜色
	output GAME_READY;

	Divider #(20,1000000)get_clk_100Hz(CLK,clk_100Hz);

	wire square_ready;
	assign GAME_READY=square_ready;

	/*
	*该模块负责告知VGA显示模块方块的位置以及颜色
	
	*与外部进行通信，接收启动、重置、停止等指令
	*发送DROP_READY信号告知外部方块已就位
	*HURT RECOVER INVINCIBLE等信号标志游戏机会的增加与减少等等
	*OVER信号有效时，代表游戏结束
	
	*与声音采样编码器进行通信，接收音高等级
	*/
	Square_Controller square_control(.CLK(clk_100Hz),//100Hz
									 .SOUND_WAVE(SOUND_WAVE),
									 .RESET(RESET),
									 .START(START),
									 .HURT(HURT),
									 .RECOVER(RECOVER),
									 .INVINCIBLE(INVINCIBLE),
									 .OVER(OVER),
									 .DROP_READY(square_ready),
									 .SQUARE_START_Y(SQUARE_START_Y),
									 .SQUARE_SIZE(SQUARE_SIZE),
									 .SQUARE_COLOR(SQUARE_COLOR));

	/*
	上电后，障碍块在固定区域自由变动
	START有效后，停止变动
	SQUARE_READY有效，代表方块已就位，此时障碍块开始移动
	OVER有效时代表游戏结束，障碍块停止动
	RESET有效代表重置，此时障碍块回到在固定区域自由变动的状态
	*/
	Block_Controller block_control(.CLK(clk_100Hz),//100Hz
								   .START(START),
								   .RESET(RESET),
								   .SQUARE_READY(square_ready),
								   .OVER(OVER),
								   .BLOCK_SHAPE(BLOCK_SHAPE),
								   .BLOCK_START_X(BLOCK_START_X),
								   .BLOCK_COLOR(BLOCK_COLOR));

endmodule