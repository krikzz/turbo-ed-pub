
module fifo(

	input clk,
	input PiBus pi,
	input PiMap pm,
	input CpuBus cpu,
	input data_ce,
	input stat_ce,
	
	output fifo_rxf_pi,
	output [7:0]dato_cp,
	output [7:0]dato_pi
);
	
	
	assign dato_cp = stat_ce ? fifo_status : fifo_do_a;
	assign dato_pi	= fifo_do_b;

	reg [7:0]fifo_status;
	reg stat_ce_st;
	
	always @(posedge clk)
	begin
	
		stat_ce_st	<= stat_ce;
		
		if(!stat_ce_st)
		begin
			fifo_status <= {fifo_rxf_cp, fifo_rxf_pi, 6'd1};
		end
		
	end
	
	wire fifo_oe_pi = pm.ce_fifo & pi.oe & pi.act;
	wire fifo_we_pi = pm.ce_fifo & pi.we & pi.act;
	
	wire fifo_rxf_cp;
	wire fifo_oe_cp = data_ce & cpu.oe;
	wire fifo_we_cp = data_ce & cpu.we_sync;
	
	//arm to cpu
	wire [7:0]fifo_do_a;
	fifo_buff fifo_a(

		.clk(clk),
		.di(pi.dato),
		.oe(fifo_oe_cp),
		.we(fifo_we_pi),
		.dato(fifo_do_a),
		.fifo_empty(fifo_rxf_cp)
	);
	
	//cpu to arm
	wire [7:0]fifo_do_b;
	fifo_buff fifo_b(

		.clk(clk),
		.di(cpu.data),
		.oe(fifo_oe_pi),
		.we(fifo_we_cp),
		.dato(fifo_do_b),
		.fifo_empty(fifo_rxf_pi)
	);
	

endmodule 


module fifo_buff(

	input clk, 
	input [7:0]di,
	input oe, we,
	
	output [7:0]dato,
	output fifo_empty
);

	
	assign fifo_empty = we_addr == oe_addr;
	
	reg [10:0]we_addr;
	reg [10:0]oe_addr;
	reg [1:0]oe_st, we_st;	
	
	wire oe_end = oe_st[1:0] == 2'b10;
	wire we_end = we_st[1:0] == 2'b10;	
	
	always @(posedge clk)
	begin
	
		oe_st[1:0] <= {oe_st[0], (oe & !fifo_empty)};
		we_st[1:0] <= {we_st[0], we};
		
		if(oe_end)oe_addr <= oe_addr + 1;
		if(we_end)we_addr <= we_addr + 1;
		
	end
	
	
	
	ram_dp fifo_ram(
	
		.clk_a(clk),
		.dati_a(di), 
		.addr_a(we_addr), 
		.we_a(we),
		
		.clk_b(clk),
		.addr_b(oe_addr), 
		.dato_b(dato)
	);

	
endmodule

