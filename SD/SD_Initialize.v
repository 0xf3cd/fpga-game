`include "./Head.v"
`include "./Tools/Shift_Register_40bits.v"
`include "./Tools/Shift_Register_48bits.v"

module SD_Initialize(DO,CLK,START,DI,CS,OK);
	input DO;//MISO 对于SD卡而言为DO
	input CLK;
	input START;
	output reg DI=1;//MOSI 对于SD卡而言为DI
	output reg CS=1;
	output OK;

	/*
	当START有效时开始进行初始化
	初始化成功后OK为1
	*/

	parameter STATE_ENCODE_LENGTH=5;
	parameter IDLE=5'b00000;
	parameter RESET_WAIT=5'b00001;
	parameter RESET_PREPARE=5'b00011;
	parameter RESET_EXECUTE=5'b00010;
	parameter RESET_READ_RESPONSE=5'b00110;
	parameter RESET_FINISH=5'b00111;
	parameter CHECK_LOAD=5'b00101;
	parameter CHECK_PREPARE=5'b00100;
	parameter CHECK_EXECUTE=5'b01100;
	parameter CHECK_READ_RESPONSE=5'b01101;
	parameter CHECK_FINISH=5'b01111;
	parameter APP_CMD_LOAD=5'b01110;
	parameter APP_CMD_PREPARE=5'b01010;
	parameter APP_CMD_EXECUTE=5'b01011;
	parameter APP_CMD_READ_RESPONSE=5'b01001;
	parameter APP_CMD_FINISH=5'b01000;
	parameter ACTIVATE_LOAD=5'b11000;
	parameter ACTIVATE_PREPARE=5'b11001;
	parameter ACTIVATE_EXECUTE=5'b11011;
	parameter ACTIVATE_READ_RESPONSE=5'b11010;
	parameter ACTIVATE_FINISH=5'b11110;
	parameter TURN_OFF_CRC_CHECK_LOAD=5'b11111;
	parameter TURN_OFF_CRC_CHECK_PREPARE=5'b11101;
	parameter TURN_OFF_CRC_CHECK_EXECUTE=5'b11100;
	parameter TURN_OFF_CRC_CHECK_READ_RESPONSE=5'b10100;
	parameter TURN_OFF_CRC_CHECK_FINISH=5'b10101;
	parameter FINISH=5'b10111;

	parameter INITIAL_STATE=IDLE;
	//100101 110111


	/*
	*以下为初始化需要使用的命令
	*CMD0 复位，使SD卡回归至IDLE状态
	*CMD8 发送接口状态
	*CMD55 告知SD卡下一个命令为应用命令（ACMD），而非标准命令
	*ACMD41 要求SD卡发送OCR寄存器的内容
	*CMD59 关闭CRC检查
	*/
	parameter CMD0_HEAD=8'b0100_0000;
	parameter CMD8_HEAD=8'b0100_1000;
	parameter CMD55_HEAD=8'b0111_0111;
	parameter CMD59_HEAD=8'b0111_1011;
	parameter ACMD41_HEAD=8'b0110_1001;
	parameter CMD0_ARGUMENT=32'b0000_0000_0000_0000_0000_0000_0000_0000;
	parameter CMD8_ARGUMENT=32'b0000_0000_0000_0000_0000_0001_1010_1010;	
	parameter CMD55_ARGUMENT=32'b0000_0000_0000_0000_0000_0000_0000_0000;
	parameter CMD59_ARGUMENT=32'b0000_0000_0000_0000_0000_0000_0000_0000;
	parameter ACMD41_ARGUMENT=32'b0100_0000_0000_0000_0000_0000_0000_0000;
	parameter CMD0_CRC=8'b1001_0101;
	parameter CMD8_CRC=8'b1000_0111;
	parameter CMD55_CRC=8'b0110_0101;
	parameter CMD59_CRC=8'b1001_0001;
	parameter ACMD41_CRC=8'b0111_0111;
	parameter CMD0_RESPONSE=8'b0000_0001;
	parameter CMD8_RESPONSE_R1_PART=8'b0000_0001;
	parameter CMD8_RESPONSE_ECHO_BACK_PART=8'b1010_1010;
	parameter CMD55_WAIT_RESPONSE=8'b0000_0001;
	parameter CMD55_ACTIVATED_RESPONSE=8'b0000_0000;
	parameter CMD59_RESPONSE=8'b0000_0000;
	parameter ACMD41_ACTIVATED_RESPONSE=8'b0000_0000;


	//响应处理部分
	reg response_enable;//有效时表示开始接收响应
	reg [5:0]response_length;//记录响应的长度
	reg [5:0]response_counter;//记录response_enable有效时，时钟下降沿的个数
	wire [39:0]response_saver;//储存响应
	reg response_counter_reset=0;

	Shift_Register_40bits response_register(~CLK,DO,response_enable,response_saver);

	always @(DO or response_counter or response_length)begin//锁存器，控制response_enable的值
		if(DO==0&&response_counter==0)begin
			response_enable=1;
		end
		else if(response_counter==response_length)begin
			response_enable=0;
		end
		else begin
			response_enable=response_enable;
		end
	end

	always @(negedge CLK)begin//response_enable有效时进行时钟下降沿计数，否则保持
		if(response_counter_reset)begin
			response_counter<=0;
		end
		else begin
			if(response_enable)begin
				response_counter<=response_counter+1;
			end
			else begin
				response_counter<=response_counter;
			end
		end
	end



	//指令发送控制部分
	wire cmd_to_send;
	reg [47:0]cmd;//储存需要执行的指令
	reg cmd_execute;//有效时执行指令
	reg cmd_write;//有效时将cmd的值写入储存指令的移位寄存器

	Shift_Register_48bits cmd_register(CLK,1,cmd_write,cmd,cmd_to_send);
	//当cmd_write有效时，需要执行的指令被写入命令寄存器
	//随后每当时钟上升沿到来时，指令会一位一位移位
	//cmd_to_send为每次需要发送的指令(1位)
	//当指令全部移出寄存器时，cmd_to_send恒为1

	always @(negedge CLK)begin//避免竞争冒险，下降沿时写入DI，SD卡在时钟上升沿读入DI上的数据
		if(cmd_execute)begin
			DI<=cmd_to_send;
		end
		else begin
			DI<=1;
		end
	end



	//空时钟发送控制部分
	reg [3:0]empty_clk_counter;//记录发送空时钟个数的计数器
	reg empty_clk_enable;//有效时开始发送空时钟
	reg empty_clk_counter_reset=0;

	always @(posedge CLK)begin
		if(empty_clk_counter_reset)begin
			empty_clk_counter<=0;
		end
		else begin
			if(empty_clk_enable)begin
				empty_clk_counter<=empty_clk_counter+1;
			end
			else begin
				empty_clk_counter<=empty_clk_counter;
			end
		end
	end



	//CRC校验位读取部分
	reg [3:0]crc_receive_counter;//记录收到的冗余循环检查的位数
	reg crc_receive_enable;
	reg crc_receive_counter_reset=0;

	always @(posedge CLK)begin
		if(crc_receive_counter_reset)begin
			crc_receive_counter<=0;
		end
		else begin
			if(crc_receive_enable)begin
				crc_receive_counter<=crc_receive_counter+1;
			end
			else begin
				crc_receive_counter<=crc_receive_counter;
			end
		end
	end



	//时钟个数计数部分
	reg [7:0]clk_counter;
	reg clk_counter_reset=0;

	always @(posedge CLK)begin
		if(clk_counter_reset)begin
			clk_counter<=0;
		end
		else begin
			clk_counter<=clk_counter+1;
		end
	end


	//状态机描述部分
	reg [STATE_ENCODE_LENGTH-1:0]current_state=INITIAL_STATE;
	reg [STATE_ENCODE_LENGTH-1:0]next_state;
	
	always @(posedge CLK)begin//描述状态机状态的转移，时序逻辑
		current_state<=next_state;
	end

	always @(*)begin//描述状态机的状态转移条件，组合逻辑
		case(current_state)
			IDLE:begin
			if(START)begin
				next_state=RESET_WAIT;
			end
			else begin
				next_state=IDLE;
			end
			end
			RESET_WAIT:begin
				if(clk_counter==8'b11111111)begin
					next_state=RESET_PREPARE;
				end
				else begin
					next_state=RESET_WAIT;
				end
			end
			RESET_PREPARE:begin
				next_state=RESET_EXECUTE;
			end
			RESET_EXECUTE:begin
				next_state=RESET_READ_RESPONSE;
			end
			RESET_READ_RESPONSE:begin
				if(response_counter==response_length)begin//响应读取完毕
					next_state=RESET_FINISH;
				end
				else begin
					next_state=RESET_READ_RESPONSE;
				end
			end
			RESET_FINISH:begin
				if(empty_clk_counter==4'b1111)begin//空时钟发送完毕
					if(response_saver[7:0]==CMD0_RESPONSE)begin
						next_state=CHECK_LOAD;//响应正确
					end
					else begin
						next_state=IDLE;//响应错误，重新执行CMD0
					end
				end
				else begin
					next_state=RESET_FINISH;
				end
			end
			CHECK_LOAD:begin
				next_state=CHECK_PREPARE;
			end
			CHECK_PREPARE:begin
				next_state=CHECK_EXECUTE;
			end
			CHECK_EXECUTE:begin
				next_state=CHECK_READ_RESPONSE;
			end
			CHECK_READ_RESPONSE:begin
				if(response_counter==response_length)begin//响应读取完毕
					next_state=CHECK_FINISH;
				end
				else begin
					next_state=CHECK_READ_RESPONSE;
				end
			end
			CHECK_FINISH:begin
				if(empty_clk_counter==4'b1111)begin//空时钟发送完毕
					if(response_saver[7:0]==CMD8_RESPONSE_ECHO_BACK_PART
						&&response_saver[39:32]==CMD8_RESPONSE_R1_PART)begin
						next_state=APP_CMD_LOAD;//响应正确
					end
					else begin
						next_state=CHECK_LOAD;//响应错误，重新执行CMD8
					end
				end
				else begin
					next_state=CHECK_FINISH;
				end
			end
			APP_CMD_LOAD:begin
				next_state=APP_CMD_PREPARE;
			end
			APP_CMD_PREPARE:begin
				next_state=APP_CMD_EXECUTE;
			end
			APP_CMD_EXECUTE:begin
				next_state=APP_CMD_READ_RESPONSE;
			end
			APP_CMD_READ_RESPONSE:begin
				if(response_counter==response_length)begin//响应读取完毕
					next_state=APP_CMD_FINISH;
				end
				else begin
					next_state=APP_CMD_READ_RESPONSE;
				end
			end
			APP_CMD_FINISH:begin
				if(empty_clk_counter==4'b1111)begin//空时钟发送完毕
					if(response_saver[7:0]==CMD55_WAIT_RESPONSE
						||response_saver[7:0]==CMD55_ACTIVATED_RESPONSE)begin
						next_state=ACTIVATE_LOAD;
					end
					else begin
						next_state=APP_CMD_LOAD;
					end
				end
				else begin
					next_state=APP_CMD_FINISH;
				end
			end
			ACTIVATE_LOAD:begin
				next_state=ACTIVATE_PREPARE;
			end
			ACTIVATE_PREPARE:begin
				next_state=ACTIVATE_EXECUTE;
			end
			ACTIVATE_EXECUTE:begin
				next_state=ACTIVATE_READ_RESPONSE;
			end
			ACTIVATE_READ_RESPONSE:begin
				if(response_counter==response_length)begin//响应读取完毕
					next_state=ACTIVATE_FINISH;
				end
				else begin
					next_state=ACTIVATE_READ_RESPONSE;
				end
			end
			ACTIVATE_FINISH:begin
				if(empty_clk_counter==4'b1111)begin//空时钟发送完毕
					if(response_saver[7:0]==ACMD41_ACTIVATED_RESPONSE)begin
						next_state=TURN_OFF_CRC_CHECK_LOAD;//如果SD卡被激活，则返回ACMD41_ACTIVATED_RESPONSE
					end
					else begin
						next_state=APP_CMD_LOAD;//否则持续循环发送CMD55及ACMD41
					end
				end
				else begin
					next_state=ACTIVATE_FINISH;
				end
			end
			TURN_OFF_CRC_CHECK_LOAD:begin
				next_state=TURN_OFF_CRC_CHECK_PREPARE;
			end
			TURN_OFF_CRC_CHECK_PREPARE:begin
				next_state=TURN_OFF_CRC_CHECK_EXECUTE;
			end
			TURN_OFF_CRC_CHECK_EXECUTE:begin
				next_state=TURN_OFF_CRC_CHECK_READ_RESPONSE;
			end
			TURN_OFF_CRC_CHECK_READ_RESPONSE:begin
				if(response_counter==response_length)begin//响应读取完毕
					next_state=TURN_OFF_CRC_CHECK_FINISH;
				end 
				else begin
					next_state=TURN_OFF_CRC_CHECK_READ_RESPONSE;
				end
			end
			TURN_OFF_CRC_CHECK_FINISH:begin
				if(empty_clk_counter==4'b1111)begin//空时钟发送完毕
					if(response_saver[7:0]==CMD59_RESPONSE)begin
						next_state=FINISH;//响应正确，进行时钟频率调整
					end
					else begin
						next_state=TURN_OFF_CRC_CHECK_LOAD;//响应错误，重新进行关闭CRC检查操作
					end
				end
				else begin
					next_state=TURN_OFF_CRC_CHECK_FINISH;
				end
			end
			FINISH:begin
				next_state=FINISH;
			end
			default:begin
				next_state=IDLE;
			end
		endcase	
	end

	always @(posedge CLK)begin//描述状态机的状态输出
		case(next_state)
			IDLE:begin
				CS<=1;
			end
			RESET_WAIT:begin
				CS<=1;
			end
			RESET_PREPARE:begin
				CS<=0;
			end
			RESET_EXECUTE:begin
				CS<=0;
			end
			RESET_READ_RESPONSE:begin
				CS<=0;
			end
			RESET_FINISH:begin
				CS<=1;
			end
			CHECK_LOAD:begin
				CS<=1;
			end
			CHECK_PREPARE:begin
				CS<=0;
			end
			CHECK_EXECUTE:begin
				CS<=0;
			end
			CHECK_READ_RESPONSE:begin
				CS<=0;
			end
			CHECK_FINISH:begin
				CS<=1;
			end
			APP_CMD_LOAD:begin
				CS<=1;
			end
			APP_CMD_PREPARE:begin
				CS<=0;
			end
			APP_CMD_EXECUTE:begin
				CS<=0;
			end
			APP_CMD_READ_RESPONSE:begin
				CS<=0;
			end
			APP_CMD_FINISH:begin
				CS<=1;
			end
			ACTIVATE_LOAD:begin
				CS<=1;
			end
			ACTIVATE_PREPARE:begin
				CS<=0;
			end
			ACTIVATE_EXECUTE:begin
				CS<=0;
			end
			ACTIVATE_READ_RESPONSE:begin
				CS<=0;
			end
			ACTIVATE_FINISH:begin
				CS<=1;
			end
			TURN_OFF_CRC_CHECK_LOAD:begin
				CS<=1;
			end
			TURN_OFF_CRC_CHECK_PREPARE:begin
				CS<=0;
			end
			TURN_OFF_CRC_CHECK_EXECUTE:begin
				CS<=0;
			end
			TURN_OFF_CRC_CHECK_READ_RESPONSE:begin
				CS<=0;
			end
			TURN_OFF_CRC_CHECK_FINISH:begin
				CS<=1;
			end
			FINISH:begin	
				CS<=1;
			end
			default:begin
				CS<=1;
			end
		endcase
	end

	always @(posedge CLK)begin//描述状态机的状态输出
		case(next_state)
			IDLE:begin
				cmd_execute<=0;
				cmd_write<=0;
			end
			RESET_WAIT:begin
				cmd_execute<=0;
				cmd_write<=1;
				cmd<={CMD0_HEAD,CMD0_ARGUMENT,CMD0_CRC};//将下一个需要执行的指令CMD0写入移位寄存器
			end
			RESET_PREPARE:begin
				cmd_execute<=1;
				cmd_write<=0;
			end
			RESET_EXECUTE:begin
				cmd_execute<=1;
				cmd_write<=0;
			end
			RESET_READ_RESPONSE:begin
				cmd_execute<=1;
				cmd_write<=0;
			end
			RESET_FINISH:begin
				cmd_execute<=0;
				cmd_write<=0;
			end
			CHECK_LOAD:begin
				cmd_execute<=0;
				cmd_write<=1;
				cmd<={CMD8_HEAD,CMD8_ARGUMENT,CMD8_CRC};
			end
			CHECK_PREPARE:begin
				cmd_execute<=1;
				cmd_write<=0;
			end
			CHECK_EXECUTE:begin
				cmd_execute<=1;
				cmd_write<=0;
			end
			CHECK_READ_RESPONSE:begin
				cmd_execute<=1;
				cmd_write<=0;
			end
			CHECK_FINISH:begin
				cmd_execute<=0;
				cmd_write<=0;
			end
			APP_CMD_LOAD:begin
				cmd_execute<=0;
				cmd_write<=1;
				cmd<={CMD55_HEAD,CMD55_ARGUMENT,CMD55_CRC};
			end
			APP_CMD_PREPARE:begin
				cmd_execute<=1;
				cmd_write<=0;
			end
			APP_CMD_EXECUTE:begin
				cmd_execute<=1;
				cmd_write<=0;
			end
			APP_CMD_READ_RESPONSE:begin
				cmd_execute<=1;
				cmd_write<=0;
			end
			APP_CMD_FINISH:begin
				cmd_execute<=0;
				cmd_write<=0;
			end
			ACTIVATE_LOAD:begin
				cmd_execute<=0;
				cmd_write<=1;
				cmd<={ACMD41_HEAD,ACMD41_ARGUMENT,ACMD41_CRC};
			end
			ACTIVATE_PREPARE:begin
				cmd_execute<=1;
				cmd_write<=0;
			end
			ACTIVATE_EXECUTE:begin
				cmd_execute<=1;
				cmd_write<=0;			
			end
			ACTIVATE_READ_RESPONSE:begin
				cmd_execute<=1;
				cmd_write<=0;
			end
			ACTIVATE_FINISH:begin
				cmd_execute<=0;
				cmd_write<=0;
			end
			TURN_OFF_CRC_CHECK_LOAD:begin
				cmd_execute<=0;
				cmd_write<=1;
				cmd<={CMD59_HEAD,CMD59_ARGUMENT,CMD59_CRC};
			end
			TURN_OFF_CRC_CHECK_PREPARE:begin
				cmd_execute<=1;
				cmd_write<=0;
			end
			TURN_OFF_CRC_CHECK_EXECUTE:begin
				cmd_execute<=1;
				cmd_write<=0;
			end
			TURN_OFF_CRC_CHECK_READ_RESPONSE:begin
				cmd_execute<=1;
				cmd_write<=0;
			end
			TURN_OFF_CRC_CHECK_FINISH:begin
				cmd_execute<=0;
				cmd_write<=0;
			end
			FINISH:begin	
				cmd_execute<=0;
				cmd_write<=0;
			end
			default:begin
				cmd_execute<=0;
				cmd_write<=0;
			end
		endcase
	end

	always @(posedge CLK)begin//描述状态机的状态输出
		case(next_state)
			IDLE:begin
				clk_counter_reset<=1;
			end
			RESET_WAIT:begin
				clk_counter_reset<=0;
			end
			RESET_PREPARE:begin
				response_length<='d8;//设定响应格式为R1，长度为8
				response_counter_reset<=1;
				empty_clk_counter_reset<=1;
				empty_clk_enable<=0;
			end
			RESET_EXECUTE:begin
				response_counter_reset<=0;
				empty_clk_counter_reset<=0;
			end
			RESET_FINISH:begin
				empty_clk_enable<=1;
			end
			CHECK_PREPARE:begin
				response_length<='d40;//响应格式为R7，长度为40
				response_counter_reset<=1;
				empty_clk_counter_reset<=1;
				empty_clk_enable<=0;
			end
			CHECK_EXECUTE:begin
				response_counter_reset<=0;
				empty_clk_counter_reset<=0;
			end
			CHECK_FINISH:begin
				empty_clk_enable<=1;
			end
			APP_CMD_PREPARE:begin
				response_length<='d8;//R1 8位
				response_counter_reset<=1;
				empty_clk_counter_reset<=1;
				empty_clk_enable<=0;
			end
			APP_CMD_EXECUTE:begin
				response_counter_reset<=0;
				empty_clk_counter_reset<=0;
			end
			APP_CMD_FINISH:begin
				empty_clk_enable<=1;
			end
			ACTIVATE_PREPARE:begin
				response_length<='d8;//R1 8位
				response_counter_reset<=1;
				empty_clk_counter_reset<=1;
				empty_clk_enable<=0;
			end
			ACTIVATE_EXECUTE:begin
				response_counter_reset<=0;
				empty_clk_counter_reset<=0;				
			end
			ACTIVATE_FINISH:begin
				empty_clk_enable<=1;
			end
			TURN_OFF_CRC_CHECK_PREPARE:begin
				response_length<='d8;//R1 8位
				response_counter_reset<=1;
				empty_clk_counter_reset<=1;
				empty_clk_enable<=0;
			end
			TURN_OFF_CRC_CHECK_EXECUTE:begin
				response_counter_reset<=0;
				empty_clk_counter_reset<=0;
			end
			TURN_OFF_CRC_CHECK_FINISH:begin
				empty_clk_enable<=1;
			end
			default:begin
				response_length<=response_length;
				response_counter_reset<=response_counter_reset;
				empty_clk_counter_reset<=empty_clk_counter_reset;
				empty_clk_enable<=empty_clk_enable;
			end
		endcase
	end

	assign OK=(current_state==FINISH);
endmodule