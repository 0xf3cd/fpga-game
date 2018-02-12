module Allocator_16_1_256bits(IN,ADDRESS,OUT);
	input [4095:0]IN;
	input [3:0]ADDRESS;
	output reg [255:0]OUT;

	always @(IN or ADDRESS)begin
		case(ADDRESS)
			4'd0:begin
				OUT=IN[4095:3840];
			end
			4'd1:begin
				OUT=IN[3839:3584];
			end
			4'd2:begin
				OUT=IN[3583:3328];
			end
			4'd3:begin
				OUT=IN[3327:3072];
			end
			4'd4:begin
				OUT=IN[3071:2816];
			end
			4'd5:begin
				OUT=IN[2815:2560];
			end
			4'd6:begin
				OUT=IN[2559:2304];
			end
			4'd7:begin
				OUT=IN[2303:2048];
			end
			4'd8:begin
				OUT=IN[2047:1792];
			end
			4'd9:begin
				OUT=IN[1791:1536];
			end
			4'd10:begin
				OUT=IN[1535:1280];
			end
			4'd11:begin
				OUT=IN[1279:1024];
			end
			4'd12:begin
				OUT=IN[1023:768];
			end
			4'd13:begin
				OUT=IN[767:512];
			end
			4'd14:begin
				OUT=IN[511:256];
			end
			4'd15:begin
				OUT=IN[255:0];
			end
		endcase
	end
endmodule