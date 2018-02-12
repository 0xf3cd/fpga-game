`include "./Head.v"
`include "./Game_Rules/Game_Referee.v"
`include "./VGA/VGA_Control/VGA_Controller.v"
`include "./VGA/VGA_Output/VGA_Output.v"

module Game(CLK,SOUND_WAVE,VGA_ENABLE,GAME_START,GAME_RESET,GAME_OVER,GAME_HURT,H_SYNC,V_SYNC,R,G,B);
	input CLK;
	input SOUND_WAVE;
	input VGA_ENABLE;
	input GAME_START;
	input GAME_RESET;
	output GAME_OVER;
	output GAME_HURT;
	output H_SYNC;
	output V_SYNC;
	output [3:0]R;
	output [3:0]G;
	output [3:0]B;

	/*
	这个模块将游戏规则控制模块与VGA显示模块相连接
	*/

	wire [4*`SHAPE_ENCODE_LENGTH-1:0]BLOCK_SHAPE;//代各4个图形的编号，每种图形编码为4位
	wire [4*`COORDINATE_LENGTH-1:0]BLOCK_START_X;//4个图形的左上角x坐标
	wire [4*`COLOR_ENCODE_LENGTH-1:0]BLOCK_COLOR;//代表4个图形的颜色，每个颜色编码为3位
	wire [`COORDINATE_LENGTH-1:0]SQUARE_START_Y;//要显示的方块左上角的Y坐标
	wire [`SQUARE_SIZE_LENGTH-1:0]SQUARE_SIZE;//要显示的方块边长
	wire [`SQUARE_STATE_ENCODE_LENGTH-1:0]SQUARE_COLOR;//方块的颜色
	wire referee_clk;
	wire game_ready;
	wire hurt;
	wire recover;
	wire invincible;
	assign GAME_HURT=hurt;

	Divider #(30,1000000)get_referee_clk(CLK,referee_clk);

	Game_Referee game_referee(.CLK(referee_clk),
							  .START(GAME_START),
							  .RESET(GAME_RESET),
							  .GAME_READY(game_ready),
							  .BLOCK_SHAPE(BLOCK_SHAPE),
							  .BLOCK_START_X(BLOCK_START_X),
							  .SQUARE_START_Y(SQUARE_START_Y),
							  .SQUARE_SIZE(SQUARE_SIZE),
							  .HURT(hurt),
							  .INVINCIBLE(invincible),
							  .RECOVER(recover),
							  .OVER(GAME_OVER));

	VGA_Controller vga_controller(.CLK(CLK),
	 						  .SOUND_WAVE(SOUND_WAVE),
	 						  .RESET(GAME_RESET),
	 						  .START(GAME_START),
	 						  .HURT(hurt),
	 						  .RECOVER(recover),
	 						  .INVINCIBLE(invincible),
	 						  .OVER(GAME_OVER),
	 						  .BLOCK_SHAPE(BLOCK_SHAPE),
	 						  .BLOCK_START_X(BLOCK_START_X),
	 						  .BLOCK_COLOR(BLOCK_COLOR),
	 						  .SQUARE_START_Y(SQUARE_START_Y),
	 						  .SQUARE_SIZE(SQUARE_SIZE),
	 						  .SQUARE_COLOR(SQUARE_COLOR),
	 						  .GAME_READY(game_ready));

	VGA_Output vga_output(.CLK(CLK),
		 				  .ENABLE(VGA_ENABLE),
		 				  .RESET(GAME_RESET),
		 				  .BLOCK_SHAPE(BLOCK_SHAPE),
		 				  .BLOCK_START_X(BLOCK_START_X),
		 				  .BLOCK_COLOR(BLOCK_COLOR),
		 				  .SQUARE_START_Y(SQUARE_START_Y),
		 				  .SQUARE_SIZE(SQUARE_SIZE),
		 				  .SQUARE_COLOR(SQUARE_COLOR),
		 				  .H_SYNC(H_SYNC),
		 				  .V_SYNC(V_SYNC),
		 				  .RGB({R,G,B}));
endmodule