#!/usr/bin/env bash
# Run the MAC engine testbench with Verilator.  Usage: ./sim.sh
# (Needs Verilator >=5 with C++20; in Vivado just add rtl/*.sv as design sources and tb/*.sv as simulation sources.)
set -e
cd "$(dirname "$0")"
verilator --binary --timing -Wno-fatal -CFLAGS -std=c++20 --top-module tb_mac_engine \
  rtl/mac_lane.sv rtl/mac_engine.sv tb/tb_mac_engine.sv -Mdir obj_mac >/dev/null
./obj_mac/Vtb_mac_engine
