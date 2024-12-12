
module huc_hub(//hucards list
	
	input  SysCfg cfg,
	input  HucIn  huc_i,
	output HucOut huc_o
);

	parameter HUC_SYS = 'h0;
	parameter HUC_USR = 'h1;
	parameter HUC_STD = 'h2;
	parameter HUC_SF2 = 'h3;
	parameter HUC_POP = 'h4;
	parameter HUC_384 = 'h5;
	parameter HUC_TNB = 'h6;
	parameter HUC_SCA = 'h8;
	parameter HUC_SSC = 'h9;
	parameter HUC_ARC = 'hA;
	
	
	HucOut huc_o_nom;
	huc_nom huc_nom_inst(.huc_i(huc_i),.huc_o(huc_o_nom));
	
	HucOut huc_o_std;
	huc_std huc_std_inst(.huc_i(huc_i),.huc_o(huc_o_std));
	
	HucOut huc_o_384;
	huc_384 huc_384_inst(.huc_i(huc_i),.huc_o(huc_o_384));
	
	HucOut huc_o_ssc;
	huc_ssc huc_ssc_inst(.huc_i(huc_i),.huc_o(huc_o_ssc));
	
	//HucOut huc_o_arc;
	//huc_arc huc_arc_inst(.huc_i(huc_i),.huc_o(huc_o_arc));
	
	HucOut huc_o_sf2;
	huc_sf2 huc_sf2_inst(.huc_i(huc_i),.huc_o(huc_o_sf2));
	
	HucOut huc_o_pop;
	huc_pop huc_pop_inst(.huc_i(huc_i),.huc_o(huc_o_pop));
	
	assign huc_o = 
	cfg.huc_type == HUC_STD ? huc_o_std :
	cfg.huc_type == HUC_384 ? huc_o_384 :
	cfg.huc_type == HUC_SCA ? huc_o_std :
	cfg.huc_type == HUC_SSC ? huc_o_ssc :
	//cfg.huc_type == HUC_ARC ? huc_o_arc :
	cfg.huc_type == HUC_SF2 ? huc_o_sf2 :
	cfg.huc_type == HUC_POP ? huc_o_pop :
	huc_o_nom;//no mapper
	
endmodule
