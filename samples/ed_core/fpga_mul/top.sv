
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
	
//************************************************************************************* initialization for unused stuff
	assign FCI_IO_3 			= 1;//mcu_mode mcu master mode (unused, should be 1)
	assign FCI_IO_5			= 1;//mcu_brm_n
	assign FCI_IO_1			= 1;//mcu_fifo_rxf
	
	assign TG_DOEn				= 0;//bus output always enabled
	assign TG_IRQ2n			= 1'bz;
	assign LED_FPGn			= 1'bz;//blinking led
	
//************************************************************************************* cpu data bus assigments
	wire region					= FCI_IO_4;
	assign TG_D[7:0]			= !bus_oe ? 8'hzz : region ? cpu_dati_tg : cpu_dati_pc;
	assign TG_DDIR 			= bus_oe;//data bus direction

	wire bus_oe					= TG_A[20] == 0 & !TG_OEn;
	wire [7:0]cpu_dati_pc	= cpu_dati;
	wire [7:0]cpu_dati_tg	= {cpu_dati[0],cpu_dati[1],cpu_dati[2],cpu_dati[3],cpu_dati[4],cpu_dati[5],cpu_dati[6],cpu_dati[7]};
	
	wire [7:0]cpu_dato_pc	= TG_D[7:0];
	wire [7:0]cpu_dato_tg	= {TG_D[0],TG_D[1],TG_D[2],TG_D[3],TG_D[4],TG_D[5],TG_D[6],TG_D[7]};
	
	wire [7:0]cpu_dati		= mul_ce ? mul_8 : TG_A[0] == 0 ? PSR_D[15:8] : PSR_D[7:0];
	wire [7:0]cpu_dato 		= region ? cpu_dato_tg : cpu_dato_pc;
//************************************************************************************* memory assigments
	assign PSR_A[18:0] 		= TG_A[19:1];
	assign PSR_D[15:0] 		= !PSR_OEn ? 16'hzzzz : {cpu_dati[7:0], cpu_dati[7:0]};
	assign PSR_CEn 			= TG_A[20] == 0 & (!TG_OEn | !TG_WEn) ? 0 : 1;
	assign PSR_OEn 			= TG_OEn;
	assign PSR_WEn 			= TG_WEn;
	assign PSR_UBn 			= TG_A[0] == 0 ? 0 : 1;
	assign PSR_LBn 			= TG_A[0] == 1 ? 0 : 1;
//************************************************************************************* reset control
	assign FCI_IO_6 			= BTNn;//mcu_rst return to menu request for mcu
	assign TG_RSTFn			= rst_ctr[23];//system cpu reset
	
	
	reg [23:0]rst_ctr;
	reg btn_n_st;
	
	always @(posedge CLK)
	begin
		
		btn_n_st		<= BTNn;
		
		if(btn_n_st == 0)
		begin
			rst_ctr	<= 0;
		end
			else
		if(rst_ctr[23] == 0)
		begin
			rst_ctr	<= rst_ctr + 1;//initial system reset
		end
		
	end
//************************************************************************************* hv multiplier

	wire mul_ce 		= {TG_A[20:3], 3'b0} == 21'hFFFF8;//map multiplier registers to the last 8 bytes of rom space
	wire mul_we 		= mul_ce & !TG_WEn;
	
	wire [31:0]mul_32	=	mul_arg_0 * mul_arg_1;
	
	wire [7:0]mul_8	=  
	TG_A[1:0] == 0 ? mul_32[7:0]   : 
	TG_A[1:0] == 1 ? mul_32[15:8]  : 
	TG_A[1:0] == 2 ? mul_32[23:16] : mul_32[31:24];
	
	reg [31:0]mul_arg_0;
	reg [31:0]mul_arg_1;
	
	always @(negedge mul_we)
	case(TG_A[2:0])
		0:mul_arg_0[7:0]		<= cpu_dato;
		1:mul_arg_0[15:8]		<= cpu_dato;
		2:mul_arg_0[23:16]	<= cpu_dato;
		3:mul_arg_0[31:24]	<= cpu_dato;
		4:mul_arg_1[7:0]		<= cpu_dato;
		5:mul_arg_1[15:8]		<= cpu_dato;
		6:mul_arg_1[23:16]	<= cpu_dato;
		7:mul_arg_1[31:24]	<= cpu_dato;
	endcase
	
	
endmodule
