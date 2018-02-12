`include "./Head.v"

module Square_Color_Controller(CLK,RESET,HURT,RECOVER,INVINCIBLE_ENABLE,SQUARE_COLOR);
	input CLK;
	input RESET;
	input HURT;
	input RECOVER;
	input INVINCIBLE_ENABLE;
	output reg [`SQUARE_STATE_ENCODE_LENGTH-1:0]SQUARE_COLOR;//方块的颜色

	parameter STRONG=2'b00;
	parameter OK=2'b01;
	parameter WEAK=2'b11;
	parameter INVINCIBLE=2'b10;

	reg [1:0]current_state=STRONG;
	reg [1:0]next_state;
	reg [1:0]state_saver;

	always @(negedge CLK)begin
		if(current_state!=INVINCIBLE)begin
			state_saver<=current_state;
		end
		else begin
			state_saver<=state_saver;
		end
	end

	always @(posedge CLK)begin
		if(RESET)begin
			current_state<=STRONG;
		end
		else begin
			current_state<=next_state;
		end
	end

	always @(current_state or INVINCIBLE_ENABLE or HURT or RECOVER or state_saver)begin
		case(current_state)
			STRONG:begin
				if(INVINCIBLE_ENABLE)begin
					next_state=INVINCIBLE;
				end
				else if(HURT)begin
					next_state=OK;
				end
				else begin
					next_state=STRONG;
				end
			end
			OK:begin
				if(INVINCIBLE_ENABLE)begin
					next_state=INVINCIBLE;
				end
				else if(RECOVER)begin
					next_state=STRONG;
				end
				else if(HURT)begin
					next_state=WEAK;
				end
				else begin
					next_state=OK;
				end
			end
			WEAK:begin
				if(INVINCIBLE_ENABLE)begin
					next_state=INVINCIBLE;
				end
				else if(RECOVER)begin
					next_state=OK;
				end
				else begin
					next_state=WEAK;
				end
			end
			INVINCIBLE:begin
				if(INVINCIBLE_ENABLE)begin
					next_state=INVINCIBLE;
				end
				else begin
					next_state=state_saver;//恢复成之前状态
				end
			end
			default:begin
				next_state=STRONG;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			STRONG:begin
				SQUARE_COLOR<=`SQUARE_STRONG;
			end
			OK:begin
				SQUARE_COLOR<=`SQUARE_OKAY;
			end
			WEAK:begin
				SQUARE_COLOR<=`SQUARE_WEAK;
			end
			INVINCIBLE:begin
				SQUARE_COLOR<=`SQUARE_INVINCIBLE;
			end
			default:begin
				SQUARE_COLOR<=`SQUARE_STRONG;
			end
		endcase
	end
endmodule