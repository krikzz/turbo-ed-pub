
module bram(

	input  clk,
	input  brm_on,
	input  brm_bc_on,
	input  cpu_we_sync,
	
	input  MemCtrl exp_brm,
	input  MemCtrl huc_brm,
	output [7:0]brm_dato,

	input  PiBus pi,
	input  pi_ce,
	output [7:0]pi_dato,
	
	output bc_req
);
	
	
	assign pi_dato 		= pi_ce_ack ? {4'hA, mod_state[3:0]} : mem_dato_pi;
	assign bc_req			= mod_state != 0;
			
	wire pi_ce_mem			= pi_ce & pi.addr[15] == 0;
	wire pi_ce_ack			= pi_ce & pi.addr[15] == 1;
	wire pi_we_mem			= pi.we_sync & pi_ce_mem;
	wire pi_we_ack			= pi.we_sync & pi_ce_ack;
	
	
	MemCtrl brm;
	assign brm 				= huc_brm.ce ? huc_brm : exp_brm;
	wire [13:0]brm_addr	= {huc_brm.ce, brm.addr[12:0]};
	wire mem_we_sync		= brm.ce & cpu_we_sync & brm_on;

	reg  [3:0]mod_state;
	
	always @(posedge clk)
	if(!brm_on | !brm_bc_on)
	begin
		mod_state	<= 0;
	end
		else
	begin
		
		if(mem_we_sync & brm_addr[13] == 0)
		begin
			mod_state[1:0]	<= 'b11;
		end
			else
		if(pi_we_ack)
		begin
			mod_state[1:0]		<= mod_state[1:0]	& pi.dato[1:0]; 
		end
		
		if(mem_we_sync & brm_addr[13] == 1)
		begin
			mod_state[3:2]	<= 'b11;
		end
			else
		if(pi_we_ack)
		begin
			mod_state[3:2]		<= mod_state[3:2]	& pi.dato[3:2]; 
		end
		
	end
	
	//16K total
	//0x0000: exp bram 2K
	//0x2000: huc bram 8K
	wire [7:0]mem_dato_pi;
	
	ram_dp ram_dp_inst(

		.clk_a(clk),
		.dati_a(brm.dati),
		.addr_a(brm_addr[13:0]),
		.we_a(mem_we_sync),
		.dato_a(brm_dato),
		
		.clk_b(clk),
		.dati_b(pi.dato),
		.addr_b(pi.addr[13:0]),
		.we_b(pi_we_mem),
		.dato_b(mem_dato_pi)
	);

endmodule
