
module huc_sf2(//street fighter mapper

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
	assign rom.addr	= rom_x;
	assign rom.ce2		= cpu.ce;
	assign rom.ce		= cpu.addr[20] == 0;
	assign rom.oe		= cpu.oe;
	assign rom.we		= 0;
	
	
	wire [22:0]rom_x	= !cpu.addr[19] ? rom_a : rom_b + 'h80000;
	wire [22:0]rom_a 	= cpu.addr[18:0];
	wire [22:0]rom_b	= {bank[3:0], cpu.addr[18:0]};
	
	wire regs_we 		= cpu.we_sync & {cpu.addr[20:4], 4'b0000} == 'h1ff0;
	
	
	reg [3:0]bank;
	
	always @(posedge clk)
	if(huc_i.map_rst | cpu.rst)
	begin
		bank	<= 0;
	end
		else
	if(regs_we)
	begin
		bank	<= cpu.addr;
	end
	
endmodule
