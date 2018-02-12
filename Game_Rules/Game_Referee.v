`include "./Head.v"
`include "./Game_Rules/Overlapping_Judge.v"

module Game_Referee(CLK,START,RESET,GAME_READY,BLOCK_SHAPE,BLOCK_START_X,SQUARE_START_Y,SQUARE_SIZE,HURT,INVINCIBLE,RECOVER,OVER);
	input CLK;//100Hz
	input START;
	input RESET;
	input GAME_READY;
	input [4*`SHAPE_ENCODE_LENGTH-1:0]BLOCK_SHAPE;
	input [4*`COORDINATE_LENGTH-1:0]BLOCK_START_X;
	input [`COORDINATE_LENGTH-1:0]SQUARE_START_Y;
	input [`SQUARE_SIZE_LENGTH-1:0]SQUARE_SIZE;
	output reg HURT;
	output reg INVINCIBLE;
	output reg RECOVER;
	output reg OVER;

	/*
	开始时START置为1，则开始执行游戏规则
	游戏次数由这个模块控制
	如果机会全部用完则游戏结束，OVER置为1
	*/

	reg [1:0]rest_life=2'd3;


	//记录当前未受伤游戏时间
	reg playing_time_counter_enable=0;
	reg playing_time_counter_reset=0;
	wire [10:0]playing_time_counter_result;
	wire recover_time;
	Counter #(.WIDTH(11))playing_time_counter(CLK,playing_time_counter_enable,playing_time_counter_reset,playing_time_counter_result);
	assign recover_time=(playing_time_counter_result>=11'd500);


	//判断进入INVINCIBLE状态后，是否超过了2秒，若超过则跳出这个状态
	reg invincible_time_counter_enable=0;
	reg invincible_time_counter_reset=0;
	wire [7:0]invincible_time_counter_result;
	wire invincible_time_end;
	Counter #(.WIDTH(8))invincible_time_counter(CLK,invincible_time_counter_enable,invincible_time_counter_reset,invincible_time_counter_result);
	assign invincible_time_end=(invincible_time_counter_result>=8'd250);

	
	//判断当前情况是否产生重叠
	wire is_overlapping;
	assign LED=is_overlapping;
	Overlapping_Judge judger(BLOCK_SHAPE,BLOCK_START_X,SQUARE_START_Y,SQUARE_SIZE,is_overlapping);


	parameter WAIT_TO_START=3'b000;
	parameter WAIT_GAME_READY=3'b001;
	parameter GOING_TO_BE_INVINCIBLE=3'b011;
	parameter IS_INVINCIBLE=3'b010;
	parameter IS_NORMAL=3'b110;
	parameter SEND_HURT=3'b111;
	parameter SEND_RECOVER=3'b101;
	parameter GAME_OVER=3'b100;

	reg [2:0]current_state=WAIT_TO_START;
	reg [2:0]next_state;

	always @(negedge CLK)begin
		if(RESET)begin
			current_state<=WAIT_TO_START;
		end
		else begin
			current_state<=next_state;
		end
	end

	always @(*)begin
		case(current_state)
			WAIT_TO_START:begin
				if(START)begin
					next_state=WAIT_GAME_READY;
				end	
				else begin
					next_state=WAIT_TO_START;
				end
			end
			WAIT_GAME_READY:begin
				if(GAME_READY)begin
					next_state=GOING_TO_BE_INVINCIBLE;
				end
				else begin
					next_state=WAIT_GAME_READY;
				end
			end
			GOING_TO_BE_INVINCIBLE:begin
				next_state=IS_INVINCIBLE;
			end
			IS_INVINCIBLE:begin
				if(invincible_time_end)begin
					next_state=IS_NORMAL;
				end
				else begin
					next_state=IS_INVINCIBLE;
				end
			end
			IS_NORMAL:begin
				if(is_overlapping)begin
					next_state=SEND_HURT;
				end
				else if(recover_time&(rest_life!=2'd3))begin
					next_state=SEND_RECOVER;
				end
				else begin
					next_state=IS_NORMAL;
				end
			end
			SEND_HURT:begin
				if(rest_life==2'd0)begin
					next_state=GAME_OVER;
				end
				else begin
					next_state=GOING_TO_BE_INVINCIBLE;	
				end
			end
			SEND_RECOVER:begin
				next_state=GOING_TO_BE_INVINCIBLE;
			end
			GAME_OVER:begin
				next_state=GAME_OVER;
			end
			default:begin
				next_state=WAIT_TO_START;
			end
		endcase
	end

	always @(negedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				playing_time_counter_enable<=0;
				playing_time_counter_reset<=1;
			end
			WAIT_GAME_READY:begin
				playing_time_counter_enable<=0;
				playing_time_counter_reset<=1;
			end
			GOING_TO_BE_INVINCIBLE:begin
				playing_time_counter_enable<=0;
				playing_time_counter_reset<=1;
			end
			IS_INVINCIBLE:begin
				playing_time_counter_enable<=0;
				playing_time_counter_reset<=1;
			end
			IS_NORMAL:begin
				playing_time_counter_enable<=1;
				playing_time_counter_reset<=0;
			end
			SEND_HURT:begin
				playing_time_counter_enable<=0;
				playing_time_counter_reset<=1;
			end
			SEND_RECOVER:begin
				playing_time_counter_enable<=0;
				playing_time_counter_reset<=1;
			end
			GAME_OVER:begin
				playing_time_counter_enable<=0;
				playing_time_counter_reset<=1;
			end
			default:begin
				playing_time_counter_enable<=0;
				playing_time_counter_reset<=1;
			end
		endcase
	end

	always @(negedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				invincible_time_counter_enable<=0;
				invincible_time_counter_reset<=1;
			end
			WAIT_GAME_READY:begin
				invincible_time_counter_enable<=0;
				invincible_time_counter_reset<=1;
			end
			GOING_TO_BE_INVINCIBLE:begin
				invincible_time_counter_enable<=0;
				invincible_time_counter_reset<=1;
			end
			IS_INVINCIBLE:begin
				invincible_time_counter_enable<=1;
				invincible_time_counter_reset<=0;
			end
			IS_NORMAL:begin
				invincible_time_counter_enable<=0;
				invincible_time_counter_reset<=1;
			end
			SEND_HURT:begin
				invincible_time_counter_enable<=0;
				invincible_time_counter_reset<=1;
			end
			SEND_RECOVER:begin
				invincible_time_counter_enable<=0;
				invincible_time_counter_reset<=1;
			end
			GAME_OVER:begin
				invincible_time_counter_enable<=0;
				invincible_time_counter_reset<=1;
			end
			default:begin
				invincible_time_counter_enable<=0;
				invincible_time_counter_reset<=1;
			end
		endcase
	end

	always @(negedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				rest_life<=2'd3;
			end
			WAIT_GAME_READY:begin
				rest_life<=2'd3;
			end
			GOING_TO_BE_INVINCIBLE:begin
				rest_life<=rest_life;
			end
			IS_INVINCIBLE:begin
				rest_life<=rest_life;
			end
			IS_NORMAL:begin
				rest_life<=rest_life;
			end
			SEND_HURT:begin
				rest_life<=rest_life-1;
			end
			SEND_RECOVER:begin
				rest_life<=rest_life+1;
			end
			GAME_OVER:begin
				rest_life<=rest_life;
			end
			default:begin
				rest_life<=rest_life;
			end
		endcase
	end

	always @(negedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				HURT<=0;
				RECOVER<=0;
				INVINCIBLE<=0;
			end
			WAIT_GAME_READY:begin
				HURT<=0;
				RECOVER<=0;
				INVINCIBLE<=0;
			end
			GOING_TO_BE_INVINCIBLE:begin
				HURT<=0;
				RECOVER<=0;
				INVINCIBLE<=1;
			end
			IS_INVINCIBLE:begin
				HURT<=0;
				RECOVER<=0;
				INVINCIBLE<=1;
			end
			IS_NORMAL:begin
				HURT<=0;
				RECOVER<=0;
				INVINCIBLE<=0;
			end
			SEND_HURT:begin
				HURT<=1;
				RECOVER<=0;
				INVINCIBLE<=0;
			end
			SEND_RECOVER:begin
				HURT<=0;
				RECOVER<=1;
				INVINCIBLE<=0;
			end
			GAME_OVER:begin
				HURT<=0;
				RECOVER<=0;
				INVINCIBLE<=0;
			end
			default:begin
				HURT<=0;
				RECOVER<=0;
				INVINCIBLE<=0;
			end
		endcase
	end

	always @(negedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				OVER<=0;
			end
			WAIT_GAME_READY:begin
				OVER<=0;
			end
			GOING_TO_BE_INVINCIBLE:begin
				OVER<=0;
			end
			IS_INVINCIBLE:begin
				OVER<=0;
			end
			IS_NORMAL:begin
				OVER<=0;
			end
			SEND_HURT:begin
				OVER<=0;
			end
			SEND_RECOVER:begin
				OVER<=0;
			end
			GAME_OVER:begin
				OVER<=1;
			end
			default:begin
				OVER<=0;
			end
		endcase
	end
endmodule