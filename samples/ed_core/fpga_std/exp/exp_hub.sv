
module exp_hub(//expansion port devices list

	input  SysCfg cfg,
	input  ExpIn  exp_i,
	output ExpOut exp_o
);

	
	parameter EXP_OFF = 0;
	parameter EXP_CDR = 1;
	parameter EXP_TNB = 2;
	
	ExpOut  exp_o_off;

`ifdef HWC_CDROM_ON	
	ExpOut  exp_o_cdr;
	exp_cdr exp_cdr_inst(.exp_i(exp_i),.exp_o(exp_o_cdr));
`elsif HWC_CDROM_OFF
	ExpOut  exp_o_cdr;
	assign exp_o_cdr 	= exp_o_off;
`else
	"undefined hardware config"
`endif
	
	ExpOut  exp_o_tnb;
	exp_tnb exp_tnb_inst(.exp_i(exp_i),.exp_o(exp_o_tnb));
	
	assign exp_o =
	cfg.exp_type == EXP_CDR ? exp_o_cdr :
	cfg.exp_type == EXP_TNB ? exp_o_tnb :
	exp_o_off;
	
endmodule
