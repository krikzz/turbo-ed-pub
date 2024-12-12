
module huc_pop(//populous mapper

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
	
	assign huc_o.cart_ce		= rom.ce | ram.ce;
	assign huc_o.cart_dato	= rom.ce ? huc_i.rom_dato : huc_i.ram_dato;
//************************************************************************************* 
	
	assign rom.dati	= cpu.data;
	assign rom.addr	= cpu.addr[19:0];
	assign rom.ce2		= cpu.ce;
	assign rom.ce		= cpu.addr[20:19] == 0;
	assign rom.oe		= cpu.oe;
	assign rom.we		= 0;
	
	assign ram.dati	= cpu.data;
	assign ram.addr	= cpu.addr[14:0];
	assign ram.ce2		= cpu.ce;
	assign ram.ce		= cpu.addr[20:19] == 1;
	assign ram.oe		= cpu.oe;
	assign ram.we		= cpu.we;
	
	
endmodule
