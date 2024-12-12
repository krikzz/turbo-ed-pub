
module sys_cfg(

	input  clk,
	input  rst,
	input  PiBus pi,
	input  PiMap pm,
	
	output SysCfg cfg
);
	
	initial cfg.vol_l = 255;
	initial cfg.vol_r = 255;
	
	always @(posedge clk)
	if(rst)
	begin
		cfg.huc_type			<= 0;
		cfg.exp_type			<= 0;
	end
		else
	if(pi.we_sync & pm.ce_cfg)
	case(pi.addr[2:0])
		
		0:begin
			cfg.ct_rst_dl		<= pi.dato[0];
			cfg.ct_brm_on		<= pi.dato[1];
			cfg.ct_sst_on		<= pi.dato[2];
			cfg.ct_cc_on		<= pi.dato[3];
			cfg.ct_stereo		<= pi.dato[4];//
			cfg.ct_cart_off	<= pi.dato[6] ? pi.dato[5] : cfg.ct_cart_off;//can be modified only if pi.dato[6]. prevents changes during regs reset
		end
		1:begin
			cfg.key_save		<= pi.dato;
		end
		2:begin
			cfg.key_load		<= pi.dato;
		end
		3:begin
			cfg.key_menu		<= pi.dato;
		end
		4:begin
			cfg.vol_l			<= pi.dato;
		end
		5:begin
			cfg.vol_r			<= pi.dato;
		end
		6:begin
			cfg.exp_type		<= pi.dato;
		end
		7:begin
			cfg.huc_region		<= pi.dato[7];
			cfg.huc_type		<= pi.dato;
		end
		
	endcase
	
	
endmodule
