`include "./Head.v"

module In_Square_Judge(X,Y,SQUARE_Y,SQUARE_SIZE,IN_SQUARE);
	input [`COORDINATE_LENGTH-1:0]X;
	input [`COORDINATE_LENGTH-1:0]Y;
	input [`COORDINATE_LENGTH-1:0]SQUARE_Y;
	input [`SQUARE_SIZE_LENGTH-1:0]SQUARE_SIZE;
	output reg IN_SQUARE;

	always @(X or Y or SQUARE_Y or SQUARE_SIZE)begin
		if(X>=`SQUARE_X&&X<(`SQUARE_X+SQUARE_SIZE))begin
			if(Y>=SQUARE_Y&&Y<(SQUARE_Y+SQUARE_SIZE))begin
				IN_SQUARE=1;
			end
			else begin
				IN_SQUARE=0;
			end
		end
		else begin
			IN_SQUARE=0;
		end
	end
endmodule