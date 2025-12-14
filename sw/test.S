.section .text
.globl _start
_start:
  li t0, 0x20000000   # EXIT MMIO (matches soc_top.sv)
  li t1, 2            # PASS code
  sw t1, 0(t0)        # write -> $finish in simulation
1: j 1b
