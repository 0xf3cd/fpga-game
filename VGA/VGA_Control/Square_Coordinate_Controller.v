`include "./Head.v"

module Square_Coordinate_Controller(CLK,RESET,DROP_START,FREE_MOVE,GAME_OVER,SOUND_LEVEL,SQUARE_Y_COORDINATE,DROP_FINISH);
	input CLK;
	input RESET;
	input DROP_START;
	input FREE_MOVE;
	input GAME_OVER;
	input [`SOUND_LEVEL_ENCODE_LENGTH-1:0] SOUND_LEVEL;
	output reg [`COORDINATE_LENGTH-1:0]SQUARE_Y_COORDINATE;
	output reg DROP_FINISH;

	parameter IDLE=3'b000;
	parameter DROP=3'b001;
	parameter MOVE_WAIT=3'b011;
	parameter MOVE=3'b010;
	parameter OVER=3'b110;

	reg [2:0]current_state=IDLE;
	reg [2:0]next_state;

	always @(posedge CLK)begin
		if(RESET)begin
			current_state<=IDLE;
		end
		else begin
			current_state<=next_state;
		end
	end
	
	wire drop_finish;
	assign drop_finish=(SQUARE_Y_COORDINATE>='d180);

	always @(current_state or DROP_START or drop_finish or FREE_MOVE or GAME_OVER)begin
		case(current_state)
			IDLE:begin
				if(DROP_START)begin
					next_state=DROP;
				end
				else begin
					next_state=IDLE;
				end
			end
			DROP:begin
				if(drop_finish)begin
					next_state=MOVE_WAIT;
				end
				else begin
					next_state=DROP;
				end
			end
			MOVE_WAIT:begin
				if(FREE_MOVE)begin
					next_state=MOVE;
				end
				else begin
					next_state=MOVE_WAIT;
				end
			end
			MOVE:begin
				if(GAME_OVER)begin
					next_state=OVER;
				end
				else begin
					next_state=MOVE;
				end
			end
			OVER:begin
				next_state=OVER;
			end
			default:begin
				next_state=IDLE;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			IDLE:begin
				DROP_FINISH<=0;
			end
			DROP:begin
				DROP_FINISH<=0;
			end
			MOVE_WAIT:begin
				DROP_FINISH<=1;
			end
			MOVE:begin
				DROP_FINISH<=0;
			end
			OVER:begin
				DROP_FINISH<=0;
			end
			default:begin
				DROP_FINISH<=0;
			end
		endcase
	end

	//以下代码决定方块的y坐标
	wire y_up_movable;
	wire y_down_movable;
	assign y_up_movable=(SQUARE_Y_COORDINATE>='d42);
	assign y_down_movable=(SQUARE_Y_COORDINATE<='d492);

	always @(posedge CLK)begin
		case(next_state)
			IDLE:begin
				SQUARE_Y_COORDINATE<='d20;
			end
			DROP:begin
				SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE+'d2;
			end
			MOVE_WAIT:begin
				SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE;
			end
			MOVE:begin
				case(SOUND_LEVEL)
					`NO_SOUND:begin
						if(y_down_movable)begin
							SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE+'d4;
						end
						else begin
							SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE;
						end
					end
					`LEVEL_1:begin
						if(y_up_movable)begin
							SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE-'d1;
						end
						else begin
							SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE;
						end
					end
					`LEVEL_2:begin
						if(y_up_movable)begin
							SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE-'d3;
						end
						else begin
							SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE;
						end
					end
					`LEVEL_3:begin
						if(y_up_movable)begin
							SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE-'d5;
						end
						else begin
							SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE;
						end
					end
					`LEVEL_4:begin
						if(y_up_movable)begin
							SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE-'d7;
						end
						else begin
							SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE;
						end
					end
					`LEVEL_5:begin
						if(y_up_movable)begin
							SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE-'d10;
						end
						else begin
							SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE;
						end
					end
					default:begin
						if(y_down_movable)begin
							SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE+'d4;
						end
						else begin
							SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE;
						end
					end
				endcase
			end
			OVER:begin
				SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE;
			end
			default:begin
				SQUARE_Y_COORDINATE<=SQUARE_Y_COORDINATE;
			end
		endcase
	end
endmodule