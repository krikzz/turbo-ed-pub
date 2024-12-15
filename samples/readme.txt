ed_pro 		fpga cores and execution scripts for Turbo EverDrive PRO
ed_core		fpga cores and execution scripts for Turbo EverDrive CORE

************************************************************applications
hello-app	basic hello world app for loading via usb
edio-turbo	work with cartridge features. disk,usb,etc.
mul-app		hardware multiplication application sample

************************************************************fpga cores
fpga_mul	hardware multiplication fpga core sample
fpga_se		simplified fpga core sample. without everdrive system layer, minimal code for fpga.
fpga_std	fpga core sample with regular everdrive system layer

************************************************************execution scripts
start_helo-app.bat		load hello-app via usb
start_helo-app_with_fpga	load hello-app along with fpga_se core via usb
start_mul-app			load mul-app along with fpga_mul core via usb
start_edio-app			load edio-app via usb