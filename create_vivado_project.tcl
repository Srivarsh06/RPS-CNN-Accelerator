# Build the Vivado project (vivado/rps_cnn.xpr) for the Urbana board (Spartan-7 XC7S50).
# In the Vivado Tcl console:  cd <repo>; source create_vivado_project.tcl
# Or from a shell:           vivado -mode batch -source create_vivado_project.tcl
set root [file normalize [file dirname [info script]]]

create_project rps_cnn $root/vivado -part xc7s50csga324-1 -force

add_files -fileset sources_1 [glob $root/rtl/*.sv]
add_files -fileset sources_1 [glob $root/mem/*.mem]
add_files -fileset constrs_1 $root/constraints/urbana_selftest.xdc

# Design top: on-board MAC self-test (HEX A shows PASS/FAIL, HEX B the cycle count).
set_property top selftest_top [get_filesets sources_1]

# sim_1: MAC engine unit testbench. sim_selftest: whole self-test, pass + injected-fault runs.
# Both run until $finish; pick one with right-click -> Make Active in the Sources panel.
add_files -fileset sim_1 $root/tb/tb_mac_engine.sv
set_property top tb_mac_engine [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

create_fileset -simset sim_selftest
add_files -fileset sim_selftest $root/tb/tb_selftest_top.sv
set_property top tb_selftest_top [get_filesets sim_selftest]
set_property top_lib xil_defaultlib [get_filesets sim_selftest]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_selftest]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
update_compile_order -fileset sim_selftest
puts "Created $root/vivado/rps_cnn.xpr"
