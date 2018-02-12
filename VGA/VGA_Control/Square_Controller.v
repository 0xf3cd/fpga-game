`include "./Head.v"
`include "./VGA/VGA_Control/Square_Color_Controller.v"
`include "./VGA/VGA_Control/Square_Coordinate_Controller.v"
`include "./Sound/Sound_Encoder.v"

module Square_Controller(CLK,SOUND_WAVE,RESET,START,HURT,RECOVER,INVINCIBLE,OVER,DROP_READY,SQUARE_START_Y,SQUARE_SIZE,SQUARE_COLOR);
	input CLK;//100Hz
	input SOUND_WAVE;
	input RESET;
	input START;
	input HURT;//当游戏机会次数-1时，HURT置为1,随后置为0
	input RECOVER;//机会次数+1
	input INVINCIBLE;//有效时代表方块处于不死状态
	input OVER;//游戏结束信号
	output DROP_READY;
	output [`COORDINATE_LENGTH-1:0]SQUARE_START_Y;//要显示的方块左上角的Y坐标
	output [`SQUARE_SIZE_LENGTH-1:0]SQUARE_SIZE;//要显示的方块边长
	output [`SQUARE_STATE_ENCODE_LENGTH-1:0]SQUARE_COLOR;//方块的颜色
	/*
	*该模块负责告知VGA显示模块方块的位置以及颜色
	
	*与外部进行通信，接收启动、重置、停止等指令
	*发送DROP_READY信号告知外部方块已就位
	*HURT RECOVER INVINCIBLE等信号标志游戏机会的增加与减少等等
	*OVER信号有效时，代表游戏结束
	
	*与声音采样编码器进行通信，接收音高等级
	*/

	/*
	向VGA显示模块传递以下数值即可显示
	input [9:0]SQUARE_START_Y;//要显示的方块左上角的Y坐标
	input [9:0]SQUARE_SIZE;//要显示的方块边长
	input [1:0]SQUARE_COLOR;//方块的颜色
	*/

	assign SQUARE_SIZE=`SQUARE_DEFAULT_SIZE;//'d12;//考虑后期进行调整

	wire[`SOUND_LEVEL_ENCODE_LENGTH-1:0] sound_level;
	Sound_Encoder get_sound_level(CLK,SOUND_WAVE,sound_level);


	//以下实例化了一个控制方块颜色的电路
	reg color_reset=0;//有效时颜色复位
	Square_Color_Controller color_controller(.CLK(CLK),
											 .RESET(color_reset),
											 .HURT(HURT),
											 .RECOVER(RECOVER),
											 .INVINCIBLE_ENABLE(INVINCIBLE),
											 .SQUARE_COLOR(SQUARE_COLOR));

	reg coordinate_reset=0;
	reg drop_start=0;
	reg free_move_start=0;
	Square_Coordinate_Controller coordinate_controller(.CLK(CLK),
													   .RESET(coordinate_reset),
													   .DROP_START(drop_start),
													   .FREE_MOVE(free_move_start),
													   .GAME_OVER(OVER),
													   .SOUND_LEVEL(sound_level),
													   .SQUARE_Y_COORDINATE(SQUARE_START_Y),
													   .DROP_FINISH(DROP_READY));


	/*
	状态机需要控制以下信号
	reg color_reset=0;
	reg coordinate_reset=0;
	reg drop_start=0;
	reg free_move_start=0;
	*/

	//状态机描述
	parameter HIDE=2'b00;
	parameter DROP=2'b01;
	parameter FREE_MOVE=2'b11;
	parameter GAME_OVER=2'b10;

	reg [1:0]current_state=HIDE;
	reg [1:0]next_state;

	always @(posedge CLK)begin
		if(RESET)begin
			current_state<=HIDE;
		end
		else begin
			current_state<=next_state;
		end
	end

	always @(current_state or START or DROP_READY or OVER)begin
		case(current_state)
			HIDE:begin
				if(START)begin
					next_state=DROP;
				end
				else begin
					next_state=HIDE;
				end
			end
			DROP:begin
				if(DROP_READY)begin
					next_state=FREE_MOVE;
				end
				else begin
					next_state=DROP;
				end
			end
			FREE_MOVE:begin
				if(!OVER)begin
					next_state=FREE_MOVE;
				end
				else begin
					next_state=GAME_OVER;
				end
			end
			GAME_OVER:begin
				next_state=GAME_OVER;//这个状态下只有接收到RESET信号才能复位
			end
			default:begin
				next_state=HIDE;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			HIDE:begin
				color_reset<=1;
				coordinate_reset<=1;
			end
			DROP:begin
				color_reset<=0;
				coordinate_reset<=0;
			end
			FREE_MOVE:begin
				color_reset<=0;
				coordinate_reset<=0;
			end
			GAME_OVER:begin
				color_reset<=0;
				coordinate_reset<=0;
			end
			default:begin
				color_reset<=1;
				coordinate_reset<=1;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			HIDE:begin
				drop_start<=0;
				free_move_start<=0;
			end
			DROP:begin
				drop_start<=1;
				free_move_start<=0;
			end
			FREE_MOVE:begin
				drop_start<=0;
				free_move_start<=1;
			end
			GAME_OVER:begin
				drop_start<=0;
				free_move_start<=0;
			end
			default:begin
				drop_start<=0;
				free_move_start<=0;
			end
		endcase
	end
endmodule
