# Five-Stage RISC-V Pipeline with UVM Verification

A 32-bit, in-order RISC-V processor implemented in SystemVerilog, with a five-stage pipeline, data forwarding, load-use stalls, and execute-stage branch resolution. The project implements 37 RV32I integer instructions and includes a UVM environment, a commit-based reference scoreboard, functional coverage, ten SystemVerilog assertions, a Bubble Sort program, and Cadence Genus synthesis results using SKY130 HD cells.

The repository contains the design, runnable simulation and synthesis scripts, archived reports and netlists, and screenshots of the recorded results.

## Recorded results

| Measurement | Result | Evidence |
| --- | --- | --- |
| Instruction functional coverage | **100.00%** of the 37 instruction bins | [Full test, seed 25](docs/images/coverage-seed25.png) |
| Pipeline functional coverage | **98.41%** | [Full test, seed 25](docs/images/coverage-seed25.png) |
| Random-seed regression | **1,000 passes, 0 failures** reported by the original runner | [Regression summary](docs/images/regression-1000-pass.png) |
| Regression stimulus | **140,000 instruction transactions** (140 per seed × 1,000 seeds) | [Full-test sequence](tb_simple/uvm/riscv_full_sequence.sv) |
| Full-test scoreboard, seed 25 | **682 commits, 0 errors** | [Coverage and scoreboard output](docs/images/coverage-seed25.png) |
| Bubble Sort | **PASS**, output `1 2 4 5 8` | [Program result](docs/images/bubblesort-result.png) |
| Bubble Sort performance | **169 cycles / 121 retired instructions = 1.397 CPI** | [Program result](docs/images/bubblesort-result.png) |
| Tightest archived synthesis target | **4 ns / 250 MHz**, +2.0 ps slack | [4 ns QoR report](synth/reports/4ns/qor.rpt) |
| Cell area at 4 ns | **71,966.523 µm²** | [4 ns area report](synth/reports/4ns/area.rpt) |

These are historical results from the supplied screenshots and archived reports. They were not regenerated during repository cleanup. The regression screenshot reaches seed 1000 and reports `PASS = 1000`, although its old heading says “100 SEED.” It also shows errors from two lines using `//` as shell comments. Both issues are corrected in the current runner, which now checks the simulator exit status and requires complete summaries. The historical run has not been repeated with that stricter runner.

## Architecture

```mermaid
flowchart LR
    IM[Instruction memory] --> IF[IF: fetch and PC]
    IF --> IFID[IF/ID]
    IFID --> ID[ID: decode and register read]
    ID --> IDEX[ID/EX]
    IDEX --> EX[EX: ALU and branch decision]
    EX --> EXMEM[EX/MEM]
    EXMEM --> MEM[MEM: load/store unit]
    MEM --> MEMWB[MEM/WB]
    MEMWB --> WB[WB: result selection]
    WB --> ID
    WB --> EX
    EXMEM --> EX
    EX -->|redirect and flush| IF
    MEM <--> DM[Data memory]
```

| Stage | Main functions | Main source files |
| --- | --- | --- |
| IF | Reset PC to zero, select sequential or redirected PC, fetch instruction | `pc_unit.sv`, `if_id_reg.sv` |
| ID | Decode controls, read registers, build immediates, apply WB-to-ID bypass | `decoder.sv`, `regfile.sv`, `immgen.sv`, `id_ex_reg.sv` |
| EX | Select forwarded operands, execute ALU operations, evaluate branches and jump targets | `alu.sv`, `branch_cond.sv`, `forwarding_unit.sv`, `ex_mem_reg.sv` |
| MEM | Generate addresses and byte strobes; select and extend load data | `lsu.sv`, `mem_wb_reg.sv` |
| WB | Select ALU, load, or PC+4 result and write the register file | `wbmux.sv` |

[`riscv_core_top.sv`](rtl/riscv_core_top.sv) connects the stages. [`riscv_pkg.sv`](rtl/riscv_pkg.sv) defines the control word, operation selectors, and NOP encoding.

### Data and control hazards

- EX/MEM forwarding has priority over MEM/WB forwarding when both match a source register. Register zero is excluded.
- Forwarding controls use `00` for the saved operand, `01` for MEM/WB, and `10` for EX/MEM.
- Load results are forwarded from MEM/WB. A dependent instruction behind a load holds the PC and IF/ID register and inserts an ID/EX bubble.
- WB-to-ID bypass makes a result available to an instruction decoding during the same cycle as writeback.
- Branches, JAL, and JALR resolve in EX. A redirect invalidates younger instructions in IF/ID and ID/EX. JALR clears target bit zero.
- Forwarded register operands also feed branch comparisons and store data.

The hazard detector compares both instruction source-field positions without decoding whether each is used. This is conservative and can introduce an unnecessary stall for an immediate field that happens to match a pending load destination.

### Instruction support

| Category | Instructions | Count |
| --- | --- | ---: |
| Register arithmetic and logic | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND | 10 |
| Immediate arithmetic and logic | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI | 9 |
| Loads | LB, LH, LW, LBU, LHU | 5 |
| Stores | SB, SH, SW | 3 |
| Conditional branches | BEQ, BNE, BLT, BGE, BLTU, BGEU | 6 |
| Upper immediates and jumps | LUI, AUIPC, JAL, JALR | 4 |
| **Total** | | **37** |

This is an educational RV32I integer subset. There is no trap/interrupt controller, CSR unit, multiplication/division extension, compressed instruction support, or complete illegal-instruction checking. Unrecognized opcodes, including FENCE and SYSTEM encodings, leave the decoder's controls inactive. No ISA compliance suite result is claimed.

### Memory interface

The core exposes separate instruction and data ports, with no ready/valid response handshake or variable-latency memory support.

| Signal | Direction at the core | Purpose |
| --- | --- | --- |
| `imem_addr[31:0]` | Output | Instruction byte address |
| `imem_rdata[31:0]` | Input | Instruction word |
| `dmem_addr[31:0]` | Output | Data byte address |
| `dmem_wdata[31:0]` | Output | Store data positioned in byte lanes |
| `dmem_wstrb[3:0]` | Output | Store byte enables; zero for reads |
| `dmem_req` | Output | Active load or store |
| `dmem_rdata[31:0]` | Input | Memory read word |

The testbench provides 1,024 words each of instruction and data memory, indexed by address bits `[11:2]`. Addresses outside that 4 KiB window alias in these models. Reads are driven on the falling clock edge in the UVM driver, and stores update enabled byte lanes on the rising edge. The LSU expects naturally aligned halfword and word accesses; it does not implement misalignment traps or accesses crossing word boundaries. There is no AXI interface in this repository.

## Verification environment

```text
UVM test -> sequence -> sequencer -> driver -> instruction/data memory -> DUT
                                                                      |
                                                 interface <- pipeline and commit signals
                                                      |
                                                   monitor
                                                  /       \
                                           scoreboard    coverage

Assertions are bound directly to riscv_core_top.
```

The driver loads instruction transactions before execution and models memory. The monitor publishes fetched instructions, writeback activity, memory signals, stalls, redirects, and forwarding controls.

The scoreboard maintains a reference register file, byte-addressed memory, and expected next PC. It decodes the instruction associated with each valid commit, predicts register results and control flow, and reports mismatches. Reference stores update its memory model so later loads can be checked. It does not independently compare every store bus transaction. The Bubble Sort test additionally checks the final contents of the driver's data memory.

Commit visibility is connected to internal MEM/WB signals in `tb_uvm_top.sv`; it is not a separate architectural output port on the core.

### Tests

| Test | Purpose |
| --- | --- |
| `riscv_smoke_test` | Basic ADDI, ADD, and SUB bring-up |
| `riscv_directed_test` | Directed instruction-category checks |
| `riscv_hazard_test` | Dependent operations, load-use stalls, forwarding, and taken-branch flushing |
| `riscv_random_test` | 60 generated arithmetic, shift, and aligned LW/SW instructions |
| `riscv_full_test` | 80 fixed transactions plus 60 generated instructions; runs for 700 rising clock edges after its reset sequence |
| `riscv_bubblesort_test` | Sort five values, check memory, and measure cycles and retired instructions |

Each full-test seed loads **140 instruction transactions**: 80 fixed transactions and 60 generated instructions. Across 1,000 seeds, the total is **140 × 1,000 = 140,000 instruction transactions**. These are program-loading transactions, not dynamic retired instructions: execution can include branches and the NOP-filled memory after the loaded program.

`riscv_sequence.sv` and `riscv_test.sv` are retained as early bring-up sources. They are not included in the current UVM package or exposed by `run.sh`. The separate `tb_core.sv` testbench reads `program.hex`, prints registers, and checks x0; it is not the full UVM verification flow.

### Functional coverage

[`riscv_coverage.sv`](tb_simple/uvm/riscv_coverage.sv) samples the instruction covergroup at commit and the pipeline covergroup on monitor transactions.

- Instruction coverage contains one wildcard bin for each of the 37 listed instructions.
- Pipeline coverage includes stalls, redirects, both forwarding selectors, memory requests, byte-write strobes, and a cross of the two forwarding selectors.
- The saved seed-25 run reports 100.00% instruction coverage and 98.41% pipeline coverage, with 682 scoreboard commits and zero scoreboard errors.

The strobe coverpoint contains a `0110` halfword-write bin, while the implemented LSU only generates the aligned halfword strobes `0011` and `1100`. The reported 98.41% is consistent with that one uncovered bin under equal coverpoint/cross weighting. This is an inference from the source and aggregate percentage; a per-bin coverage report was not retained. The coverage model has been preserved without adding exclusions.

These percentages describe functional covergroups. They do not establish 100% RTL code coverage or exhaustive architectural correctness.

![Instruction and pipeline coverage](docs/images/coverage-seed25.png)

### Assertions

[`riscv_assertions.sv`](tb_simple/uvm/riscv_assertions.sv) contains ten named properties, connected through [`riscv_bind.sv`](tb_simple/uvm/riscv_bind.sv):

1. Legal forwarding selection for operand A.
2. Legal forwarding selection for operand B.
3. A detected load-use dependency requests a stall.
4. The PC holds after a stall.
5. IF/ID PC and instruction hold after a stall.
6. A redirect flushes IF/ID and ID/EX validity.
7. Pipeline control signals are known.
8. Active writeback destination and data are known.
9. Memory strobes belong to the allowed set.
10. A valid memory-stage instruction does not assert read and write together.

The assertions are included in the simulation file list. The saved seed-25 output and failure-message search recorded no assertion failures; assertion coverage and formal proof results are not included.

### Regression debugging

An earlier 100-seed run reported **88 passes and 12 failures**. The archived project already contains the subsequent scoreboard correction for arithmetic-right-shift signedness. The later screenshot reports **1,000 passes and zero failures**.

See [the debugging notes](docs/debugging.md) for the failure list, the seed-9 mismatch, the existing correction, and the evidence limitations.

![Completed 1000-seed regression](docs/images/regression-1000-pass.png)

## Bubble Sort program

[`riscv_bubblesort_sequence.sv`](tb_simple/uvm/riscv_bubblesort_sequence.sv) loads machine-code instructions that initialize and sort five integers:

```text
Input:   5 1 4 2 8
Output:  1 2 4 5 8
```

The program exercises nested loops, signed comparisons, loads, stores, forwarding, load-use stalls, and redirects. It writes a completion marker to byte address `0x100`. The test stops when the completion store at PC `0x6c` is observed as committed.

The recorded run measured **169 cycles** and **121 retired instructions**, giving `169 / 121 = 1.397` CPI to three decimal places. These are the test's counters over its reset-release-to-completion window, not a universal CPI for the core.

![Bubble Sort result](docs/images/bubblesort-result.png)

The [full Bubble Sort output](docs/images/bubblesort-full-output.png) shows 120 scoreboard commits and zero errors, versus the test's 121 retired instructions. The test samples at the falling edge and ends at completion, while the monitor samples at the rising edge. This leaves the terminal observation out of the scoreboard's reported count. The original termination behavior is preserved. That historical run also had covergroup collection disabled, so its displayed 0.00% coverage does not replace the separate seed-25 coverage result.

### Pipeline waveform

The supplied waveform shows stage-valid signals, register destinations, forwarding, a load-use stall, redirect activity, commits, and data-memory traffic during Bubble Sort.

![Bubble Sort pipeline waveform](docs/images/pipeline-waveform.png)

## Running simulations

Use a Linux environment with Cadence Xcelium and its UVM library configured. The recorded logs identify Xcelium `26.03-s001` with Cadence UVM `1.1d`. A RISC-V software compiler is not required for the included sequences; their machine-code instructions are embedded in SystemVerilog.

From the repository root:

```bash
# Smoke test, seed 1, with coverage.
./sim/run.sh

# Reproduce the named full-test coverage setup.
./sim/run.sh riscv_full_test 25

# Bubble Sort with coverage enabled by this wrapper.
./sim/run.sh riscv_bubblesort_test 1

# Full test across seeds 1 through 1000, without coverage collection.
./sim/regression.sh

# Shorter run across seeds 1 through 100.
./sim/regression.sh 100
```

Both scripts resolve paths relative to `sim/`. `run.sh` stores logs under `sim/logs/` and coverage under `sim/cov_work/`; rerunning the same test and seed overwrites its named coverage result. It returns Xcelium's exit status, so inspect the UVM and scoreboard summaries as well.

`regression.sh` writes simulation and console logs under `sim/regression_logs/`. A seed passes only when Xcelium exits successfully, the log contains zero UVM errors and fatals, the scoreboard reports at least one commit and zero errors, and no listed assertion failure or simulator error is found. The script prints a seed-count-aware heading, records failures in `sim/failed_seeds.txt`, and returns a nonzero status if any seed fails. Repeated runs overwrite logs for the selected seeds; older logs for other seed numbers can remain.

To inspect a single coverage run:

```bash
grep -E 'Instruction Coverage|Pipeline Coverage|COMMITS=|^UVM_ERROR|^UVM_FATAL' \
    sim/logs/riscv_full_test_seed25.log
```

For an interactive Bubble Sort waveform session:

```bash
cd sim
xrun -64bit -sv -uvm -timescale 1ns/1ps -f filelist.f \
    -top tb_uvm_top +UVM_TESTNAME=riscv_bubblesort_test \
    +UVM_VERBOSITY=UVM_NONE +UVM_NO_RELNOTES -svseed 1 -access +rwc -gui
```

Add `dut.pc`, pipeline stage-valid signals, `dut.hazard_stall`, `dut.ex_redirect`, `dut.forward_a`, `dut.forward_b`, and the `vif.commit_*` / `vif.dmem_*` signals in SimVision. This GUI command does not enable coverage collection.

## Synthesis characterization

The saved reports were generated on September 28, 2026 using **Cadence Genus 25.13-s071_1**. The supplied synthesis script selects `sky130_fd_sc_hd__tt_025C_1v80.lib`: SKY130 HD at the typical 25 °C, 1.8 V corner. The reports describe pre-layout synthesis with `Wireload mode: top` and timing-library area. The library itself is not bundled.

The table uses the exact slack and area values in each `qor.rpt`. Report clock periods and slack are in picoseconds; the target column converts periods to nanoseconds. The detailed timing reports round some slack values to whole picoseconds.

| Target | Frequency | Worst slack | Violating paths | Cells | Sequential cells | Cell area (µm²) | Report |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 10 ns | 100 MHz | +13.7 ps | 0 | 5,143 | 1,523 | 68,775.963 | [QoR](synth/reports/10ns/qor.rpt) |
| 8 ns | 125 MHz | +13.7 ps | 0 | 5,258 | 1,523 | 69,217.636 | [QoR](synth/reports/8ns/qor.rpt) |
| 6 ns | 166.7 MHz | +0.4 ps | 0 | 5,456 | 1,523 | 69,716.865 | [QoR](synth/reports/6ns/qor.rpt) |
| 5 ns | 200 MHz | +4.6 ps | 0 | 5,555 | 1,523 | 70,179.809 | [QoR](synth/reports/5ns/qor.rpt) |
| **4 ns** | **250 MHz** | **+2.0 ps** | **0** | **5,971** | **1,523** | **71,966.523** | [QoR](synth/reports/4ns/qor.rpt) |

Each target directory retains `area.rpt`, `timing.rpt`, `qor.rpt`, `gates.rpt`, and `riscv_core_netlist.v` unchanged from the input archive.

Area increases by approximately **4.64%** from the 10 ns target to the 4 ns target. Sequential cell count remains at 1,523, while combinational cell count increases from 3,620 to 4,448.

| Targets | Critical-path endpoints in the reports | Interpretation from the RTL |
| --- | --- | --- |
| 10, 8, 6 ns | MEM/WB destination register → PC register | Forwarding selection feeding execute-stage redirect logic |
| 5 ns | MEM/WB writeback selector → EX/MEM ALU-result register | Writeback selection, forwarding, and ALU path |
| 4 ns | EX/MEM destination register → EX/MEM ALU-result register | Forwarding selection and ALU path |

The gate-level reports establish the endpoints; the datapath descriptions are interpretations based on the RTL. The results meet the archived targets under the supplied synthesis constraints. **250 MHz is a met pre-layout target, not a measured silicon frequency or proven maximum frequency.** Place-and-route, extracted timing, multi-corner signoff, and tighter failing targets are not included.

### Running synthesis

From the repository root, with Genus and the SKY130 Liberty file available:

```bash
export SKY130_LIB=/path/to/sky130_fd_sc_hd__tt_025C_1v80.lib
CLOCK_PERIOD_NS=4 genus -files synth/run_genus.tcl
```

To repeat the five target settings:

```bash
for period in 10 8 6 5 4; do
    CLOCK_PERIOD_NS="$period" genus -files synth/run_genus.tcl
done
```

The script defaults to 4 ns and to `~/sky130_lib/sky130_fd_sc_hd__tt_025C_1v80.lib` if `SKY130_LIB` is unset. It retains the original 2 ns input and output delays, including the original `all_inputs` selection. It writes new outputs to `synth/build/<period>ns/`, leaving the archived evidence in `synth/reports/` intact. Review the constraints for any new integration or physical-design flow.

## Repository layout

```text
riscv_pipeline/
├── rtl/                    # processor RTL and shared package
├── tb_simple/
│   ├── tb_core.sv          # early standalone register-dump test
│   ├── imem_model.sv
│   ├── dmem_model.sv
│   └── uvm/                # active UVM environment, tests and assertions
├── sim/
│   ├── filelist.f
│   ├── run.sh              # one test with coverage
│   └── regression.sh       # full test across seeds, coverage disabled
├── synth/
│   ├── run_genus.tcl
│   └── reports/            # 10ns, 8ns, 6ns, 5ns and 4ns results
├── docs/
│   ├── images/             # supplied result and waveform screenshots
│   ├── debugging.md
│   └── cleanup.md
├── program.hex             # instruction image for tb_core.sv
├── LICENSE                 # MIT license
├── .gitignore
├── .gitattributes
└── README.md
```

Simulator databases, coverage databases, temporary logs, generated formal-mapping files, editor backups, and operating-system metadata are excluded. Final synthesis reports and netlists are intentionally retained. See [cleanup and validation details](docs/cleanup.md).

## Getting the source

```bash
git clone https://github.com/Charan6556/RISCV-32I.git
cd RISCV-32I
```

The repository history retains the earlier single-cycle implementation. The current sources contain the five-stage pipeline and UVM verification environment described above.

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2026 Charan Gundepinni.
