`include "./Head.v"
`include "./VGA/VGA_Output/In_Block_Judge.v"
`include "./VGA/VGA_Output/In_Square_Judge.v"

module Position_Judge(BLOCK_SHAPE,BLOCK_START_X,SQUARE_START_Y,SQUARE_SIZE,X,Y,IN_BLOCK_1,IN_BLOCK_2,IN_BLOCK_3,IN_BLOCK_4,IN_SQUARE,IS_EMPTY);
	input [4*`SHAPE_ENCODE_LENGTH-1:0]BLOCK_SHAPE;
	input [4*`COORDINATE_LENGTH-1:0]BLOCK_START_X;
	input [`COORDINATE_LENGTH-1:0]SQUARE_START_Y;
	input [`SQUARE_SIZE_LENGTH-1:0]SQUARE_SIZE;
	input [`COORDINATE_LENGTH-1:0]X;
	input [`COORDINATE_LENGTH-1:0]Y;
	output IN_BLOCK_1;
	output IN_BLOCK_2;
	output IN_BLOCK_3;
	output IN_BLOCK_4;
	output IN_SQUARE;
	output IS_EMPTY;

	/*
	该模块的输入为当前扫描点坐标以及要显示的图像区域
	输出的是当前扫描点所处的区域位置
	如果当前扫描点刚好在BLOCK_1要显示的区域，则IN_BLOCK_1为1
	......
	*/

	wire [`SHAPE_ENCODE_LENGTH-1:0]block_1_shape;
	wire [`SHAPE_ENCODE_LENGTH-1:0]block_2_shape;
	wire [`SHAPE_ENCODE_LENGTH-1:0]block_3_shape;
	wire [`SHAPE_ENCODE_LENGTH-1:0]block_4_shape;
	assign {block_1_shape,block_2_shape,block_3_shape,block_4_shape}=BLOCK_SHAPE[4*`SHAPE_ENCODE_LENGTH-1:0];

	wire [`COORDINATE_LENGTH-1:0]block_1_x;
	wire [`COORDINATE_LENGTH-1:0]block_2_x;
	wire [`COORDINATE_LENGTH-1:0]block_3_x;
	wire [`COORDINATE_LENGTH-1:0]block_4_x;
	assign {block_1_x,block_2_x,block_3_x,block_4_x}=BLOCK_START_X[4*`COORDINATE_LENGTH-1:0];

	In_Block_Judge block_1_judge(.X(X),
								 .Y(Y),
								 .BLOCK_X(block_1_x),
								 .BLOCK_SHAPE(block_1_shape),
								 .IN_BLOCK(IN_BLOCK_1));
	In_Block_Judge block_2_judge(.X(X),
								 .Y(Y),
								 .BLOCK_X(block_2_x),
								 .BLOCK_SHAPE(block_2_shape),
								 .IN_BLOCK(IN_BLOCK_2));
	In_Block_Judge block_3_judge(.X(X),
								 .Y(Y),
								 .BLOCK_X(block_3_x),
								 .BLOCK_SHAPE(block_3_shape),
								 .IN_BLOCK(IN_BLOCK_3));
	In_Block_Judge block_4_judge(.X(X),
								 .Y(Y),
								 .BLOCK_X(block_4_x),
								 .BLOCK_SHAPE(block_4_shape),
								 .IN_BLOCK(IN_BLOCK_4));

	In_Square_Judge square_judge(.X(X),
								 .Y(Y),
								 .SQUARE_Y(SQUARE_START_Y),
								 .SQUARE_SIZE(SQUARE_SIZE),
								 .IN_SQUARE(IN_SQUARE));

	assign IS_EMPTY=(~IN_BLOCK_1)&(~IN_BLOCK_2)&(~IN_BLOCK_3)&(~IN_BLOCK_4)&(~IN_SQUARE);//不在障碍区也不在方块所在区域时，则为空
endmodule