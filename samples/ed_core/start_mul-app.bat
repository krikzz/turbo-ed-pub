@echo off
copy fpga_mul\output_files\tecore.rbf fpga_mul\output_files\tecore.x26
..\turbolink ..\mul-app\mul-app.pce fpga_mul\output_files\tecore.x26
pause