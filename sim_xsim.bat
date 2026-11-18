@echo off
rem Run the MAC engine testbench with Vivado's xsim (Windows).  Usage: sim_xsim.bat
rem Edit VIVADO if Vivado is installed somewhere else.
set VIVADO=C:\Xilinx\Vivado\2022.2\bin
cd /d "%~dp0"
if not exist obj_xsim mkdir obj_xsim
cd obj_xsim
call "%VIVADO%\xvlog.bat" -sv ..\rtl\mac_lane.sv ..\rtl\mac_engine.sv ..\tb\tb_mac_engine.sv || exit /b 1
call "%VIVADO%\xelab.bat" tb_mac_engine -s tb_sim || exit /b 1
call "%VIVADO%\xsim.bat" tb_sim -R
