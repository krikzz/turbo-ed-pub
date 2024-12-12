@echo off
copy fpga_se\output_files\tecore.rbf fpga_se\output_files\tecore.x26
..\turbolink ..\hello-app/hello-app.pce fpga_se\output_files\tecore.x26
