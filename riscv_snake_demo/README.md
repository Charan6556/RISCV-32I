# Running C programs on the RV32I core

`tb/tb_soc.sv` puts `riscv_core_top` in a small test system:

| Address | Function |
| --- | --- |
| `0x0000_0000` - `0x0000_3FFF` | 16 KB RAM, used for both code and data |
| `0x1000_0000` | console, a byte store prints one character |
| `0x1000_0004` | exit, a word store prints the counters and ends the sim |

The testbench also counts cycles, retired instructions, load-use stalls and taken branches/jumps (redirects).

## Files

| File | Purpose |
| --- | --- |
| `sw/start.S` | startup code: sets the stack, clears bss, calls `main` |
| `sw/link.ld` | linker script for the 16 KB RAM |
| `sw/rt.c` | software multiply/divide (RV32I has no M extension) |
| `sw/snake.c` | self-playing snake: BFS pathfinding with a flood-fill check for available space |
| `tb/tb_soc.sv` | memory, console, exit register and performance counters |
| `run.sh` | builds the C code with clang and runs it in Verilator |
| `make_video.py` | optional, makes a GIF/MP4 from the console output |

## How to run

Needs Verilator, clang/LLVM with lld, and Python 3. On a Mac: `brew install verilator llvm lld` and put the Homebrew llvm and lld on your PATH.

```bash
./run.sh snake | tee build_out.txt
python3 make_video.py build_out.txt snake_rv32i   # optional, needs Pillow and ffmpeg
```

Run these commands from `riscv_snake_demo/` inside this repository; the build uses the adjacent `../rtl/` directory.

[Demo recording](../docs/images/snake-demo.mov)

## Result

Results from the recorded run with Verilator 5.052:

| | |
| --- | --- |
| Score | 40 (target reached) |
| Instructions retired | 56,912,196 |
| Cycles | 69,192,928 |
| CPI | 1.216 |
| Load-use stalls | 3,217,210 |
| Taken redirects | 4,531,759 |

Branches and jumps resolve in EX. For this run, the counters match a two-cycle penalty per taken redirect, with four cycles left for pipeline fill:

```
56,912,196 retired + 3,217,210 stalls + 2 x 4,531,759 redirects = 69,192,924
69,192,928 cycles - 69,192,924 = 4 cycles of pipeline fill
```
