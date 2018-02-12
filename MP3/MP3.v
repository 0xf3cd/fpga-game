`include "./MP3/MP3_SD_Communicator.v"
`include "./MP3/MP3_Send_Controller.v"

module MP3(CLK,MP3_SO,MP3_DREQ,SD_HAS_INITIALIZED,SD_IS_READING,START,RESET,SD_READ_DATA,
		MP3_SCLK,MP3_RESET_n,MP3_DCS,MP3_CS,MP3_SI,SD_TO_READ,SD_READ_ADDRESS);
	input CLK;//100MHz
	input MP3_SO;
	input MP3_DREQ;
	input SD_HAS_INITIALIZED;
	input SD_IS_READING;
	input START;
	input RESET;
	input [4095:0]SD_READ_DATA;
	output MP3_SCLK;
	output reg MP3_RESET_n=0;
	output MP3_DCS;
	output MP3_CS;
	output MP3_SI;
	output SD_TO_READ;
	output [31:0]SD_READ_ADDRESS;

	Divider #(10,100)get_1MHz(CLK,MP3_SCLK);

	assign MP3_CS=1;

	wire prepare_ok;
	wire is_requesting;
	wire need_new_data;
	reg work_start=0;
	reg communicator_reset=0;
	MP3_SD_Communicator communicator(.CLK(MP3_SCLK),
									 .START(work_start),
									 .RESET(communicator_reset),
									 .SD_HAS_INITIALIZED(SD_HAS_INITIALIZED),
									 .SD_IS_READING(SD_IS_READING),
									 .NEED_NEW_DATA(need_new_data),
									 .SD_TO_READ(SD_TO_READ),
									 .SD_READ_ADDRESS(SD_READ_ADDRESS),
									 .READ_FIRST_PART_FINISH(prepare_ok),
									 .IS_REQUESTING_NEW_DATA(is_requesting));


	MP3_Send_Controller send_controller(.CLK(MP3_SCLK),
										.DREQ(MP3_DREQ),
										.START(prepare_ok),
										.SD_IS_READING(is_requesting),
										.DATA(SD_READ_DATA),
										.SI(MP3_SI),
										.DCS(MP3_DCS),
										.NEED_NEW_DATA(need_new_data));

	parameter IDLE=1'b0;
	parameter WORKING=1'b1;

	reg current_state=IDLE;
	reg next_state;

	
	always @(posedge MP3_SCLK)begin
		if(RESET)begin
			current_state<=IDLE;
		end
		else begin
			current_state<=next_state;			
		end
	end

	always @(current_state or START)begin
		case(current_state)
			IDLE:begin
				if(START)begin
					next_state=WORKING;
				end
				else begin
					next_state=IDLE;
				end
			end
			WORKING:begin
				next_state=WORKING;
			end
		endcase
	end

	always @(posedge MP3_SCLK)begin
		case(next_state)
			IDLE:begin
				work_start<=0;
				communicator_reset<=1;
				MP3_RESET_n<=0;
			end
			WORKING:begin
				work_start<=1;
				communicator_reset<=0;
				MP3_RESET_n<=1;
			end
		endcase
	end
endmodule