


module everdrive(
	
	input  clk,
	
	output [7:0]cpu_dati,
	input  [7:0]cpu_dato,
	input  [20:0]cpu_addr,
	input  cpu_oe_n, 
	input  cpu_we_n,
	input  cpu_hsm,
	input  cpu_ce,
	output cpu_irq_n,
	output cpu_rst_n,
	output cpu_cart_n,
	

	output [7:0]ram0_dati,
	input  [7:0]ram0_dato,
	output [22:0]ram0_addr,
	output ram0_ce,
	output ram0_oe,
	output ram0_we,
	
	output [7:0]ram1_dati,
	input  [7:0]ram1_dato,
	output [22:0]ram1_addr,
	output ram1_ce,
	output ram1_oe,
	output ram1_we,
	
	output spi_miso,
	input  spi_mosi, 
	input  spi_sck,
	input  spi_ss,
	
	input  mcu_busy,
	output mcu_fifo_rxf,
	output mcu_master,
	output mcu_brm_bc,
	
	output dac_mclk, 
	output dac_lrck, 
	output dac_sclk, 
	output dac_sdin,
	
	output bus_oe,
	output use_irq,
	output led_g,
	output led_r,
	input  btn
);	
	
	SysCfg cfg;
	CpuBus cpu;
//****************************************************************************** mem ctrl	
	DmaBus  dma;
	MemCtrl mio_mem;
	MemCtrl ram0;
	MemCtrl ram1;
	MemCtrl mem_off;
	
	MemCtrl huc_rom;
	MemCtrl huc_ram;
	
	MemCtrl exp_ram;
	MemCtrl exp_adp;
	
	wire huc_rom_ce0		= huc_rom.ce & huc_rom.addr[23] == 0;
	wire huc_rom_ce1		= huc_rom.ce & huc_rom.addr[23] == 1;
	wire exp_adp_ce1		= exp_adp.ce & !sst_act;
	
	
	assign ram0 			=
	dma.req_ram0	? dma.mem :
	mio_ce0			? mio_mem :
	huc_rom_ce0		? huc_rom :
	huc_ram.ce		? huc_ram : 
	exp_ram.ce  	? exp_ram :
	mem_off;
	
	assign ram1				= 
	dma.req_ram1 	? dma.mem :
	mio_ce1			? mio_mem :
	huc_rom_ce1		? huc_rom :
	exp_adp_ce1		? exp_adp :
	mem_off;
	
	
	wire [22:0]ram0_map	= 
	dma.req_ram0 	? 'h000000 :
	mio_ce0			? 'h000000 :
	huc_rom_ce0  	? 'h000000 :
	huc_ram.ce  	? 'h400000 ://2M+192K
	exp_ram.ce  	? 'h640000 ://64K
	0;
	
	wire [22:0]ram1_map	= 
	dma.req_ram1 	? 'h000000 :
	mio_ce1			? 'h000000 :
	huc_rom_ce1  	? 'h000000 :
	exp_adp.ce  	? 'h400000 ://64K
	0;	

	assign ram0_dati		= ram0.dati;
	assign ram0_addr		= ram0.addr | ram0_map;
	assign ram0_oe			= ram0.oe;
	assign ram0_we			= ram0.we;
	assign ram0_ce			= ram0.ce & ram0.ce2;
	
	assign ram1_dati		= ram1.dati;
	assign ram1_addr		= ram1.addr | ram1_map;
	assign ram1_oe			= ram1.oe;
	assign ram1_we			= ram1.we;
	assign ram1_ce			= ram1.ce & ram1.ce2;
//****************************************************************************** cpu bus
	wire cpu_irq;
	
	assign cpu_irq_n 		= !hub_irq;
	assign cpu_rst_n 		= !rst_cpu;
	assign cpu_cart_n		= cfg.ct_cart_off;
	
	cpu_io cpu_io_inst(
	
		.clk(clk),		
		.cpu_dato(cpu_dato),
		.cpu_addr(cpu_addr),
		.cpu_oe_n(cpu_oe_n), 
		.cpu_we_n(cpu_we_n),
		.cpu_hsm(cpu_hsm),
		.cpu_irq_n(cpu_irq_n),
		.cpu_rst_n(cpu_rst_n),
		.cpu_ce(cpu_ce),
		
		.cpu(cpu)
	);

	assign cpu_dati[7:0]	= 
	reg_ce ? reg_dato :
	cc_ce  ? cc_dato  :
	huc_ce ? huc_dato :
	exp_ce ? exp_dato :
	8'hff;
	
	assign bus_oe			= cpu.oe & (reg_ce | huc_ce | exp_ce | cc_ce);
//****************************************************************************** system regs
	wire reg_ce 			= {cpu.addr[20:4], 4'd0} == 'h1ffff0;
	
	wire [7:0]reg_dato	= 
	reg_ce_fdat	? fifo_dato_cp :
	reg_ce_fsta	? fifo_dato_cp :
	reg_ce_syss	? status_dato :
	reg_ce_time	? timer_dato :
	reg_ce_mdat ? mio_dato :
	reg_ce_sstd ? sst_dato :
	reg_ce_ssta	? sst_dato :
	'hff;
	
	
	wire reg_ce_fdat = reg_ce & (cpu.addr[3:0] == 'h0 | cpu.addr[3:0] == 'h1); //fifo data
	wire reg_ce_fsta = reg_ce &  cpu.addr[3:0] == 'h2; //fofo status
	wire reg_ce_syss = reg_ce &  cpu.addr[3:0] == 'h3; //sys status
	wire reg_ce_time = reg_ce & (cpu.addr[3:0] == 'h4 | cpu.addr[3:0] == 'h5);
	wire reg_ce_mdat = reg_ce & (cpu.addr[3:0] == 'h6 | cpu.addr[3:0] == 'h7); //ram io data
	wire reg_ce_madr = reg_ce & (cpu.addr[3:0] == 'h8 | cpu.addr[3:0] == 'h9); //ram io addr
	wire reg_ce_sstd = reg_ce & (cpu.addr[3:0] == 'hA | cpu.addr[3:0] == 'hB); //sst data and sst exit request
	wire reg_ce_ssta = reg_ce & (cpu.addr[3:0] == 'hC | cpu.addr[3:0] == 'hD); //w:sst addr, r:A+tam1
//****************************************************************************** timer
	wire [7:0]timer_dato;
	
	timer timer_inst(

		.clk(clk),
		.a0(cpu.addr[0]),
		.timer_latch(reg_ce_time & cpu.we_sync),
		.timer_dato(timer_dato)
	);
//****************************************************************************** status	
	wire [7:0]status_dato;
	
	sys_status sys_status_inst(

		.clk(clk),
		.cpu(cpu),
		.stat_ce(reg_ce_syss),
		.mcu_busy(mcu_busy),
		
		.dato(status_dato)
	);
//****************************************************************************** pi	
	PiMap pm;
	PiBus pi;
	
	wire [7:0]pi_dati = 
	dma.mem_req ? dma.pi_data :
	pm.ce_fifo 	? fifo_dato_pi : 
	pm.ce_exp	? exp_dato_pi :
	pm.ce_brm	? brm_dato_pi :
	8'hff;
	
	pi_io pi_io_inst(
	
		.clk(clk),
		
		.spi_sck(spi_sck),
		.spi_ss(spi_ss),
		.spi_mosi(spi_mosi),
		.spi_miso(spi_miso),
		
		.dati(pi_dati),
		.pi(pi)
		
	);
	
	pi_map pi_map_inst(

		.pi(pi),
		.pm(pm)
	);
//****************************************************************************** fifo
	wire [7:0]fifo_dato_cp;
	wire [7:0]fifo_dato_pi;
	
	fifo fifo_inst(

		.clk(clk),
		.pi(pi),
		.pm(pm),
		.cpu(cpu),
		.data_ce(reg_ce_fdat),
		.stat_ce(reg_ce_fsta),
		
		.fifo_rxf_pi(mcu_fifo_rxf),
		.dato_cp(fifo_dato_cp),
		.dato_pi(fifo_dato_pi)
	);
//****************************************************************************** dma
	
	dma_io dma_io_inst( 

		.pi(pi),
		.pm(pm),
		.ram0_do(ram0_dato),
		.ram1_do(ram1_dato),
		
		.dma(dma)
	);
//****************************************************************************** sys cfg	
	sys_cfg sys_cfg_inst(

		.clk(clk),
		.rst(rst_cfg),
		.pi(pi),
		.pm(pm),
		
		.cfg(cfg)
	);
//****************************************************************************** rst ctrl
	wire rst_cpu;
	wire rst_cfg;
	
	rst_ctrl rst_ctrl_inst(

		.clk(clk),
		.btn(btn_filt),
		.rst_delay(cfg.ct_rst_dl),
		.sst_on(sst_on),
		
		.rst_cpu(rst_cpu),
		.rst_cfg(rst_cfg)
	);
//****************************************************************************** dac
	DacSC  dsc;
	DacIn  dac_exp;
	
	audio audio_inst(
		
		.clk(clk),
		.dsc(dsc),
		.dac(dac_exp),
		.stereo(cfg.ct_stereo),
		.cart_off(cfg.ct_cart_off),
		.mute(sst_act),
		.vol_l(cfg.vol_l),
		.vol_r(cfg.vol_r),
		
		.mclk(dac_mclk), 
		.lrck(dac_lrck),
		.sclk(dac_sclk),
		.sdin(dac_sdin)
	);
//****************************************************************************** hu cards
	parameter HUC_SYS 		= 0;
	
	MemCtrl huc_brm;
	HucOut huc_o;
	HucIn  huc_i;
	
	assign huc_i.clk 			= clk;
	assign huc_i.map_rst		= sys_act;
	assign huc_i.rom_dato 	= huc_rom.addr[23] == 0 ? ram0_dato : ram1_dato;
	assign huc_i.ram_dato 	= ram0_dato;
	assign huc_i.brm_dato 	= brm_dato;
	assign huc_i.cpu 			= cpu;
	assign huc_i.region		= cfg.huc_region;
	
	assign huc_rom				= huc_o.rom;
	assign huc_ram				= huc_o.ram;
	assign huc_brm				= huc_o.brm;
	
	wire huc_ce					= huc_o.cart_ce;
	wire [7:0]huc_dato		= huc_o.cart_dato;
	HucOut huc_o_hub;
	
	huc_hub huc_hub_inst(
	
		.cfg(cfg),
		.huc_i(huc_i),
		.huc_o(huc_o_hub)
	);
	
	
	HucOut huc_o_sys;
	huc_sys huc_sys_inst(.huc_i(huc_i),.huc_o(huc_o_sys));
	
	assign huc_o =
	sys_act	? huc_o_sys :
	sst_act	? huc_o_sys :
	huc_o_hub;
	
	wire sys_act	= cfg.huc_type == HUC_SYS;//cart menu mode
//****************************************************************************** exp cards
	MemCtrl exp_brm;
	ExpOut exp_o;
	ExpIn  exp_i;
	wire hub_irq;
	
	assign exp_i.clk 			= clk;
	assign exp_i.map_rst		= cfg.exp_type == 0;
	assign exp_i.pi_ce		= pm.ce_exp;
	assign exp_i.ram_dato 	= ram0_dato;
	assign exp_i.brm_dato 	= brm_dato;
	assign exp_i.adp_dato 	= ram1_dato;
	assign exp_i.cpu 			= cpu;
	assign exp_i.pi			= pi;
	assign exp_i.sst_act		= sst_act;
	assign exp_i.dsc 			= dsc;
	
	assign exp_ram				= exp_o.ram;
	assign exp_brm				= exp_o.brm;
	assign exp_adp				= exp_o.adp;
	assign mcu_master			= exp_o.mcu_master & !sst_act;
	assign hub_irq				= exp_o.irq | huc_o.irq;
	assign dac_exp				= exp_o.dac;
	assign use_irq				= exp_o.use_irq;
	
	wire exp_ce					= exp_o.ce;
	wire [7:0]exp_dato		= exp_o.dato;
	wire [7:0]exp_dato_pi	= exp_o.pi_data;
	
	exp_hub exp_hub_inst(

		.cfg(cfg),
		.exp_i(exp_i),
		.exp_o(exp_o)
	);
//****************************************************************************** bram
	assign mcu_brm_bc = bc_req;
	
	wire [7:0]brm_dato;
	wire [7:0]brm_dato_pi;
	wire bc_req;
	
	bram bram_inst(

		.clk(clk),
		.brm_on(cfg.ct_brm_on),
		.brm_bc_on(!sys_act),//for menu diagnostics
		.cpu_we_sync(cpu.we_sync),
		
		.exp_brm(exp_brm),
		.huc_brm(huc_brm),
		.brm_dato(brm_dato),
		
		.pi(pi),
		.pi_ce(pm.ce_brm),
		.pi_dato(brm_dato_pi),
		.bc_req(bc_req)
	);
//****************************************************************************** memory io (mem access via REG_MEM_DATA/REG_MEM_ADDR)
	wire mio_ce0;
	wire mio_ce1;
	wire [7:0]mio_dato;
	
	mem_io mem_io_inst(
	
		.clk(clk),
		.cpu(cpu),
		.ce_data(reg_ce_mdat),
		.ce_addr(reg_ce_madr),
		
		.mem0_dato(ram0_dato),
		.mem1_dato(ram1_dato),
		.mem(mio_mem),
		.mem_ce0(mio_ce0),
		.mem_ce1(mio_ce1),
		.dato(mio_dato)
	);
//****************************************************************************** save states
	wire [7:0]sst_dato;
	wire sst_act;
	wire sst_on = cfg.ct_sst_on & !sys_act;
	
`ifdef USE_SST

	sst sst_inst(

		.clk(clk),
		.cpu(cpu),
		.sst_on(sst_on),
		.sst_req_bnt(btn_filt & cfg.ct_rst_dl),
		.sst_ce_addr(reg_ce_ssta),
		.sst_ce_data(reg_ce_sstd),
		.key_save(cfg.key_save),
		.key_load(cfg.key_load),
		.key_menu(cfg.key_menu),
		
		.sst_dato(sst_dato),
		.sst_act(sst_act)
	);
`endif	
//****************************************************************************** cheats	
	wire [7:0]cc_dato;
	wire cc_ce;
	wire cc_on	= cfg.ct_cc_on & !sys_act & !sst_act;

`ifdef USE_CHEATS
	
	cheats cheats_inst(
	
		.clk(clk),
		.cheats_on(cc_on),
		.cpu(cpu),
		.pi(pi),
		.pm(pm),
		
		.cc_dato(cc_dato),
		.cc_ce(cc_ce)
	);
	
`endif	
//****************************************************************************** var
	
	led_ctrl led_inst_g(
		.clk(clk),
		.led_i(exp_o.led | huc_o.led | sst_act | rst_cfg),
		.led_o(led_g),
	);
	
	led_ctrl led_inst_r(
		.clk(clk),
		.led_i(bc_req),
		.led_o(led_r),
	);
	
	
	wire btn_filt;
	
	btn_filter btn_filter_inst(

		.clk(clk),
		.btn_i(btn),
		.btn_o(btn_filt)
	);
	
endmodule


