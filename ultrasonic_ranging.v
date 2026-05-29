module ultrasonic_ranging(
     input   sys_clk   ,
	  input   rst_n     ,
	  input   key1      ,
	  input   key2      ,
	  output reg trig   ,
	  input echo        ,
	  output reg  led0  ,
	  output    beep  ,
	  
    output  wire            stcp        , //数据存储器时钟
    output  wire            shcp        , //移位寄存器时钟
    output  wire            ds          , //串行数据输入
    output  wire            oe            //使能信号

);

 
   parameter DATA_WIDTH = 112;
	parameter MSB_FIRST = 0;

	
wire 	key_flag1;
wire  key_value1;
	
	key_debounce u0_key_debounce(
.sys_clk(sys_clk),          //外部50M时钟
.sys_rst_n(rst_n),        //外部复位信号，低有效
    
.key(key1),              //外部按键输入
.key_flag(key_flag1),         //按键数据有效信号
.key_value(key_value1)         //按键消抖后的数据  
    );

wire 	key_flag2;
wire  key_value2;
	
	key_debounce u1_key_debounce(
.sys_clk(sys_clk),          //外部50M时钟
.sys_rst_n(rst_n),        //外部复位信号，低有效
    
.key(key2),              //外部按键输入
.key_flag(key_flag2),         //按键数据有效信号
.key_value(key_value2)         //按键消抖后的数据  
    );

reg echo_d0;
reg echo_d1;
wire echo_fall;	
always@(posedge sys_clk or negedge rst_n)begin
   if(!rst_n)begin
	   echo_d0 <= 1'b0;
		echo_d1 <= 1'b0;
	end
	else begin
	   echo_d0 <= echo;
		echo_d1 <= echo_d0;
	end
end
assign echo_fall = (!echo_d0)&&(echo_d1);
	

reg [31:0] cntc;
reg beep_reg;
wire beep_en;
always@(posedge sys_clk )begin
   begin
	   if(cntc <= 32'd25_000)begin
		   cntc <= cntc + 1'b1;
			beep_reg <= beep_reg;
		end
		else begin
		   cntc <= 32'd0;
			beep_reg <= ~beep_reg;
		end
	end
end
assign beep = beep_en? beep_reg : 1'b0;
	 
seg_595_dynamic    seg_595_dynamic_inst
(
    .sys_clk    (sys_clk   ),   //系统时钟，频率50MHz
    .sys_rst_n  (rst_n ),   //复位信号，低有效
    .data       (data      ),   //数码管要显示的值
    .point      (6'd0     ),   //小数点显示,高电平有效
    .seg_en     (1'b1    ),   //数码管使能信号，高电平有效
    .sign       (1'b0      ),   //符号位，高电平显示负号

    .stcp       (stcp      ),   //输出数据存储寄时钟
    .shcp       (shcp      ),   //移位寄存器的时钟输入
    .ds         (ds        ),   //串行数据输入
    .oe         (oe        )    //输出使能信号
);





reg [1:0] status;
reg [31:0] delay;//延时作用
reg [31:0] time_reg;
always@(posedge sys_clk or negedge rst_n)begin
   if(!rst_n)begin
	   status <= 2'd0;
		delay <= 32'd0;
		time_reg <= 32'd0;
		trig <= 1'b0;
	end
	else begin
	   case(status)
		    2'd0:begin
			         if(delay < 'd50_000_00)begin//延时100ms
						   delay <= delay + 1'b1;
							status <= status; 
						end
						else begin
						   delay <= 'd0;
							status <= status + 1'b1;;
						end
			      end
			 2'd1:begin
			         if(delay < 'd800)begin
						   delay <= delay + 1'b1;
							status <= status ;
							trig <= 1'b1;
						end
						else begin
						   delay <= 'd0;
							status <= status + 1'b1;
							trig <= 1'b0;
						end
			      end
			 2'd2:begin
			         if(echo)begin
							delay <= delay + 1'b1;
						end
						else begin
						   if(echo_fall)begin
								time_reg <= delay;
								delay <= 'd0;
								status <= status + 1'b1;
							end
							else begin
							   delay <= delay;
								time_reg <= time_reg;
								status <= status;
							end
						end
			      end
			 2'd3:begin
			         status <= 2'd0;
			      end
		  default:begin
		            status <= status;
		         end
		endcase
	end
end
	 
assign beep_en = (time_reg < 'd12000)? 1'b1:1'b0;	

endmodule
