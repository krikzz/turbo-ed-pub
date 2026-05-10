
module exp_tnb(//ten no koe 2

	input  ExpIn  exp_i,
	output ExpOut exp_o
);
	
	wire clk;
	CpuBus  cpu;
	MemCtrl brm;
	
	assign cpu			= exp_i.cpu;
	assign clk 			= exp_i.clk;
	assign exp_o.brm	= brm;
	
//******************************************************************************

	assign exp_o.ce			=  exp_o.brm.ce;
	assign exp_o.dato			=	exp_i.brm_dato;
	

	//everyting work just like in cd-unit bram
	assign brm.addr[10:0]	= cpu.addr[10:0];
	assign brm.dati[7:0]		= cpu.data[7:0];
	assign brm.ce				= {cpu.addr[20:11], 11'd0} == 'h1EE000 & ram_on;//2K, bram
	assign brm.oe				= cpu.oe;
	assign brm.we				= cpu.we;
	
	
	wire [3:0]regs_addr		= cpu.addr[3:0];
	wire regs_ce 				= {cpu.addr[20:4],   4'd0} == 'h1FF800;//16B, regs
	wire regs_we				= regs_ce & cpu.we_sync;
	wire regs_oe				= regs_ce & cpu.oe_sync;
	
	reg ram_on;
	
	always @(posedge clk)
	if(exp_i.map_rst | cpu.rst)
	begin
		ram_on	<= 0;
	end
		else
	begin
		
		if(regs_we & regs_addr == 'h7)
		begin
			ram_on	<= cpu.data[7];
		end
		
		if(regs_oe & regs_addr == 'h3)
		begin
			ram_on	<= 0;//not sure if this need
		end
		
	end
	
endmodule
