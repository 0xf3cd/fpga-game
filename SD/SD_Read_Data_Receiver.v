`include "./Head.v"
`include "./Tools/Shift_Register_4096bits.v"

module SD_Read_Data_Receiver(CLK,DO,START,FINISH,READ_DATA);
	input CLK;
	input DO;
	input START;
	output reg FINISH=0;
	output [4095:0]READ_DATA;

	/*
	当START有效时，Receiver将在接收到令牌后开始接收数据
	4096位接收完毕后将FINISH置为1
	*/

	reg counter_enable=0;
	reg counter_reset=0;
	wire [12:0]counter_result;
	Counter #(.WIDTH(13))counter(~CLK,counter_enable,counter_reset,counter_result);//下降沿计数

	reg saver_enable=0;
	Shift_Register_4096bits saver(~CLK,DO,saver_enable,READ_DATA);

	reg DO_negedge_has_come=0;
	always @(posedge START or negedge DO)begin
		if(~DO)begin//DO下降沿到来
			DO_negedge_has_come<=1;
		end
		else begin
			if(START)begin
				DO_negedge_has_come<=0;
			end
			else begin
				DO_negedge_has_come<=DO_negedge_has_come;
			end
		end
	end

	//状态机描述
	parameter WAIT=2'b00;
	parameter SAVING=2'b01;
	parameter RECEIVE_CRC=2'b11;
	parameter SAVE_FINISH=2'b10;

	reg [1:0]current_state=WAIT;
	reg [1:0]next_state;

	always @(posedge CLK)begin
		current_state<=next_state;
	end

	always @(current_state or START or counter_result or DO_negedge_has_come or counter_result)begin
		case(current_state)
			WAIT:begin
				if(DO_negedge_has_come&START)begin
					next_state=SAVING;
				end
				else begin
					next_state=WAIT;
				end
			end
			SAVING:begin
				if(counter_result==13'd4096)begin
					next_state=RECEIVE_CRC;
				end
				else begin
					next_state=SAVING;
				end
			end
			RECEIVE_CRC:begin
				if(counter_result==13'd4104)begin
					next_state=SAVE_FINISH;
				end
				else begin
					next_state=RECEIVE_CRC;
				end
			end
			SAVE_FINISH:begin
				next_state=WAIT;
			end
			default:begin
				next_state=WAIT;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT:begin
				counter_enable<=0;
				counter_reset<=1;
			end
			SAVING:begin
				counter_enable<=1;
				counter_reset<=0;
			end
			RECEIVE_CRC:begin
				counter_enable<=1;
				counter_reset<=0;
			end
			SAVE_FINISH:begin
				counter_enable<=0;
				counter_reset<=1;
			end
			default:begin
				counter_enable<=0;
				counter_reset<=1;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT:begin
				saver_enable<=0;
			end
			SAVING:begin
				saver_enable<=1;
			end
			RECEIVE_CRC:begin
				saver_enable<=0;
			end
			SAVE_FINISH:begin
				saver_enable<=0;
			end
			default:begin
				saver_enable<=0;
			end
		endcase
	end

	always @(posedge CLK)begin
		case(next_state)
			WAIT:begin
				FINISH<=0;
			end
			SAVING:begin
				FINISH<=0;
			end
			RECEIVE_CRC:begin
				FINISH<=0;
			end
			SAVE_FINISH:begin
				FINISH<=1;
			end
			default:begin
				FINISH<=0;
			end
		endcase
	end
endmodule
