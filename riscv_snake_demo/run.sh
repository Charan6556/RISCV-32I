#!/usr/bin/env bash
# build a C program with clang and run it on the core in Verilator
# usage: ./run.sh [program]    default is snake
set -e
cd "$(dirname "$0")"
PROG=${1:-snake}
mkdir -p build

# compile and link
clang --target=riscv32-unknown-elf -march=rv32i -mabi=ilp32 -O2 \
      -ffreestanding -nostdlib -mno-relax -fuse-ld=lld \
      -T sw/link.ld sw/start.S sw/rt.c sw/$PROG.c -o build/$PROG.elf
llvm-objcopy -O binary build/$PROG.elf build/$PROG.bin

# make a hex file for $readmemh (one 32-bit word per line)
python3 -c "
d = open('build/$PROG.bin','rb').read(); d += b'\0' * (-len(d) % 4)
open('build/$PROG.hex','w').write('\n'.join('%08x' % int.from_bytes(d[i:i+4],'little') for i in range(0,len(d),4)) + '\n')
print('[build] $PROG: %d bytes of code+data' % len(d))"

# build the simulator once
if [ ! -x build/obj_dir/Vtb_soc ]; then
  verilator --binary --timing -Wno-fatal -Wno-lint -Wno-style \
    -I../rtl ../rtl/riscv_pkg.sv $(ls ../rtl/*.sv | grep -v riscv_pkg) tb/tb_soc.sv \
    --top-module tb_soc -Mdir build/obj_dir -o Vtb_soc
fi

./build/obj_dir/Vtb_soc +HEX=build/$PROG.hex
