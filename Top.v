`include "./Head.v"
`include "./Tools/Divider.v"
`include "./Tools/Counter.v"
`include "./Game.v"
`include "./Periphery.v"

module Top(CLK,SOUND_WAVE,SD_DO,MP3_SO,MP3_DREQ,START_USER,RESTART_USER,H_SYNC,V_SYNC,
		   R,G,B,SD_CS,SD_CLK,SD_DI,MP3_CLK,MP3_RESET_n,MP3_DCS,MP3_CS,MP3_SI,
		   SEGMENT_ACTIVE,AG_ENABLE);
	input CLK;
	input SOUND_WAVE;
	input SD_DO;
	input MP3_SO;
	input MP3_DREQ;
	input START_USER;
	input RESTART_USER;
	output H_SYNC;
	output V_SYNC;
	output [3:0]R;
	output [3:0]G;
	output [3:0]B;
	output SD_CS;
	output SD_CLK;
	output SD_DI;
	output MP3_CLK;
	output MP3_RESET_n;
	output MP3_DCS;
	output MP3_CS;
	output MP3_SI;
	output [7:0]SEGMENT_ACTIVE;//8个7段数码管是否被激活的控制信号
	output [6:0]AG_ENABLE;//A-G的通断控制.

	wire game_over;
	wire game_hurt;
	
	Game game(.CLK(CLK),
			  .SOUND_WAVE(SOUND_WAVE),
			  .VGA_ENABLE(1),//持续显示图像
			  .GAME_START(START_USER),
			  .GAME_RESET(RESTART_USER),
			  .GAME_OVER(game_over),
			  .GAME_HURT(game_hurt),
			  .H_SYNC(H_SYNC),
			  .V_SYNC(V_SYNC),
			  .R(R),
			  .G(G),
			  .B(B));
	

	Periphery periphery(.CLK(CLK),
						.SD_DO(SD_DO),
						.MP3_SO(MP3_SO),
						.MP3_DREQ(MP3_DREQ),
						.START(START_USER),
						.HURT(game_hurt),
						.OVER(game_over),
						.RESTART(RESTART_USER),
						.SD_CS(SD_CS),
						.SD_CLK(SD_CLK),
						.SD_DI(SD_DI),
						.MP3_CLK(MP3_CLK),
						.MP3_RESET_n(MP3_RESET_n),
						.MP3_DCS(MP3_DCS),
						.MP3_CS(MP3_CS),
						.MP3_SI(MP3_SI),
						.SEGMENT_ACTIVE(SEGMENT_ACTIVE),
						.AG_ENABLE(AG_ENABLE));
endmodule