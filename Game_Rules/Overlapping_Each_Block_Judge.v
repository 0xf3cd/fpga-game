`include "./Head.v"

module Overlapping_Each_Block_Judge(BLOCK_SHAPE,BLOCK_START_X,SQUARE_START_Y,SQUARE_SIZE,IS_OVERLAPPING);
	input [`SHAPE_ENCODE_LENGTH-1:0]BLOCK_SHAPE;
	input [`COORDINATE_LENGTH-1:0]BLOCK_START_X;
	input [`COORDINATE_LENGTH-1:0]SQUARE_START_Y;
	input [`SQUARE_SIZE_LENGTH-1:0]SQUARE_SIZE;
	output reg IS_OVERLAPPING;

	wire x_overlapping;
	assign x_overlapping=((`SQUARE_X<(BLOCK_START_X+`BLOCK_WIDTH))
						&((`SQUARE_X+SQUARE_SIZE)>BLOCK_START_X));

	always @(*)begin
		if(~x_overlapping)begin//X方向上无重叠，则必定不会相交
			IS_OVERLAPPING=0;
		end
		else begin
			case(BLOCK_SHAPE)
				`SHAPE_0:begin
					if(SQUARE_START_Y>(`SHAPE_0_Y1+`SHAPE_0_LENGTH1)
						&&(SQUARE_START_Y<(`SHAPE_0_Y2-SQUARE_SIZE)))begin
						IS_OVERLAPPING=0;
					end
					else begin
						IS_OVERLAPPING=1;
					end
				end
				`SHAPE_1:begin
					if(SQUARE_START_Y>(`SHAPE_1_LENGTH1+`SHAPE_1_Y1))begin
						IS_OVERLAPPING=0;
					end
					else begin
						IS_OVERLAPPING=1;
					end
				end
				`SHAPE_2:begin
					if((SQUARE_START_Y+SQUARE_SIZE)<`SHAPE_2_Y1)begin
						IS_OVERLAPPING=0;
					end
					else begin
						IS_OVERLAPPING=1;
					end
				end
				`SHAPE_3:begin
					if(SQUARE_START_Y>`SHAPE_3_Y1&&(SQUARE_START_Y+SQUARE_SIZE)<`SHAPE_3_Y1+`SHAPE_3_LENGTH1)begin
						IS_OVERLAPPING=1;
					end
					else begin
						IS_OVERLAPPING=0;
					end
				end
				`SHAPE_4:begin
					if(SQUARE_START_Y>`SHAPE_4_Y1&&(SQUARE_START_Y+SQUARE_SIZE)<`SHAPE_4_Y1+`SHAPE_4_LENGTH1)begin
						IS_OVERLAPPING=1;
					end
					else begin
						IS_OVERLAPPING=0;
					end
				end
				`SHAPE_5:begin
					if(SQUARE_START_Y>`SHAPE_5_Y1&&(SQUARE_START_Y+SQUARE_SIZE)<`SHAPE_5_Y1+`SHAPE_5_LENGTH1)begin
						IS_OVERLAPPING=1;
					end
					else begin
						IS_OVERLAPPING=0;
					end
				end
				`SHAPE_6:begin
					if(SQUARE_START_Y>(`SHAPE_6_Y1+`SHAPE_6_LENGTH1)
						&&(SQUARE_START_Y<(`SHAPE_6_Y2-SQUARE_SIZE)))begin
						IS_OVERLAPPING=0;
					end
					else begin
						IS_OVERLAPPING=1;
					end
				end
				`SHAPE_7:begin
					if(SQUARE_START_Y>(`SHAPE_7_Y1+`SHAPE_7_LENGTH1)
						&&(SQUARE_START_Y<(`SHAPE_7_Y2-SQUARE_SIZE)))begin
						IS_OVERLAPPING=0;
					end
					else begin
						IS_OVERLAPPING=1;
					end
				end
				`SHAPE_8:begin
					if((SQUARE_START_Y>`SHAPE_8_Y1
						&&(SQUARE_START_Y+SQUARE_SIZE)<(`SHAPE_8_Y1+`SHAPE_8_LENGTH1))
						||((SQUARE_START_Y+SQUARE_SIZE)>`SHAPE_8_Y2))begin
						IS_OVERLAPPING=1;
					end
					else begin
						IS_OVERLAPPING=0;
					end
				end
				`SHAPE_9:begin
					if((SQUARE_START_Y>`SHAPE_9_Y2
						&&(SQUARE_START_Y+SQUARE_SIZE)<(`SHAPE_9_Y2+`SHAPE_9_LENGTH2))
						||(SQUARE_START_Y<(`SHAPE_8_Y1+`SHAPE_8_LENGTH1)))begin
						IS_OVERLAPPING=1;
					end
					else begin
						IS_OVERLAPPING=0;
					end
				end
				`SHAPE_10:begin
					if((SQUARE_START_Y>(`SHAPE_10_Y1+`SHAPE_10_LENGTH1)
						&&(SQUARE_START_Y+SQUARE_SIZE)<`SHAPE_10_Y2)
						||(SQUARE_START_Y>(`SHAPE_10_Y2+`SHAPE_10_LENGTH2)
							&&(SQUARE_START_Y+SQUARE_SIZE)<`SHAPE_10_Y3))begin
						IS_OVERLAPPING=0;			
					end
					else begin
						IS_OVERLAPPING=1;
					end
				end
				default:begin
					IS_OVERLAPPING=0;
				end
			endcase
		end
	end
endmodule