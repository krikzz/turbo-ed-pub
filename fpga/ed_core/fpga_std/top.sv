

`define HWC_PSR1_OFF
`define HWC_CDROM_OFF

module top(

	input  CLK,

	inout  [7:0]TG_D,
	input  [20:0]TG_A,
	input  TG_HSM,
	input  TG_OEn,
	input  TG_WEn,
	output TG_IRQ2n,
	output TG_RSTFn,
	output TG_DDIR,
	output TG_DOEn,
	
	
	output [21:0]PSR_A,
	inout  [15:0]PSR_D,
	output PSR_LBn,
	output PSR_UBn,
	output PSR_OEn,
	output PSR_WEn,
	output PSR_CEn,
	
	input  FCI_IO_0,//spi_ss
	output FCI_IO_1,//mcu_fifo_rxf
	input  FCI_IO_2,//mcu_busy
	output FCI_IO_3,//mcu_mode
	input  FCI_IO_4,//region
	output FCI_IO_5,//mcu_brm_n
	output FCI_IO_6,//mcu_rst
	output FCI_MISO,
	input  FCI_MOSI,
	input  FCI_SCK,
	
	output LED_FPGn,
	input  BTNn

);
//************************************************************************************* mcu
	assign mcu_mode 			= !mcu_master;
	assign mcu_rst 			= 1;
	assign mcu_brm_n			= !mcu_brm_bc;
	wire mcu_master;
	wire mcu_brm_bc;
	
	
	
	wire mcu_fifo_rxf;
	wire mcu_mode;
	wire mcu_brm_n;
	wire mcu_rst;
	wire spi_ss					= FCI_IO_0;
	wire mcu_busy				= FCI_IO_2;
	wire region					= FCI_IO_4;
	
	assign FCI_IO_1			= mcu_fifo_rxf;
	assign FCI_IO_3			= mcu_mode;
	assign FCI_IO_5			= mcu_brm_n;
	assign FCI_IO_6			= mcu_rst;
//************************************************************************************* cpu
	assign TG_D[7:0]			= !bus_oe ? 8'hzz : region ? cpu_dati_tg : cpu_dati_pc;
	assign TG_RSTFn			= !cpu_rst_n ? 0 : 1'bz;
	//assign TG_CARTn 			= !cpu_cart_n ? 0 : 1'bz;
	assign TG_IRQ2n 			= !use_irq ? 1'bz : !cpu_irq_n ? 0 : 1;//1'bz;
	
	wire [7:0]cpu_dati_pc	= cpu_dati;
	wire [7:0]cpu_dati_tg	= {cpu_dati[0],cpu_dati[1],cpu_dati[2],cpu_dati[3],cpu_dati[4],cpu_dati[5],cpu_dati[6],cpu_dati[7]};
	
	wire [7:0]cpu_dato_pc	= TG_D[7:0];
	wire [7:0]cpu_dato_tg	= {TG_D[0],TG_D[1],TG_D[2],TG_D[3],TG_D[4],TG_D[5],TG_D[6],TG_D[7]};
	wire [7:0]cpu_dati;
	wire [7:0]cpu_dato 		= region ? cpu_dato_tg : cpu_dato_pc;
	
	wire cpu_rst_n;
	wire cpu_cart_n;
	wire use_irq;
	wire cpu_irq_n;
//************************************************************************************* memory	
	assign PSR_A[21:0] 		= mem0_addr[22:1];
	assign PSR_D[15:0] 		= mem0_oe ? 16'hzzzz : {mem0_dati[7:0], mem0_dati[7:0]};
	assign PSR_CEn 			= !mem0_ce;
	assign PSR_OEn 			= !mem0_oe;
	assign PSR_WEn 			= !mem0_we;
	assign PSR_UBn 			= mem0_addr[0];
	assign PSR_LBn 			= !PSR_UBn;
		
	
	wire [7:0]mem0_dati;
	wire [7:0]mem0_dato		= mem0_addr[0] == 0 ? PSR_D[15:8] : PSR_D[7:0];
	wire [23:0]mem0_addr;
	wire mem0_ce;
	wire mem0_oe;
	wire mem0_we;
	
	
	wire [7:0]mem1_dati;
	wire [7:0]mem1_dato;//		= mem1_addr[0] == 0 ? PSR1_D[15:8] : PSR1_D[7:0];
	wire [23:0]mem1_addr;
	wire mem1_ce;
	wire mem1_oe;
	wire mem1_we;
//************************************************************************************* bus drivers	
	assign TG_DDIR 			= bus_oe;//data bus direction
	assign TG_DOEn				= 0;
	wire bus_oe;
//************************************************************************************* leds
	assign LED_FPGn 			= led_r | led_g ? 0 : 1'bz;
	wire led_g;
	wire led_r;
//************************************************************************************* turbo-ed core
	everdrive everdrive_inst(
	
		.clk(CLK),
		
		.cpu_dati(cpu_dati),
		.cpu_dato(cpu_dato),
		.cpu_addr(TG_A),
		.cpu_oe_n(TG_OEn), 
		.cpu_we_n(TG_WEn),
		.cpu_hsm(TG_HSM),
		.cpu_ce(cpu_ce),
		.cpu_irq_n(cpu_irq_n),
		.cpu_rst_n(cpu_rst_n),
		.cpu_cart_n(cpu_cart_n),
		
		.ram0_dati(mem0_dati),
		.ram0_dato(mem0_dato),
		.ram0_addr(mem0_addr),
		.ram0_ce(mem0_ce),
		.ram0_oe(mem0_oe),
		.ram0_we(mem0_we),
		
		.ram1_dati(mem1_dati),
		.ram1_dato(mem1_dato),
		.ram1_addr(mem1_addr),
		.ram1_ce(mem1_ce),
		.ram1_oe(mem1_oe),
		.ram1_we(mem1_we),
		
		.spi_miso(FCI_MISO),
		.spi_mosi(FCI_MOSI), 
		.spi_sck(FCI_SCK),
		.spi_ss(spi_ss),
		
		.mcu_busy(mcu_busy),
		.mcu_fifo_rxf(mcu_fifo_rxf),
		.mcu_master(mcu_master),
		.mcu_brm_bc(mcu_brm_bc),
		
		
		.bus_oe(bus_oe),
		.use_irq(use_irq),
		.led_g(led_g),
		.led_r(led_r),
		.btn(!BTNn)
	);
//************************************************************************************* pll
	wire mclk8x;
	
	pll_1 pll_1_inst(
		.inclk0(CLK),
		.c0(mclk8x)
	);
//************************************************************************************* cpu_ce (required for psram)
	wire cpu_ce 		= cpu_pstart | !TG_OEn | !TG_WEn;
	
	reg [4:0]phase;
	reg [3:0]cpu_oe_st;
	reg cpu_pstart;
	
	always @(posedge mclk8x)
	begin
	
		cpu_oe_st[3:0]	<= {cpu_oe_st[2:0], !TG_OEn};
		
		if(cpu_oe_st[2:0] == 'b001)
		begin
			phase			<= 0;
		end
			else
		begin
			phase			<= phase >= 23 ? 0 : phase + 1;
		end
		
		cpu_pstart		<= phase >= 16 | phase <= 2;
		
	end

endmodule
