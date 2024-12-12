

module pi_io(//mcu to fpga serial interface
	
	input  clk,
	
	input  spi_sck,
	input  spi_ss,
	input  spi_mosi,
	output spi_miso,
	
	input  [7:0]dati,
	output PiBus pi
	
);

	parameter CMD_MEM_WR	= 8'hA0;
	parameter CMD_MEM_RD	= 8'hA1;
	
	
	assign spi_miso 		= !spi_ss ? sout[7] : 1'bz;
	assign pi.oe 			= cmd[7:0] == CMD_MEM_RD & exec;
	assign pi.we 			= cmd[7:0] == CMD_MEM_WR & exec;
	assign pi.we_sync		= pi_we_st[2:0] == 'b001;
	assign pi.oe_sync		= pi_oe_st[2:0] == 'b001;
	
	reg [7:0]sin;
	reg [7:0]sout;
	reg [2:0]bit_ctr;
	reg [7:0]cmd;
	reg [3:0]byte_ctr;
	reg [7:0]rd_buff;
	reg wr_ok;
	reg exec;

	
	always @(posedge spi_sck)
	begin
		sin[7:0] <= {sin[6:0], spi_mosi};
	end
	
	
	always @(negedge spi_sck)
	if(spi_ss)
	begin
		cmd[7:0] 		<= 8'h00;
		sout[7:0] 		<= 8'hff;
		bit_ctr[2:0] 	<= 3'd0;
		byte_ctr[3:0] 	<= 4'd0;
		pi.act 			<= 0;
		wr_ok 			<= 0;
		exec 				<= 0;
	end
		else
	begin
		
		
		bit_ctr <= bit_ctr + 1;
				
		
		if(bit_ctr == 7 & !exec)
		begin
			if(byte_ctr[3:0] == 4'd0)cmd[7:0] 			<= sin[7:0];
			if(byte_ctr[3:0] == 4'd1)pi.addr[7:0] 		<= sin[7:0];
			if(byte_ctr[3:0] == 4'd2)pi.addr[15:8] 	<= sin[7:0];
			if(byte_ctr[3:0] == 4'd3)pi.addr[23:16] 	<= sin[7:0];
			if(byte_ctr[3:0] == 4'd4)pi.addr[31:24] 	<= sin[7:0];
			if(byte_ctr[3:0] == 4'd4)exec 				<= 1;
			byte_ctr 											<= byte_ctr + 1;
		end
		
		
		
		if(cmd[7:0] == CMD_MEM_WR & exec)
		begin
			if(bit_ctr == 7)pi.dato[7:0] 		<= sin[7:0];
			if(bit_ctr == 7)wr_ok 				<= 1;
			if(bit_ctr == 0 & wr_ok)pi.act 	<= 1;
			if(bit_ctr == 5 & wr_ok)pi.act 	<= 0;
			if(bit_ctr == 6 & wr_ok)pi.addr 	<= pi.addr + 1;
		end

		
		if(cmd[7:0] == CMD_MEM_RD & exec)
		begin
			if(bit_ctr == 1)pi.act 			<= 1;
			if(bit_ctr == 5)rd_buff[7:0] 	<= dati[7:0];
			if(bit_ctr == 5)pi.act 			<= 0;//should not release on last cycle. otherwise spi clocked thing may not work properly
			if(bit_ctr == 6)pi.addr 		<= pi.addr + 1;
			if(bit_ctr == 7)sout[7:0] 		<= rd_buff[7:0];
			
			if(bit_ctr != 7)sout[7:0] 		<= {sout[6:0], 1'b1};
		end
		
	end
	
	
	reg [2:0]pi_we_st;
	reg [2:0]pi_oe_st;
	
	always @(posedge clk)
	begin
		pi_we_st[2:0] <= {pi_we_st[1:0], pi.we & pi.act};
		pi_oe_st[2:0] <= {pi_oe_st[1:0], pi.oe & pi.act};
	end
	
endmodule
