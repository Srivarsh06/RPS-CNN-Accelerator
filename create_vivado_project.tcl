# Build the Vivado project (vivado/rps_cnn.xpr) for the Urbana board (Spartan-7 XC7S50).
# In the Vivado Tcl console:  cd <repo>; source create_vivado_project.tcl
# Or from a shell:           vivado -mode batch -source create_vivado_project.tcl
set root [file normalize [file dirname [info script]]]

create_project rps_cnn $root/vivado -part xc7s50csga324-1 -force

add_files -fileset sources_1 [glob $root/rtl/*.sv]
add_files -fileset sim_1 [glob $root/tb/*.sv]

# Design top: the MAC engine for now (inference_ctrl takes over once the layers exist).
# Synthesized out-of-context because it is not wired to board pins yet.
set_property top mac_engine [get_filesets sources_1]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]

# Simulation top: self-checking MAC testbench, run until $finish.
set_property top tb_mac_engine [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "Created $root/vivado/rps_cnn.xpr"
