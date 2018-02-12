`include "./Head.v"
`include "./Game_Rules/Overlapping_Each_Block_Judge.v"

module Overlapping_Judge(BLOCK_SHAPE,BLOCK_START_X,SQUARE_START_Y,SQUARE_SIZE,IS_OVERLAPPING);
	input [4*`SHAPE_ENCODE_LENGTH-1:0]BLOCK_SHAPE;
	input [4*`COORDINATE_LENGTH-1:0]BLOCK_START_X;
	input [`COORDINATE_LENGTH-1:0]SQUARE_START_Y;
	input [`SQUARE_SIZE_LENGTH-1:0]SQUARE_SIZE;
	output IS_OVERLAPPING;

	wire is_overlappint_1;
	wire is_overlappint_2;
	wire is_overlappint_3;
	wire is_overlappint_4;

	Overlapping_Each_Block_Judge judge_block_1(.BLOCK_SHAPE(BLOCK_SHAPE[4*`SHAPE_ENCODE_LENGTH-1:3*`SHAPE_ENCODE_LENGTH]),
											   .BLOCK_START_X(BLOCK_START_X[4*`COORDINATE_LENGTH-1:3*`COORDINATE_LENGTH]),
											   .SQUARE_START_Y(SQUARE_START_Y),
											   .SQUARE_SIZE(SQUARE_SIZE),
											   .IS_OVERLAPPING(is_overlappint_1));

	Overlapping_Each_Block_Judge judge_block_2(.BLOCK_SHAPE(BLOCK_SHAPE[3*`SHAPE_ENCODE_LENGTH-1:2*`SHAPE_ENCODE_LENGTH]),
											   .BLOCK_START_X(BLOCK_START_X[3*`COORDINATE_LENGTH-1:2*`COORDINATE_LENGTH]),
											   .SQUARE_START_Y(SQUARE_START_Y),
											   .SQUARE_SIZE(SQUARE_SIZE),
											   .IS_OVERLAPPING(is_overlappint_2));

	Overlapping_Each_Block_Judge judge_block_3(.BLOCK_SHAPE(BLOCK_SHAPE[2*`SHAPE_ENCODE_LENGTH-1:`SHAPE_ENCODE_LENGTH]),
											   .BLOCK_START_X(BLOCK_START_X[2*`COORDINATE_LENGTH-1:`COORDINATE_LENGTH]),
											   .SQUARE_START_Y(SQUARE_START_Y),
											   .SQUARE_SIZE(SQUARE_SIZE),
											   .IS_OVERLAPPING(is_overlappint_3));

	Overlapping_Each_Block_Judge judge_block_4(.BLOCK_SHAPE(BLOCK_SHAPE[`SHAPE_ENCODE_LENGTH-1:0]),
											   .BLOCK_START_X(BLOCK_START_X[`COORDINATE_LENGTH-1:0]),
											   .SQUARE_START_Y(SQUARE_START_Y),
											   .SQUARE_SIZE(SQUARE_SIZE),
											   .IS_OVERLAPPING(is_overlappint_4));

	assign IS_OVERLAPPING=is_overlappint_1|is_overlappint_2|is_overlappint_3|is_overlappint_4;
endmodule