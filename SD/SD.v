`include "./Head.v"
`include "./SD/SD_Initialize.v"
`include "./SD/SD_Read_Write.v"

module SD #(parameter DATA_TO_WRITE_LENGTH=16)(CLK,DO,START_TO_INITIALIZE,TO_READ,TO_WRITE,
			READ_ADDRESS,WRITE_ADDRESS,DATA_TO_WRITE,DI,SD_CLK,CS,HAS_INITIALIZED,IS_READING,
			IS_WRITING,DATA_READ);
	input CLK;
	input DO;
	input START_TO_INITIALIZE;
	input TO_READ;
	input TO_WRITE;
	input [31:0]READ_ADDRESS;
	input [31:0]WRITE_ADDRESS;
	input [DATA_TO_WRITE_LENGTH-1:0]DATA_TO_WRITE;
	output DI;
	output SD_CLK;
	output CS;
	output reg HAS_INITIALIZED;
	output reg IS_READING;
	output reg IS_WRITING;
	output [4095:0]DATA_READ;

	wire clk_initialize;
	wire clk_read_and_write;
	Divider #(9,1000) get_initliaze_clk(CLK,clk_initialize);
	assign clk_read_and_write=CLK;

	parameter SD_initializing=1'b0;
	parameter SD_initialized=1'b1;
	reg SD_state=SD_initializing;

	/*
	当START有效时开始进行初始化
	初始化成功后OK为1
	*/
	reg initialize_start=0;
	wire DI_initialize;
	wire CS_initialize;
	wire initialize_finish;
	SD_Initialize initialize(.DO(DO),
							 .CLK(clk_initialize),
							 .START(initialize_start),
							 .DI(DI_initialize),
							 .CS(CS_initialize),
							 .OK(initialize_finish));

	/*
	*SD卡初始化后上层模块将INITIALIZE_OK置为1，之后才可以开始读写
	*写操作为的是写入游戏最高分，固定为16位
	*读操作一次读出4096位，在下一次读之前读出的值将保持
	*/
	reg write_start=0;
	reg read_start=0;
	wire DI_read_and_write;
	wire CS_read_and_write;
	wire sd_is_reading;
	wire sd_is_writing;
	SD_Read_Write #(.DATA_TO_WRITE_LENGTH(DATA_TO_WRITE_LENGTH))SD
					(.CLK(clk_read_and_write),
					 .DO(DO),
					 .INITIALIZE_OK(initialize_finish),
					 .TO_WRITE(write_start),
					 .TO_READ(read_start),
					 .DATA_TO_WRITE(DATA_TO_WRITE),
					 .READ_ADDRESS(READ_ADDRESS),
					 .WRITE_ADDRESS(WRITE_ADDRESS),
					 .CS(CS_read_and_write),
					 .DI(DI_read_and_write),
					 .DATA(DATA_READ),
					 .IS_READING(sd_is_reading),
					 .IS_WRITING(sd_is_writing));


	assign SD_CLK=(SD_state==SD_initializing)?clk_initialize:clk_read_and_write;
	assign DI=(SD_state==SD_initializing)?DI_initialize:DI_read_and_write;
	assign CS=(SD_state==SD_initializing)?CS_initialize:CS_read_and_write;

	
	parameter IDLE=4'b0000;//闲闲没事做
	parameter INITIALIZING=4'b0001;
	parameter I_AM_READY=4'b0011;
	parameter READ_PREPARE=4'b0010;
	parameter I_AM_READING=4'b0110;
	parameter READ_FINISH=4'b0111;
	parameter WRITE_PREPARE=4'b0101;
	parameter I_AM_WRITING=4'b0100;
	parameter WRITE_FINISH=4'b1100;

	reg [3:0]current_state=IDLE;
	reg [3:0]next_state;

	always @(posedge SD_CLK)begin
		current_state<=next_state;
	end

	/*
	根据以下数值进行状态转换
	START_TO_INITIALIZE
	TO_READ
	TO_WRITE
	initialize_finish
	sd_is_reading
	sd_is_writing
	*/
	always @(*)begin
		case(current_state)
			IDLE:begin
				if(START_TO_INITIALIZE)begin
					next_state=INITIALIZING;
				end
				else begin
					next_state=IDLE;
				end
			end
			INITIALIZING:begin
				if(initialize_finish)begin
					next_state=I_AM_READY;
				end
				else begin
					next_state=INITIALIZING;
				end
			end
			I_AM_READY:begin
				if(TO_READ)begin
					next_state=READ_PREPARE;
				end
				else if(TO_WRITE)begin
					next_state=WRITE_PREPARE;
				end
				else begin
					next_state=I_AM_READY;
				end
			end
			READ_PREPARE:begin
				if(sd_is_reading)begin
					next_state=I_AM_READING;
				end
				else begin
					next_state=READ_PREPARE;
				end
			end
			I_AM_READING:begin
				if(!sd_is_reading)begin//读取结束
					next_state=READ_FINISH;
				end
				else begin
					next_state=I_AM_READING;
				end
			end
			READ_FINISH:begin
				next_state=I_AM_READY;
			end
			WRITE_PREPARE:begin
				if(sd_is_writing)begin
					next_state=I_AM_WRITING;
				end
				else begin
					next_state=WRITE_PREPARE;
				end
			end
			I_AM_WRITING:begin
				if(!sd_is_writing)begin
					next_state=WRITE_FINISH;
				end
				else begin
					next_state=I_AM_WRITING;
				end
			end
			WRITE_FINISH:begin
				next_state=I_AM_READY;
			end
			default:begin
				next_state=IDLE;
			end
		endcase
	end


	always @(posedge SD_CLK)begin
		case(next_state)
			IDLE:begin
				SD_state<=SD_initializing;
				HAS_INITIALIZED<=0;
			end
			INITIALIZING:begin
				SD_state<=SD_initializing;
				HAS_INITIALIZED<=0;
			end
			I_AM_READY:begin
				SD_state<=SD_initialized;
				HAS_INITIALIZED<=1;
			end
			READ_PREPARE:begin
				SD_state<=SD_initialized;
				HAS_INITIALIZED<=1;
			end
			I_AM_READING:begin
				SD_state<=SD_initialized;
				HAS_INITIALIZED<=1;
			end
			READ_FINISH:begin
				SD_state<=SD_initialized;
				HAS_INITIALIZED<=1;
			end
			WRITE_PREPARE:begin
				SD_state<=SD_initialized;
				HAS_INITIALIZED<=1;
			end
			I_AM_WRITING:begin
				SD_state<=SD_initialized;
				HAS_INITIALIZED<=1;
			end
			WRITE_FINISH:begin
				SD_state<=SD_initialized;
				HAS_INITIALIZED<=1;
			end
			default:begin
				SD_state<=SD_initializing;
				HAS_INITIALIZED<=0;
			end
		endcase
	end

	always @(posedge SD_CLK)begin
		case(next_state)
			IDLE:begin
				write_start<=0;
				read_start<=0;
			end
			INITIALIZING:begin
				write_start<=0;
				read_start<=0;
			end
			I_AM_READY:begin
				write_start<=0;
				read_start<=0;
			end
			READ_PREPARE:begin
				write_start<=0;
				read_start<=1;
			end
			I_AM_READING:begin
				write_start<=0;
				read_start<=1;
			end
			READ_FINISH:begin
				write_start<=0;
				read_start<=0;
			end
			WRITE_PREPARE:begin
				write_start<=1;
				read_start<=0;
			end
			I_AM_WRITING:begin
				write_start<=1;
				read_start<=0;
			end
			WRITE_FINISH:begin
				write_start<=0;
				read_start<=0;
			end
			default:begin
				write_start<=0;
				read_start<=0;
			end
		endcase
	end

	always @(posedge SD_CLK)begin
		case(next_state)
			IDLE:begin
				IS_WRITING<=0;
				IS_READING<=0;
			end
			INITIALIZING:begin
				IS_WRITING<=0;
				IS_READING<=0;
			end
			I_AM_READY:begin
				IS_WRITING<=0;
				IS_READING<=0;
			end
			READ_PREPARE:begin
				IS_WRITING<=0;
				IS_READING<=1;
			end
			I_AM_READING:begin
				IS_WRITING<=0;
				IS_READING<=1;
			end
			READ_FINISH:begin
				IS_WRITING<=0;
				IS_READING<=0;
			end
			WRITE_PREPARE:begin
				IS_WRITING<=1;
				IS_READING<=0;
			end
			I_AM_WRITING:begin
				IS_WRITING<=1;
				IS_READING<=0;
			end
			WRITE_FINISH:begin
				IS_WRITING<=0;
				IS_READING<=0;
			end
			default:begin
				IS_WRITING<=0;
				IS_READING<=0;
			end
		endcase
	end
	
	always @(posedge SD_CLK)begin
		case(next_state)
			IDLE:begin
				initialize_start<=0;
			end
			INITIALIZING:begin
				initialize_start<=1;
			end
			I_AM_READY:begin
				initialize_start<=1;
			end
			READ_PREPARE:begin
				initialize_start<=1;
			end
			I_AM_READING:begin
				initialize_start<=1;
			end
			READ_FINISH:begin
				initialize_start<=1;
			end
			WRITE_PREPARE:begin
				initialize_start<=1;
			end
			I_AM_WRITING:begin
				initialize_start<=1;
			end
			WRITE_FINISH:begin
				initialize_start<=1;
			end
			default:begin
				initialize_start<=0;
			end
		endcase
	end	
endmodule