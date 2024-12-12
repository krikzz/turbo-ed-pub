
//********

typedef struct{
		
	bit [7:0]data;
	bit [20:0]addr;
	bit oe;
	bit we;
	bit ce;
	bit rst;
	bit hsm;
	bit irq;
	
	bit we_sync;
	bit oe_sync;
	
}CpuBus;

//********

typedef struct{
	
	bit [7:0]dati;
	bit [23:0]addr;
	bit ce, oe, we;
	bit ce2;//cpu cycles separator required for psram
	
}MemCtrl;

//********

typedef struct{

	bit clk;
	bit map_rst;
	bit region;//system card region
	bit [7:0]rom_dato;
	bit [7:0]ram_dato;
	bit [7:0]brm_dato;
	
	CpuBus cpu;
	
}HucIn;

//********

typedef struct{

	bit cart_ce;
	bit [7:0]cart_dato;
	bit irq;
	bit led;
	
	MemCtrl rom;
	MemCtrl ram;
	MemCtrl brm;//8Kb for Ten no Koe card
	
}HucOut;

//********

typedef struct{

	bit clk;
	bit map_rst;
	bit pi_ce;
	bit sst_act;
	
	bit [7:0]ram_dato;
	bit [7:0]brm_dato;
	bit [7:0]adp_dato;
	
	CpuBus cpu;
	DacSC  dsc;
	PiBus  pi;
	
}ExpIn;

//********

typedef struct{

	bit ce;
	bit [7:0]dato;
	bit [7:0]pi_data;
	bit irq;
	bit led;
	bit mcu_master;
	bit use_irq;
	
	MemCtrl ram; //wram  64K
	MemCtrl brm; //bram  2K
	MemCtrl adp; //adpcm 64K
	DacIn   dac;
	
}ExpOut;

//********

typedef struct{
	
	
	bit ce_ram0;
	bit ce_ram1;
	bit ce_sys;
	
	//all below located in ce_sys area
	bit ce_cfg;
	bit ce_cc_ram;
	bit ce_cc_rom;
	bit ce_fifo;
	bit ce_exp;
	bit ce_brm;
		
}PiMap;

//********

typedef struct{

	bit [7:0]dato;
	bit [31:0]addr;
	bit we;//write mode
	bit oe;//read mode
	bit act;//memory read or write during act=1 pulse
	
	bit we_sync;
	bit oe_sync;
	
}PiBus;


//********

typedef struct{

	MemCtrl	mem;
	bit [7:0]pi_data;
	bit req_ram0;
	bit req_ram1;
	bit mem_req;
	
}DmaBus;

//********

typedef struct{
	
	bit huc_region;
	bit [3:0]huc_type;
	bit [3:0]exp_type;
	
	bit[7:0]key_save;
	bit[7:0]key_load;
	bit[7:0]key_menu;
	
	bit ct_rst_dl;
	bit ct_brm_on;
	bit ct_sst_on;
	bit ct_cc_on;
	bit ct_stereo;
	bit ct_cart_off;
	
	bit [7:0]vol_l;
	bit [7:0]vol_r;
		
}SysCfg;

//********

typedef struct{		//from dac to audio source
	
	bit clk;				//sample rate x512. 1 system clock pulse
	bit next_byte;		//sample bytes update
	bit next_sample;	//dac sample fetch
	
}DacSC;

//********

typedef struct{	//from audio source to dac
	
	bit uclk;		//user clock for dac
	bit uclk_act;	//override regular dac clk by the uclk
	bit snd_on;		//mute control
	bit signed[15:0]snd_r;
	bit signed[15:0]snd_l;
	
}DacIn;

//********