`include "./Tools/Shift_Register_256bits.v"

module MP3_Sender(CLK,DATA,VALID,DREQ,SI,DCS,IS_SENDING);
	input CLK;//1MHz
	input [255:0]DATA;
	input VALID;
	input DREQ;
	output SI;
	output reg DCS=1;
	output reg IS_SENDING=0;

	/*
	当DREQ和VALID都为有效时将发送数据
	开始发送数据后，输入的数据可以更改。
	*/


	reg sender_enable=0;
	reg sender_reset=0;
	Shift_Register_256bits sender(~CLK,sender_enable,sender_reset,DATA,1'b1,SI);

	reg sender_enable_reset=0;
	reg sender_start=0;
	always @(posedge CLK or posedge sender_enable_reset)begin
		if(sender_enable_reset)begin
			sender_enable<=0;
		end
		else if(sender_start&(~sender_enable))begin
			sender_enable<=1;
		end
		else begin
			sender_enable<=sender_enable;
		end
	end

	reg counter_enable=0;
	reg counter_reset=0;
	wire [8:0]counter_result;
	wire send_finish;
	Counter #(.WIDTH(9)) counter(CLK,counter_enable,counter_reset,counter_result);
	assign send_finish=(counter_result==9'd256);

	parameter WAIT=2'b00;
	parameter RESET=2'b01;
	parameter SEND=2'b11;
	parameter FINISH=2'b10;

	reg [1:0]current_state=WAIT;
	reg [1:0]next_state;

	always @(negedge CLK)begin
		current_state<=next_state;
	end

	always @(current_state or DREQ or VALID or send_finish)begin
		case(current_state)
			WAIT:begin
				if(DREQ&VALID)begin
					next_state=RESET;
				end
				else begin
					next_state=WAIT;
				end
			end
			RESET:begin
				next_state=SEND;
			end
			SEND:begin
				if(send_finish)begin
					next_state=FINISH;
				end
				else begin
					next_state=SEND;
				end
			end
			FINISH:begin
				next_state=WAIT;
			end
			default:begin
				next_state=WAIT;
			end
		endcase
	end

	always @(negedge CLK)begin
		case(next_state)
			WAIT:begin
				DCS<=1;
			end
			RESET:begin
				DCS<=1;
			end
			SEND:begin
				DCS<=0;
			end
			FINISH:begin
				DCS<=1;
			end
			default:begin
				DCS<=1;
			end
		endcase
	end

	always @(negedge CLK)begin
		case(next_state)
			WAIT:begin
				IS_SENDING<=0;
			end
			RESET:begin
				IS_SENDING<=0;
			end
			SEND:begin
				IS_SENDING<=1;
			end
			FINISH:begin
				IS_SENDING<=0;
			end
			default:begin
				IS_SENDING<=0;
			end
		endcase
	end

	always @(negedge CLK)begin
		case(next_state)
			WAIT:begin
				counter_enable<=0;
				counter_reset<=1;
			end
			RESET:begin
				counter_enable<=0;
				counter_reset<=1;
			end
			SEND:begin
				counter_enable<=1;
				counter_reset<=0;
			end
			FINISH:begin
				counter_enable<=0;
				counter_reset<=1;
			end
			default:begin
				counter_enable<=0;
				counter_reset<=1;
			end
		endcase
	end

	always @(negedge CLK)begin
		case(next_state)
			WAIT:begin
				sender_enable_reset<=0;
				sender_reset<=1;
				sender_start<=0;
			end
			RESET:begin
				sender_enable_reset<=1;
				sender_reset<=1;
				sender_start<=0;
			end
			SEND:begin
				sender_enable_reset<=0;
				sender_reset<=0;
				sender_start<=1;
			end
			FINISH:begin
				sender_enable_reset<=1;
				sender_reset<=1;
				sender_start<=0;
			end
			default:begin
				sender_enable_reset<=0;
				sender_reset<=1;
				sender_start<=0;
			end
		endcase
	end
endmodule