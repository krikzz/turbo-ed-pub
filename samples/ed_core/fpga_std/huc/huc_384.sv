
module huc_384(//hucard with dual rom 256+128K

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
	assign rom.addr	= cpu.addr[19] == 0 ? rom_a : rom_b;
	assign rom.ce2		= cpu.ce;
	assign rom.ce		= cpu.addr[20] == 0;
	assign rom.oe		= cpu.oe;
	assign rom.we		= 0;
	
	wire [18:0]rom_a	= {1'b0,  cpu.addr[17:0]};//256K rom in 512K window
	wire [18:0]rom_b	= {2'b10, cpu.addr[16:0]};//128K rom in 512K window
	
endmodule
