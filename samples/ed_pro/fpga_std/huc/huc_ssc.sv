
module huc_ssc(//super system card

	input  HucIn  huc_i,
	output HucOut huc_o
);
	wire clk;
	CpuBus cpu;
	MemCtrl rom;
	MemCtrl ram;
	
	assign clk 			= huc_i.clk;
	assign cpu 			= huc_i.cpu;	
	
	assign huc_o.rom 	= rom;
	assign huc_o.ram 	= ram;
	
	assign huc_o.cart_ce		= reg_ce | rom.ce | ram.ce;
	assign huc_o.cart_dato	= reg_ce ? regs_do : rom.ce ? huc_i.rom_dato : huc_i.ram_dato;
//************************************************************************************* 
	
	assign rom.dati	= cpu.data;
	assign rom.addr	= cpu.addr[19:0];
	assign rom.ce2		= cpu.ce;
	assign rom.ce		= cpu.addr[20:19] == 0;
	assign rom.oe		= cpu.oe;
	assign rom.we		= 0;
	
	assign ram.dati	= cpu.data;
	assign ram.addr	= cpu.addr[17:0];
	assign ram.ce2		= cpu.ce;
	assign ram.ce		= {cpu.addr[20:18], 18'd0} == 'h0C0000 & cpu.addr[17:16] != 0;//192K
	assign ram.oe		= cpu.oe;
	assign ram.we		= cpu.we;
	
	
	
	//super system cart detection regs
	wire reg_ce			= {cpu.addr[20:3],   3'd0} == 'h1FF8C0;//8B, regs;
	
	wire [7:0]regs_do =
	cpu.addr[2:0] == 1 ? 8'haa : 
	cpu.addr[2:0] == 2 ? 8'h55 : 
	cpu.addr[2:0] == 3 ? 8'h00 : 
	cpu.addr[2:0] == 5 ? (huc_i.region ? 8'h55 :8'haa) :
	cpu.addr[2:0] == 6 ? (huc_i.region ? 8'haa :8'h55) :
	cpu.addr[2:0] == 7 ? (huc_i.region ? 8'hc0 :8'h03) :
	8'hff;
	
endmodule
