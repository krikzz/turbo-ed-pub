
//****************************************************************************** 
module audio(

	input  clk,
	output DacSC dsc,
	input  DacIn dac,
	input  stereo,
	input  cart_off,
	input  mute,
	input  [7:0]vol_l,
	input  [7:0]vol_r,
	
	output mclk, 
	output lrck,
	output sclk,
	output sdin
);	
	
	wire signed [15:0]snd_l_vc;// = dac.snd_on ? 32000 : 0;
	vol_ctrl vol_ctrl_l(

		.clk(clk),
		.next_sample(dsc.next_sample),
		.vol(vol_l + 1),
		
		.vol_i(dac.snd_l),
		.vol_o(snd_l_vc)
	);
	
	
	wire signed [15:0]snd_r_vc;// = dac.snd_on ? -32000 : 0;
	vol_ctrl vol_ctrl_r(

		.clk(clk),
		.next_sample(dsc.next_sample),
		.vol(vol_r + 1),
		
		.vol_i(dac.snd_r),
		.vol_o(snd_r_vc)
	);
	
		
	wire signed [15:0]snd_l_mc;
	mute_snd mute_l(

		.clk(clk),
		.mute(!dac.snd_on | mute),
		.next_sample(dsc.next_sample),
		.snd_i(snd_l_vc),
		.snd_o(snd_l_mc)
	);
	
	wire signed [15:0]snd_r_mc;
	mute_snd mute_r(

		.clk(clk),
		.mute(!dac.snd_on | mute | !cart_off),
		.next_sample(dsc.next_sample),
		.snd_i(snd_r_vc),
		.snd_o(snd_r_mc)
	);
	

	
	wire signed[15:0]snd_m		= (snd_l_mc + snd_r_mc) / 2;
	
	wire signed[15:0]dac_l 		= stereo ? snd_l_mc : snd_m;
	wire signed[15:0]dac_r 		= stereo ? snd_r_mc : snd_m;
	
	
	dac_cs4344 dac_inst(
		
		.clk(clk),
		.dac_clk(dac.uclk_act ? dac.uclk : dac_clk_std),
		.dsc(dsc),
		.snd_l(dac_l),
		.snd_r(dac_r),
		
		.mclk(mclk), 
		.lrck(lrck),
		.sclk(sclk),
		.sdin(sdin)
	);
	
	
	wire dac_clk_std;
	
	clk_dvp clk_dvp_inst(

		.clk(clk),
		.rst(0),
		.ck_base(50000000),
		.ck_targ(44100*512),
		.ck_out(dac_clk_std)
	);
	
endmodule
//****************************************************************************** cs4344
module dac_cs4344(
	
	input clk,
	input dac_clk,
	input signed [15:0]snd_l,
	input signed [15:0]snd_r,
	
	output DacSC dsc,
	output mclk, 
	output lrck,
	output sclk,
	output sdin
);
//**********************************	
	assign mclk 		= phase[0];
	assign sclk 		= 1;
	assign lrck 		= phase[8];
	assign sdin 		= vol_bit;
	
	wire next_bit 		= phase[3:0] == 4'b1111;
	wire [3:0]bit_ctr = phase[7:4];

	
	reg vol_bit;
	reg signed[15:0]vol_r, vol_l;	
	
	always @(negedge clk)
	if(dsc.clk)
	begin
		
		if(next_bit & lrck == 0)
		begin
			vol_bit		<= vol_l[15 - bit_ctr[3:0]];
		end

		if(next_bit & lrck == 1)
		begin
			vol_bit 		<= vol_r[15 - bit_ctr[3:0]];
		end

		
		if(dsc.next_sample)
		begin
			vol_l 	<= snd_l;
			vol_r 	<= snd_r;
		end

	end
//**********************************	
	assign dsc.next_byte		= dsc.clk & phase[6:0] == 0;//fetch bytes at phase 0,128,256,384
	assign dsc.next_sample	= dsc.clk & phase[8:0] == 511;
	assign dsc.clk				= dac_clk;
	
	reg [8:0]phase;
	
	always @(posedge clk)
	if(dsc.clk)
	begin
		phase	<= phase + 1;
	end
	
endmodule
//****************************************************************************** mute
module mute_snd(

	input  clk,
	input  mute,
	input  next_sample,
	
	input  signed [15:0]snd_i,
	output signed [15:0]snd_o
);

	reg signed [15:0]snd_cur;
	reg signed [9:0]vol;
	reg [7:0]delay;
	
	always @(posedge clk)
	if(next_sample)
	begin
	
		snd_o	<= snd_cur * vol / 256;
		
		if(!mute)
		begin
			snd_cur	<= snd_i;
		end
		
		
		if(delay != 0)
		begin
			delay	<= delay - 1;
		end
			else
		if(mute & vol != 0)
		begin
			delay	<= 4;
			vol	<= vol - 1;
		end
			else
		if(!mute & vol != 256)
		begin
			delay	<= 4;
			vol	<= vol + 1;
		end
		
	end

endmodule

//******************************* vol ctrl
module vol_ctrl(

	input  clk,
	input  next_sample,
	input  signed[9:0]vol,
	
	input  signed[15:0]vol_i,
	output signed[15:0]vol_o
);
		
	always @(posedge clk)
	if(next_sample)
	begin
		vol_o			<= vol_i * vol / 256;
	end

endmodule

