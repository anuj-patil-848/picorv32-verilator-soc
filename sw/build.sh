#!/usr/bin/env bash
set -euo pipefail

# Inputs
SRC=${1:-sw/test.S}
LD_SCRIPT=sw/link.ld

# Outputs
mkdir -p out
OBJ=out/test.o
ELF=out/prog.elf
BIN=out/prog.bin
HEX=out/prog.hex

echo "[1/4] Assemble -> $OBJ"
riscv64-unknown-elf-as -march=rv32im -mabi=ilp32 -o "$OBJ" "$SRC"

echo "[2/4] Link (ELF32) -> $ELF"
riscv64-unknown-elf-ld -m elf32lriscv -T "$LD_SCRIPT" -o "$ELF" "$OBJ"

echo "[3/4] Objcopy -> $BIN"
riscv64-unknown-elf-objcopy -O binary "$ELF" "$BIN"

echo "[4/4] Convert BIN -> HEX (32-bit words, little-endian) -> $HEX"
python3 - <<'PY'
import struct, pathlib
bin_path = pathlib.Path("out/prog.bin")
data = bin_path.read_bytes()
data += b"\x00" * ((4 - (len(data) % 4)) % 4)
with open("out/prog.hex", "w") as f:
    for i in range(0, len(data), 4):
        f.write(f"{struct.unpack('<I', data[i:i+4])[0]:08x}\n")
print("wrote out/prog.hex words:", len(data)//4)
PY

echo "Done. First 4 words:"
head -n 4 "$HEX"
