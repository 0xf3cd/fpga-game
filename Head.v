//声音部分
`define SOUND_COUNTER_WIDTH 7
`define LEVEL_BOUNDARY_0 7'd1
`define LEVEL_BOUNDARY_1 7'd2
`define LEVEL_BOUNDARY_2 7'd3
`define LEVEL_BOUNDARY_3 7'd4
`define LEVEL_BOUNDARY_4 7'd5

`define SOUND_LEVEL_ENCODE_LENGTH 3
`define NO_SOUND 3'b000
`define LEVEL_1 3'b001
`define LEVEL_2 3'b010
`define LEVEL_3 3'b011
`define LEVEL_4 3'b100
`define LEVEL_5 3'b101



/**********************************************/



//VGA显示部分
`define RGB_LENGTH 12
`define WHITE_RGB 12'b1111_1111_1111
`define BLACK_RGB 12'b0000_0000_0000
`define PINK_RGB 12'b1111_1001_1000
`define YELLOW_RGB 12'b1111_1111_0100
`define ORANGE_RGB 12'b1110_0110_0010
`define CYAN_RGB 12'b0001_1010_0101
`define RED_RGB 12'b1110_0001_0000
`define BLUE_RGB 12'b0000_0011_0100
`define VIOLET_RGB 12'b1010_0110_1010
`define ROSE_RGB 12'b1110_0011_0010
`define DARK_GREY_RGB 12'b0010_0010_0010
`define LIGHT_GREY_RGB 12'b1000_1000_1000
`define NEAR_WHITE_RGB 12'b1010_1010_1010


`define COLOR_ENCODE_LENGTH 3
`define PINK 3'b000
`define YELLOW 3'b001
`define ORANGE 3'b010
`define CYAN 3'b011
`define RED 3'b100
`define BLUE 3'b101
`define VIOLET 3'b110
`define ROSE 3'b111


`define SQUARE_STATE_ENCODE_LENGTH 2
`define SQUARE_STRONG 2'b00
`define SQUARE_OKAY 2'b01
`define SQUARE_WEAK 2'b11
`define SQUARE_INVINCIBLE 2'b10


`define SHAPE_ENCODE_LENGTH 4
`define SHAPE_0 4'b0000
`define SHAPE_1 4'b0001
`define SHAPE_2 4'b0010
`define SHAPE_3 4'b0011
`define SHAPE_4 4'b0100
`define SHAPE_5 4'b0101
`define SHAPE_6 4'b0110
`define SHAPE_7 4'b0111
`define SHAPE_8 4'b1000
`define SHAPE_9 4'b1001
`define SHAPE_10 4'b1010

//约定左上角第一个点坐标为(0,0)
//实际显示的时候，H_counter-143 V_counter-32 为x,y坐标
`define SQUARE_X 10'd203
`define INITIAL_BLOCK_1_X 10'd343
`define INITIAL_BLOCK_2_X 10'd503
`define INITIAL_BLOCK_3_X 10'd663
`define INITIAL_BLOCK_4_X 10'd823
`define BLOCK_WIDTH 10'd40
`define BLOCK_GAP 10'd80
`define BLOCK_DISAPPEAR_X 10'd103

`define SHAPE_0_Y1 10'd32//0
`define SHAPE_0_LENGTH1 10'd140 
`define SHAPE_0_Y2 10'd372//320
`define SHAPE_0_LENGTH2 10'd140

`define SHAPE_1_Y1 10'd32//0
`define SHAPE_1_LENGTH1 10'd240

`define SHAPE_2_Y1 10'd272//120
`define SHAPE_2_LENGTH1 10'd240

`define SHAPE_3_Y1 10'd192//140
`define SHAPE_3_LENGTH1 10'd160

`define SHAPE_4_Y1 10'd112//80
`define SHAPE_4_LENGTH1 10'd120

`define SHAPE_5_Y1 10'd312//280
`define SHAPE_5_LENGTH1 10'd120

`define SHAPE_6_Y1 10'd32//0
`define SHAPE_6_LENGTH1 10'd80
`define SHAPE_6_Y2 10'd262//180
`define SHAPE_6_LENGTH2 10'd250

`define SHAPE_7_Y1 10'd32//0
`define SHAPE_7_LENGTH1 10'd250
`define SHAPE_7_Y2 10'd432//400
`define SHAPE_7_LENGTH2 10'd80

`define SHAPE_8_Y1 10'd112//80
`define SHAPE_8_LENGTH1 10'd120
`define SHAPE_8_Y2 10'd392//360
`define SHAPE_8_LENGTH2 10'd120

`define SHAPE_9_Y1 10'd32//0
`define SHAPE_9_LENGTH1 10'd70
`define SHAPE_9_Y2 10'd222//140
`define SHAPE_9_LENGTH2 10'd200

`define SHAPE_10_Y1 10'd32//0
`define SHAPE_10_LENGTH1 10'd60
`define SHAPE_10_Y2 10'd212//180
`define SHAPE_10_LENGTH2 10'd120
`define SHAPE_10_Y3 10'd452//380
`define SHAPE_10_LENGTH3 10'd60


`define COORDINATE_LENGTH 10
`define SQUARE_SIZE_LENGTH 10
`define SQUARE_DEFAULT_SIZE 12



/**********************************************/



//分数记录部分
`define SCORES_WRITE_LENGTH 16



/**********************************************/



//SD读写地址部分
`define MP3_INITIAL_READ_ADDRESS 32'b0
`define SCORES_READ_ADDRESS 32'd500000
`define SCORES_WRITE_ADDRESS 32'd500000