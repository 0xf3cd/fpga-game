`include "./MP3/Allocator_16_1_256bits.v"

module MP3_Data_Allocator(CLK,START,SENDER_IS_SENDING,SD_IS_READING,DATA_TO_ALLOCATE,DATA_TO_SEND,DATA_VALID,NEED_NEW_DATA);
	input CLK;
	input START;
	input SENDER_IS_SENDING;
	input SD_IS_READING;
	input [4095:0]DATA_TO_ALLOCATE;
	output [255:0]DATA_TO_SEND;
	output reg DATA_VALID;
	output reg NEED_NEW_DATA;

	/*
	当START有效时，开始工作
	每次传输一片数据给SENDER让其发送给MP3
	发送完毕后则分配下一个数据
	*/
	
	reg [4:0]send_counter;
	
	Allocator_16_1_256bits allocator(DATA_TO_ALLOCATE,send_counter[3:0],DATA_TO_SEND);


	parameter WAIT_START=3'b000;
	parameter ALLOCATE=3'b001;
	parameter WAIT_SENDING=3'b011;
	parameter WAIT_SEND_FINISH=3'b010;
	parameter ADJUST=3'b110;
	parameter REQUEST_NEW_DATA=3'b111;
	parameter WAIT_SD_READING=3'b101;
	parameter WAIT_READ_FINISH=3'b100;

	reg [2:0]current_state=WAIT_START;
	reg [2:0]next_state;

	always @(posedge CLK)begin
		current_state<=next_state;
	end

	always @(*)begin
		case(current_state)
			WAIT_START:begin
				if(START)begin
					next_state=ALLOCATE;
				end	
				else begin
					next_state=WAIT_START;
				end
			end
			ALLOCATE:begin
				next_state=WAIT_SENDING;
			end
			WAIT_SENDING:begin
				if(SENDER_IS_SENDING)begin
					next_state=WAIT_SEND_FINISH;
				end
				else begin
					next_state=WAIT_SENDING;
				end
			end
			WAIT_SEND_FINISH:begin
				if(SENDER_IS_SENDING)begin
					next_state=WAIT_SEND_FINISH;
				end
				else begin
					next_state=ADJUST;
				end
			end
			ADJUST:begin
				if(send_counter==5'b10000)begin
					next_state=REQUEST_NEW_DATA;
				end
				else begin
					next_state=ALLOCATE;
				end
			end
			REQUEST_NEW_DATA:begin
				next_state=WAIT_SD_READING;
			end
			WAIT_SD_READING:begin
				if(SD_IS_READING)begin
					next_state=WAIT_READ_FINISH;
				end
				else begin
					next_state=WAIT_SD_READING;
				end
			end
			WAIT_READ_FINISH:begin
				if(!SD_IS_READING)begin
					next_state=ALLOCATE;
				end
				else begin
					next_state=WAIT_READ_FINISH;
				end
			end
			default:begin
				next_state=WAIT_START;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_START:begin
				send_counter<=0;
			end
			ALLOCATE:begin
				send_counter<=send_counter;
			end
			WAIT_SENDING:begin
				send_counter<=send_counter;
			end
			WAIT_SEND_FINISH:begin
				send_counter<=send_counter;
			end
			ADJUST:begin
				send_counter<=send_counter+1;
			end
			REQUEST_NEW_DATA:begin
				send_counter<=0;
			end
			WAIT_SD_READING:begin
				send_counter<=0;
			end
			WAIT_READ_FINISH:begin
				send_counter<=0;
			end
			default:begin
				send_counter<=0;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT_START:begin
				DATA_VALID<=0;
			end
			ALLOCATE:begin
				DATA_VALID<=1;
			end
			WAIT_SENDING:begin
				DATA_VALID<=1;
			end
			WAIT_SEND_FINISH:begin
				DATA_VALID<=0;
			end
			ADJUST:begin
				DATA_VALID<=0;
			end
			REQUEST_NEW_DATA:begin
				DATA_VALID<=0;
			end
			WAIT_SD_READING:begin
				DATA_VALID<=0;
			end
			WAIT_READ_FINISH:begin
				DATA_VALID<=0;
			end
			default:begin
				DATA_VALID<=0;
			end
		endcase
	end
	
	always @(posedge CLK)begin
		case(next_state)
			WAIT_START:begin
				NEED_NEW_DATA<=0;
			end
			ALLOCATE:begin
				NEED_NEW_DATA<=0;
			end
			WAIT_SENDING:begin
				NEED_NEW_DATA<=0;
			end
			WAIT_SEND_FINISH:begin
				NEED_NEW_DATA<=0;
			end
			ADJUST:begin
				NEED_NEW_DATA<=0;
			end
			REQUEST_NEW_DATA:begin
				NEED_NEW_DATA<=1;
			end
			WAIT_SD_READING:begin
				NEED_NEW_DATA<=1;
			end
			WAIT_READ_FINISH:begin
				NEED_NEW_DATA<=0;
			end
			default:begin
				NEED_NEW_DATA<=0;
			end
		endcase
	end
endmodule