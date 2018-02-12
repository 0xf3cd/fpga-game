`include "./Head.v"

module In_Block_Judge(X,Y,BLOCK_X,BLOCK_SHAPE,IN_BLOCK);
	input [`COORDINATE_LENGTH-1:0]X;
	input [`COORDINATE_LENGTH-1:0]Y;//当前扫描位置的坐标
	input [`COORDINATE_LENGTH-1:0]BLOCK_X;//需要显示的区块的左上角点坐标
	input [`SHAPE_ENCODE_LENGTH-1:0]BLOCK_SHAPE;//需要显示的区块的形状编码
	output reg IN_BLOCK;

	/*
	模块功能为：
	判断当前输入的X,Y坐标（正在扫描的点的坐标）是否处于某各应显示障碍的区域内
	*/

	always @(X or Y or BLOCK_X or BLOCK_SHAPE)begin//组合逻辑块
		if((X>=BLOCK_X)&&(X<(BLOCK_X+`BLOCK_WIDTH)))begin
			case(BLOCK_SHAPE)
				`SHAPE_0:begin
					if((Y>=`SHAPE_0_Y1)&&(Y<(`SHAPE_0_Y1+`SHAPE_0_LENGTH1)))begin
						IN_BLOCK=1;
					end
					else if((Y>=`SHAPE_0_Y2)&&(Y<(`SHAPE_0_Y2+`SHAPE_0_LENGTH2)))begin
						IN_BLOCK=1;
					end
					else begin
						IN_BLOCK=0;
					end
				end
				`SHAPE_1:begin
					if((Y>=`SHAPE_1_Y1)&&(Y<(`SHAPE_1_Y1+`SHAPE_1_LENGTH1)))begin
						IN_BLOCK=1;
					end
					else begin
						IN_BLOCK=0;
					end
				end
				`SHAPE_2:begin
					if((Y>=`SHAPE_2_Y1)&&(Y<(`SHAPE_2_Y1+`SHAPE_2_LENGTH1)))begin
						IN_BLOCK=1;
					end
					else begin
						IN_BLOCK=0;
					end
				end
				`SHAPE_3:begin
					if((Y>=`SHAPE_3_Y1)&&(Y<(`SHAPE_3_Y1+`SHAPE_3_LENGTH1)))begin
						IN_BLOCK=1;
					end
					else begin
						IN_BLOCK=0;
					end
				end
				`SHAPE_4:begin
					if((Y>=`SHAPE_4_Y1)&&(Y<(`SHAPE_4_Y1+`SHAPE_4_LENGTH1)))begin
						IN_BLOCK=1;
					end
					else begin
						IN_BLOCK=0;
					end
				end
				`SHAPE_5:begin
					if((Y>=`SHAPE_5_Y1)&&(Y<(`SHAPE_5_Y1+`SHAPE_5_LENGTH1)))begin
						IN_BLOCK=1;
					end
					else begin
						IN_BLOCK=0;
					end
				end
				`SHAPE_6:begin
					if((Y>=`SHAPE_6_Y1)&&(Y<(`SHAPE_6_Y1+`SHAPE_6_LENGTH1)))begin
						IN_BLOCK=1;
					end
					else if((Y>=`SHAPE_6_Y2)&&(Y<(`SHAPE_6_Y2+`SHAPE_6_LENGTH2)))begin
						IN_BLOCK=1;
					end
					else begin
						IN_BLOCK=0;
					end
				end
				`SHAPE_7:begin
					if((Y>=`SHAPE_7_Y1)&&(Y<(`SHAPE_7_Y1+`SHAPE_7_LENGTH1)))begin
						IN_BLOCK=1;
					end
					else if((Y>=`SHAPE_7_Y2)&&(Y<(`SHAPE_7_Y2+`SHAPE_7_LENGTH2)))begin
						IN_BLOCK=1;
					end
					else begin
						IN_BLOCK=0;
					end
				end
				`SHAPE_8:begin
					if((Y>=`SHAPE_8_Y1)&&(Y<(`SHAPE_8_Y1+`SHAPE_8_LENGTH1)))begin
						IN_BLOCK=1;
					end
					else if((Y>=`SHAPE_8_Y2)&&(Y<(`SHAPE_8_Y2+`SHAPE_8_LENGTH2)))begin
						IN_BLOCK=1;
					end
					else begin
						IN_BLOCK=0;
					end
				end
				`SHAPE_9:begin
					if((Y>=`SHAPE_9_Y1)&&(Y<(`SHAPE_9_Y1+`SHAPE_9_LENGTH1)))begin
						IN_BLOCK=1;
					end
					else if((Y>=`SHAPE_9_Y2)&&(Y<(`SHAPE_9_Y2+`SHAPE_9_LENGTH2)))begin
						IN_BLOCK=1;
					end
					else begin
						IN_BLOCK=0;
					end
				end
				`SHAPE_10:begin
					if((Y>=`SHAPE_10_Y1)&&(Y<(`SHAPE_10_Y1+`SHAPE_10_LENGTH1)))begin
						IN_BLOCK=1;
					end
					else if((Y>=`SHAPE_10_Y2)&&(Y<(`SHAPE_10_Y2+`SHAPE_10_LENGTH2)))begin
						IN_BLOCK=1;
					end
					else if((Y>=`SHAPE_10_Y3)&&(Y<(`SHAPE_10_Y3+`SHAPE_10_LENGTH3)))begin
						IN_BLOCK=1;
					end
					else begin
						IN_BLOCK=0;
					end
				end
				default:begin
					IN_BLOCK=0;
				end
			endcase
		end	
		else begin
			IN_BLOCK=0;
		end
	end
endmodule