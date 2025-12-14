#!/usr/bin/env bash
set -euo pipefail

./sw/build.sh sw/test.S

rm -rf obj_dir
verilator -Wall -Wno-fatal --top-module tb_top --binary \
  rtl/picorv32/picorv32.v \
  rtl/soc_top.sv \
  tb/tb_top.sv

./obj_dir/Vtb_top
