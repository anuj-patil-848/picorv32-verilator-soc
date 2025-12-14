# PicoRV32 Verilator SoC

A minimal **RISC-V (RV32IM) System-on-Chip** built around the **PicoRV32** CPU core and simulated using **Verilator**.  
This project includes on-chip RAM, a memory-mapped exit device for testing, and a complete software flow capable of running real RISC-V programs.

This repository is intended as a **learning and experimentation platform** for computer architecture, SoC design, and low-level software development.

---

## Architecture Overview

- **CPU:** PicoRV32 (RV32IM)
- **Simulation:** Verilator
- **Bus Interface:** PicoRV32 native memory interface
- **Memory System:**
  - 64 KB on-chip RAM
  - Memory-mapped exit register
- **Toolchain:** `riscv64-unknown-elf`

---

## Memory Map

| Address Range | Description |
|--------------|-------------|
| `0x0000_0000 – 0x0000_FFFF` | 64 KB RAM |
| `0x2000_0000` | Test exit MMIO register |

Writing to `0x2000_0000` terminates the simulation:

- Writing `2` → **PASS**
- Writing any other value → **FAIL**

---

## Design Details

The PicoRV32 CPU communicates with memory using a simple handshake-based interface:

- `mem_valid` — CPU is requesting a memory access  
- `mem_ready` — memory has completed the request  
- `mem_addr` — address being accessed  
- `mem_wdata` — write data (stores)  
- `mem_wstrb` — byte write strobes  
- `mem_rdata` — read data returned to the CPU  

### Memory Behavior

- **Reads** are handled combinationally (zero wait-state)
- **Writes** are committed on the **rising clock edge**
- Unmapped addresses return zero

This models a simple, deterministic memory system suitable for early CPU and OS bring-up.

---

## Software Flow

1. Write RISC-V assembly in `sw/test.S`
2. Assemble and link into a 32-bit ELF
3. Convert ELF → `out/prog.hex`
4. Verilator loads `out/prog.hex` into RAM
5. PicoRV32 begins execution at `0x0000_0000`
6. Program writes to `0x2000_0000` to signal PASS/FAIL

---

## Example RISC-V Program

```asm
.section .text
.globl _start

_start:
    li t0, 0x20000000   # Exit MMIO address
    li t1, 2            # PASS code
    sw t1, 0(t0)        # End simulation

1:
    j 1b
```
---

## Running the Simulation

From the project root, run:

```bash
./run.sh
```
---
## Project Structure

```text
rtl/
  picorv32/        PicoRV32 core
  soc_top.sv       SoC top-level module

tb/
  tb_top.sv        Verilator testbench

sw/
  test.S           RISC-V assembly program
  link.ld          Linker script
  build.sh         Software build script

out/
  prog.hex         Program loaded into RAM

run.sh             Full build + simulate flow
```
---
## Future Work
- UART peripheral
- Timer and interrupt support
- Multi-cycle memory with wait states
- Instruction coverage
- UVM-style testbench
- Simple bootloader
- Minimal operating system
---
## License
This project is for educational purposes.
