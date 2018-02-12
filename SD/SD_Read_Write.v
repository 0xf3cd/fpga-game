`include "./Head.v"
`include "./SD/SD_Command_Sender.v"
`include "./SD/SD_Read_Response_Receiver.v"
`include "./SD/SD_Read_Data_Receiver.v"
`include "./SD/SD_Data_Writer.v"

module SD_Read_Write #(parameter DATA_TO_WRITE_LENGTH=16)(CLK,DO,INITIALIZE_OK,TO_WRITE,TO_READ,DATA_TO_WRITE,READ_ADDRESS,WRITE_ADDRESS,CS,DI,DATA,IS_READING,IS_WRITING);
	input CLK;
	input DO;
	input INITIALIZE_OK;
	input TO_WRITE;
	input TO_READ;
	input [DATA_TO_WRITE_LENGTH-1:0]DATA_TO_WRITE;
	input [31:0]READ_ADDRESS;
	input [31:0]WRITE_ADDRESS;
	output reg CS;
	output DI;
	output [4095:0]DATA;
	output reg IS_READING=0;
	output reg IS_WRITING=0;

	/*
	*SD卡初始化后上层模块将INITIALIZE_OK置为1，之后才可以开始读写
	*写操作为的是写入游戏最高分，固定为16位
	*读操作一次读出4096位，在下一次读之前读出的值将保持
	*/

	/*
	*以下为读写SD卡需要使用的命令
	*CMD17 读SD卡一个扇区（512字节）的数据
	*CMD24 写512字节入SD卡的一个扇区
	*/
	parameter CMD17_HEAD=8'b0101_0001;
	//CMD17的ARGUMENT（参数）为扇区编号
	parameter CMD17_CRC=8'b1111_1111;//此时循环冗余检查已经关闭，CRC位可随意填入
	parameter CMD24_HEAD=8'b0101_1000;
	//CMD24的ARGUMENT（参数）为扇区编号
	parameter CMD24_CRC=8'b1111_1111;//此时循环冗余检查已经关闭，CRC位可随意填入

	/*
	*当RESET有效时，RESET_VALUE的值将在时钟下降沿被打入命令发送队列
	*之后ENABLE有效则开始在时钟下降沿逐位发送数据
	*发送完毕后FINISH置为1
	*/
	reg command_sender_enable=0;
	reg command_sender_reset=0;
	reg [47:0]command_to_send;
	wire command_send_finish;
	wire DI_command_sender;
	SD_Command_Sender command_sender(.CLK(CLK),
									 .ENABLE(command_sender_enable),
									 .RESET(command_sender_reset),
									 .RESET_VALUE(command_to_send),
									 .OUT(DI_command_sender),
									 .FINISH(command_send_finish));

	/*
	当ACTIVATE有效时，将进行R1响应接收动作
	接收完毕后RECEIVED为1
	*/
	reg response_receiver_activate=0;
	wire response_receiver_received;
	SD_Read_Response_Receiver response_receiver(.CLK(CLK),
											  	.DO(DO),
											  	.ACTIVATE(response_receiver_activate),
											  	.RECEIVED(response_receiver_received));
	
	/*
	当START有效时，Receiver将在接收到令牌后开始接收数据
	4096位接收完毕后将FINISH置为1
	*/
	reg data_receiver_start=0;
	wire data_receiver_finish;
	SD_Read_Data_Receiver data_receiver(.CLK(CLK),
										.DO(DO),
										.START(data_receiver_start),
										.FINISH(data_receiver_finish),
										.READ_DATA(DATA[4095:0]));


	reg data_writer_start=0;
	reg data_writer_reset=0;
	wire data_writer_finish;
	wire DI_data_writer;
	SD_Data_Writer #(.DATA_TO_WRITE_LENGTH(DATA_TO_WRITE_LENGTH)) data_writer(.CLK(CLK),
																			  .DO(DO),
																			  .RESET(data_writer_reset),
																			  .DATA_TO_WRITE(DATA_TO_WRITE),
																			  .WRITE_START(data_writer_start),
																			  .DI(DI_data_writer),
																			  .WRITE_FINISH(data_writer_finish));


	parameter DI_using_by_command_sender=1'b0;
	parameter DI_using_by_data_writer=1'b1;
	reg DI_user=DI_using_by_command_sender;
	assign DI=(DI_user==DI_using_by_command_sender)?DI_command_sender:DI_data_writer;

	
	parameter WAIT_INITIALIZE_FINISH=4'b0000;
	parameter IDLE=4'b0001;
	parameter READ_CMD_LOAD=4'b0011;
	parameter READ_CMD_SEND=4'b0010;
	parameter READ_CMD_RESPONSE_WAIT=4'b0110;
	parameter READ_DATA=4'b0111;
	parameter READ_FINISH=4'b0101;
	//parameter WRITE=4'b0100;
	parameter WRITE_CMD_LOAD=4'b0100;
	parameter WRITE_CMD_SEND=4'b1100;
	parameter WRITE_CMD_RESPONSE_WAIT=4'b1101;
	parameter WRITE_DATA_SEND=4'b1111;
	parameter WRITE_FINISH=4'b1110;

	reg [3:0]current_state=IDLE;
	reg [3:0]next_state;

	always @(posedge CLK)begin
		current_state<=next_state;
	end

	always @(*)begin
		case(current_state)
			WAIT_INITIALIZE_FINISH:begin
				if(INITIALIZE_OK)begin
					next_state=IDLE;
				end
				else begin
					next_state=WAIT_INITIALIZE_FINISH;
				end
			end
			IDLE:begin
				if(TO_READ)begin
					next_state=READ_CMD_LOAD;
				end
				else if(TO_WRITE)begin
					next_state=WRITE_CMD_LOAD;
				end
				else begin
					next_state=IDLE;
				end
			end
			READ_CMD_LOAD:begin
				next_state=READ_CMD_SEND;
			end
			READ_CMD_SEND:begin
				if(command_send_finish)begin
					next_state=READ_CMD_RESPONSE_WAIT;
				end
				else begin
					next_state=READ_CMD_SEND;
				end
			end
			READ_CMD_RESPONSE_WAIT:begin
				if(response_receiver_received)begin
					next_state=READ_DATA;
				end
				else begin
					next_state=READ_CMD_RESPONSE_WAIT;
				end
			end
			READ_DATA:begin
			 	if(data_receiver_finish)begin
			 		next_state=READ_FINISH;
			 	end
			 	else begin
			 		next_state=READ_DATA;
			 	end
			end
			READ_FINISH:begin
				next_state=IDLE;
			end
			WRITE_CMD_LOAD:begin
				next_state=WRITE_CMD_SEND;
			end
			WRITE_CMD_SEND:begin
				if(command_send_finish)begin
					next_state=WRITE_CMD_RESPONSE_WAIT;
				end
				else begin
					next_state=WRITE_CMD_SEND;
				end
			end
			WRITE_CMD_RESPONSE_WAIT:begin
				if(response_receiver_received)begin
					next_state=WRITE_DATA_SEND;
				end
				else begin
					next_state=WRITE_CMD_RESPONSE_WAIT;
				end
			end
			WRITE_DATA_SEND:begin
				if(data_writer_finish)begin
					next_state=WRITE_FINISH;
				end
				else begin
					next_state=WRITE_DATA_SEND;
				end
			end
			WRITE_FINISH:begin
				next_state=IDLE;
			end
			default:begin
				next_state=IDLE;
			end
		endcase
	end

	//片选信号以及读写状态信号控制
	always @(posedge CLK)begin
		case(next_state)
			WAIT_INITIALIZE_FINISH:begin
				CS<=1;
				IS_READING<=0;
				IS_WRITING<=0;
			end
			IDLE:begin
				CS<=1;
				IS_READING<=0;
				IS_WRITING<=0;
			end
			READ_CMD_LOAD:begin
				CS<=0;
				IS_READING<=1;
				IS_WRITING<=0;
			end
			READ_CMD_SEND:begin
				CS<=0;
				IS_READING<=1;
				IS_WRITING<=0;
			end
			READ_CMD_RESPONSE_WAIT:begin
				CS<=0;
				IS_READING<=1;
				IS_WRITING<=0;
			end
			READ_DATA:begin
			 	CS<=0;
			 	IS_READING<=1;
			 	IS_WRITING<=0;
			end
			READ_FINISH:begin
				CS<=1;
				IS_READING<=0;
				IS_WRITING<=0;
			end
			WRITE_CMD_LOAD:begin
				CS<=0;
				IS_READING<=0;
				IS_WRITING<=1;
			end
			WRITE_CMD_SEND:begin
				CS<=0;
				IS_READING<=0;
				IS_WRITING<=1;
			end
			WRITE_CMD_RESPONSE_WAIT:begin
				CS<=0;
				IS_READING<=0;
				IS_WRITING<=1;
			end
			WRITE_DATA_SEND:begin
				CS<=0;
				IS_READING<=0;
				IS_WRITING<=1;
			end
			WRITE_FINISH:begin
				CS<=1;
				IS_READING<=0;
				IS_WRITING<=0;
			end
			default:begin
				CS<=1;
				IS_READING<=0;
				IS_WRITING<=0;
			end
		endcase
	end	

	//命令发送模块信号控制
	always @(posedge CLK)begin
		case(next_state)
			WAIT_INITIALIZE_FINISH:begin
				command_sender_enable<=0;
				command_sender_reset<=0;
				command_to_send<=command_to_send;	
			end
			IDLE:begin
				command_sender_enable<=0;
				command_sender_reset<=0;
				command_to_send<=command_to_send;
			end
			READ_CMD_LOAD:begin
				command_sender_enable<=0;
				command_sender_reset<=1;
				command_to_send<={CMD17_HEAD,READ_ADDRESS,CMD17_CRC};
			end
			READ_CMD_SEND:begin
				command_sender_enable<=1;
				command_sender_reset<=0;
				command_to_send<=command_to_send;
			end
			READ_CMD_RESPONSE_WAIT:begin
				command_sender_enable<=0;
				command_sender_reset<=0;
				command_to_send<=command_to_send;
			end
			READ_DATA:begin
			 	command_sender_enable<=0;
				command_sender_reset<=0;
				command_to_send<=command_to_send;
			end
			READ_FINISH:begin
				command_sender_enable<=0;
				command_sender_reset<=0;
				command_to_send<=command_to_send;
			end
			WRITE_CMD_LOAD:begin
				command_sender_enable<=0;
				command_sender_reset<=1;
				command_to_send<={CMD24_HEAD,WRITE_ADDRESS,CMD24_CRC};
			end
			WRITE_CMD_SEND:begin
				command_sender_enable<=1;
				command_sender_reset<=0;
				command_to_send<=command_to_send;
			end
			WRITE_CMD_RESPONSE_WAIT:begin
				command_sender_enable<=0;
				command_sender_reset<=0;
				command_to_send<=command_to_send;
			end
			WRITE_DATA_SEND:begin
				command_sender_enable<=0;
				command_sender_reset<=0;
				command_to_send<=command_to_send;
			end
			WRITE_FINISH:begin
				command_sender_enable<=0;
				command_sender_reset<=0;
				command_to_send<=command_to_send;
			end
			default:begin
				command_sender_enable<=0;
				command_sender_reset<=0;
				command_to_send<=command_to_send;
			end
		endcase
	end

	//响应读取信号控制
	always @(posedge CLK)begin
		case(next_state)
			WAIT_INITIALIZE_FINISH:begin
				response_receiver_activate<=0;
			end
			IDLE:begin
				response_receiver_activate<=0;
			end
			READ_CMD_LOAD:begin
				response_receiver_activate<=0;
			end
			READ_CMD_SEND:begin
				response_receiver_activate<=0;
			end
			READ_CMD_RESPONSE_WAIT:begin
				response_receiver_activate<=1;
			end
			READ_DATA:begin
			 	response_receiver_activate<=0;
			end
			READ_FINISH:begin
				response_receiver_activate<=0;
			end
			WRITE_CMD_LOAD:begin
				response_receiver_activate<=0;
			end
			WRITE_CMD_SEND:begin
				response_receiver_activate<=0;
			end
			WRITE_CMD_RESPONSE_WAIT:begin
				response_receiver_activate<=1;
			end
			WRITE_DATA_SEND:begin
				response_receiver_activate<=0;
			end
			WRITE_FINISH:begin
				response_receiver_activate<=0;
			end
			default:begin
				response_receiver_activate<=0;
			end
		endcase
	end

	//数据存储信号控制
	always @(posedge CLK)begin
		case(next_state)
			WAIT_INITIALIZE_FINISH:begin
				data_receiver_start<=0;
			end
			IDLE:begin
				data_receiver_start<=0;
			end
			READ_CMD_LOAD:begin
				data_receiver_start<=0;
			end
			READ_CMD_SEND:begin
				data_receiver_start<=0;
			end
			READ_CMD_RESPONSE_WAIT:begin
				data_receiver_start<=0;
			end
			READ_DATA:begin
			 	data_receiver_start<=1;
			end
			READ_FINISH:begin
				data_receiver_start<=0;
			end
			WRITE_CMD_LOAD:begin
				data_receiver_start<=0;
			end
			WRITE_CMD_SEND:begin
				data_receiver_start<=0;
			end
			WRITE_CMD_RESPONSE_WAIT:begin
				data_receiver_start<=0;
			end
			WRITE_DATA_SEND:begin
				data_receiver_start<=0;
			end
			WRITE_FINISH:begin
				data_receiver_start<=0;
			end
			default:begin
				data_receiver_start<=0;
			end
		endcase
	end

	//写数据信号控制
	always @(posedge CLK)begin
		case(next_state)
			WAIT_INITIALIZE_FINISH:begin
				data_writer_start<=0;
				data_writer_reset<=1;		
			end
			IDLE:begin
				data_writer_start<=0;
				data_writer_reset<=1;
			end
			READ_CMD_LOAD:begin
				data_writer_start<=0;
				data_writer_reset<=1;
			end
			READ_CMD_SEND:begin
				data_writer_start<=0;
				data_writer_reset<=1;
			end
			READ_CMD_RESPONSE_WAIT:begin
				data_writer_start<=0;
				data_writer_reset<=1;
			end
			READ_DATA:begin
			 	data_writer_start<=0;
				data_writer_reset<=1;
			end
			READ_FINISH:begin
				data_writer_start<=0;
				data_writer_reset<=1;
			end
			WRITE_CMD_LOAD:begin
				data_writer_start<=0;
				data_writer_reset<=0;
			end
			WRITE_CMD_SEND:begin
				data_writer_start<=0;
				data_writer_reset<=0;
			end
			WRITE_CMD_RESPONSE_WAIT:begin
				data_writer_start<=0;
				data_writer_reset<=0;
			end
			WRITE_DATA_SEND:begin
				data_writer_start<=1;
				data_writer_reset<=0;
			end
			WRITE_FINISH:begin
				data_writer_start<=0;
				data_writer_reset<=1;
			end
			default:begin
				data_writer_start<=0;
				data_writer_reset<=1;
			end
		endcase
	end

	//DI选择
	always @(posedge CLK)begin
		case(next_state)
			WAIT_INITIALIZE_FINISH:begin
				DI_user<=DI_using_by_command_sender;
			end
			IDLE:begin
				DI_user<=DI_using_by_command_sender;
			end
			READ_CMD_LOAD:begin
				DI_user<=DI_using_by_command_sender;
			end
			READ_CMD_SEND:begin
				DI_user<=DI_using_by_command_sender;
			end
			READ_CMD_RESPONSE_WAIT:begin
				DI_user<=DI_using_by_command_sender;
			end
			READ_DATA:begin
			 	DI_user<=DI_using_by_command_sender;
			end
			READ_FINISH:begin
				DI_user<=DI_using_by_command_sender;
			end
			WRITE_CMD_LOAD:begin
				DI_user<=DI_using_by_command_sender;
			end
			WRITE_CMD_SEND:begin
				DI_user<=DI_using_by_command_sender;
			end
			WRITE_CMD_RESPONSE_WAIT:begin
				DI_user<=DI_using_by_command_sender;
			end
			WRITE_DATA_SEND:begin
				DI_user<=DI_using_by_data_writer;
			end
			WRITE_FINISH:begin
				DI_user<=DI_using_by_command_sender;
			end
			default:begin
				DI_user<=DI_using_by_command_sender;
			end
		endcase
	end
endmodule