`include "./MP3/MP3_Data_Allocator.v"
`include "./MP3/MP3_Sender.v"

module MP3_Send_Controller(CLK,DREQ,START,SD_IS_READING,DATA,SI,DCS,NEED_NEW_DATA);
	input CLK;
	input DREQ;
	input START;//外部是否准备完毕？（初次读取SD卡）
	input SD_IS_READING;
	input [4095:0]DATA;
	output SI;
	output DCS;
	output NEED_NEW_DATA;

	/*
	START有效时则开始工作（外部已准备完毕）
	如果需要新数据则NEEW_NEW_DATA置1
	*/


	wire sender_is_sending;
	wire [255:0]data_to_send;
	wire data_valid;

	MP3_Data_Allocator allocator(.CLK(CLK),
								 .START(START),
								 .SENDER_IS_SENDING(sender_is_sending),
								 .SD_IS_READING(SD_IS_READING),
								 .DATA_TO_ALLOCATE(DATA),
								 .DATA_TO_SEND(data_to_send),
								 .DATA_VALID(data_valid),
								 .NEED_NEW_DATA(NEED_NEW_DATA));

	MP3_Sender sender(.CLK(CLK),
	 				  .DATA(data_to_send),
	 				  .VALID(data_valid),
	 				  .DREQ(DREQ),
	 				  .SI(SI),
	 				  .DCS(DCS),
	 				  .IS_SENDING(sender_is_sending));
endmodule