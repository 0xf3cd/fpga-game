module MP3_SD_Communicator(CLK,START,RESET,SD_HAS_INITIALIZED,SD_IS_READING,NEED_NEW_DATA,SD_TO_READ,SD_READ_ADDRESS,READ_FIRST_PART_FINISH,IS_REQUESTING_NEW_DATA);
	input CLK;
	input START;
	input RESET;
	input SD_HAS_INITIALIZED;
	input SD_IS_READING;
	//input [4095:0]SD_READ_DATA;
	input NEED_NEW_DATA;
	output reg SD_TO_READ=0;
	output reg [31:0]SD_READ_ADDRESS=`MP3_INITIAL_READ_ADDRESS;
	//output [4095:0]DATA_TO_SEND;
	output reg READ_FIRST_PART_FINISH=0;
	output reg IS_REQUESTING_NEW_DATA=0;

	//assign DATA_TO_SEND=SD_READ_DATA[4095:0];

	reg rise_has_come=0;
	reg down_has_come=0;
	reg rise_down_reset=0;
	
	always @(posedge rise_down_reset or posedge SD_IS_READING)begin
		if(rise_down_reset)begin
			rise_has_come<=0;
		end
		else begin
			rise_has_come<=1;
		end
	end

	always @(posedge rise_down_reset or negedge SD_IS_READING)begin
		if(rise_down_reset)begin
			down_has_come<=0;
		end
		else begin
			down_has_come<=1;
		end
	end

	parameter WAIT_TO_START=3'b000;
	parameter FIRST_READ=3'b001;
	parameter FIRST_READ_WAIT=3'b011;
	parameter FIRST_READ_FINISH=3'b010;
	parameter WAIT_READ_REQUEST=3'b110;
	parameter NEXT_READ=3'b111;
	parameter NEXT_READ_WAIT=3'b101;
	parameter NEXT_READ_FINISH=3'b100;

	reg [2:0]current_state=WAIT_TO_START;
	reg [2:0]next_state;

	always @(posedge CLK)begin
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
				if(START&SD_HAS_INITIALIZED&(~SD_IS_READING))begin
					next_state=FIRST_READ;
				end
				else begin
					next_state=WAIT_TO_START;
				end
			end
			FIRST_READ:begin
				if(rise_has_come)begin
					next_state=FIRST_READ_WAIT;
				end
				else begin
					next_state=FIRST_READ;
				end
			end
			FIRST_READ_WAIT:begin
				if(down_has_come)begin//读取完毕
					next_state=FIRST_READ_FINISH;
				end
				else begin
					next_state=FIRST_READ_WAIT;
				end
			end
			FIRST_READ_FINISH:begin
				next_state=WAIT_READ_REQUEST;
			end
			WAIT_READ_REQUEST:begin
				if(NEED_NEW_DATA&(~SD_IS_READING))begin//有新的数据请求 并且此时SD卡不在读的状态，则开始读
					next_state=NEXT_READ;
				end
				else begin
					next_state=WAIT_READ_REQUEST;
				end
			end
			NEXT_READ:begin
				if(rise_has_come)begin
					next_state=NEXT_READ_WAIT;
				end
				else begin
					next_state=NEXT_READ;
				end
			end
			NEXT_READ_WAIT:begin
				if(down_has_come)begin//读取完毕
					next_state=NEXT_READ_FINISH;
				end
				else begin
					next_state=NEXT_READ_WAIT;
				end
			end
			NEXT_READ_FINISH:begin
				next_state=WAIT_READ_REQUEST;
			end
			default:begin
				next_state=WAIT_TO_START;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				SD_TO_READ<=0;
				SD_READ_ADDRESS<=`MP3_INITIAL_READ_ADDRESS;
			end
			FIRST_READ:begin
				SD_TO_READ<=1;
				SD_READ_ADDRESS<=SD_READ_ADDRESS;
			end
			FIRST_READ_WAIT:begin
				SD_TO_READ<=1;
				SD_READ_ADDRESS<=SD_READ_ADDRESS;
			end
			FIRST_READ_FINISH:begin
				SD_TO_READ<=0;
				SD_READ_ADDRESS<=SD_READ_ADDRESS+1;
			end
			WAIT_READ_REQUEST:begin
				SD_TO_READ<=0;
				SD_READ_ADDRESS<=SD_READ_ADDRESS;
			end
			NEXT_READ:begin
				SD_TO_READ<=1;
				SD_READ_ADDRESS<=SD_READ_ADDRESS;
			end
			NEXT_READ_WAIT:begin
				SD_TO_READ<=1;
				SD_READ_ADDRESS<=SD_READ_ADDRESS;
			end
			NEXT_READ_FINISH:begin
				SD_TO_READ<=0;
				SD_READ_ADDRESS<=SD_READ_ADDRESS+1;
			end
			default:begin
				SD_TO_READ<=0;
				SD_READ_ADDRESS<=SD_READ_ADDRESS;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				READ_FIRST_PART_FINISH<=0;
			end
			FIRST_READ:begin
				READ_FIRST_PART_FINISH<=0;
			end
			FIRST_READ_WAIT:begin
				READ_FIRST_PART_FINISH<=0;
			end
			FIRST_READ_FINISH:begin
				READ_FIRST_PART_FINISH<=1;
			end
			WAIT_READ_REQUEST:begin
				READ_FIRST_PART_FINISH<=1;
			end
			NEXT_READ:begin
				READ_FIRST_PART_FINISH<=1;
			end
			NEXT_READ_WAIT:begin
				READ_FIRST_PART_FINISH<=1;
			end
			NEXT_READ_FINISH:begin
				READ_FIRST_PART_FINISH<=1;
			end
			default:begin
				READ_FIRST_PART_FINISH<=0;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				IS_REQUESTING_NEW_DATA<=0;
			end
			FIRST_READ:begin
				IS_REQUESTING_NEW_DATA<=1;
			end
			FIRST_READ_WAIT:begin
				IS_REQUESTING_NEW_DATA<=1;
			end
			FIRST_READ_FINISH:begin
				IS_REQUESTING_NEW_DATA<=0;
			end
			WAIT_READ_REQUEST:begin
				IS_REQUESTING_NEW_DATA<=0;
			end
			NEXT_READ:begin
				IS_REQUESTING_NEW_DATA<=1;
			end
			NEXT_READ_WAIT:begin
				IS_REQUESTING_NEW_DATA<=1;
			end
			NEXT_READ_FINISH:begin
				IS_REQUESTING_NEW_DATA<=0;
			end
			default:begin
				IS_REQUESTING_NEW_DATA<=0;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_TO_START:begin
				rise_down_reset<=1;
			end
			FIRST_READ:begin
				rise_down_reset<=0;
			end
			FIRST_READ_WAIT:begin
				rise_down_reset<=0;
			end
			FIRST_READ_FINISH:begin
				rise_down_reset<=0;
			end
			WAIT_READ_REQUEST:begin
				rise_down_reset<=1;
			end
			NEXT_READ:begin
				rise_down_reset<=0;
			end
			NEXT_READ_WAIT:begin
				rise_down_reset<=0;
			end
			NEXT_READ_FINISH:begin
				rise_down_reset<=1;
			end
			default:begin
				rise_down_reset<=0;
			end
		endcase
	end
endmodule