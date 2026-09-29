# Cleanup and validation

## What changed

The input was `riscv_pipeline_final.zip`. The cleaned project retains all **46 SystemVerilog source files**, the original `program.hex`, the simulation file list, both shell runners, and the synthesis flow. All five synthesis targets retain their four reports and mapped netlist, for **25 archived result files**. Eight supplied screenshots are included unchanged.

The cleanup excluded **80 files**: simulator work libraries, generated formal-mapping data under `rtl/fv/`, command histories, Genus session command files, editor backups and undo files, `.AppleDouble` metadata, the tool timestamp file, `xrun.key`, `transcript`, an empty stray file named `\`, and the unreferenced `tb_simple/uvm/cim` copy of the top-level testbench. The input archive itself was not modified.

Source edits remove repeated blank lines and trailing spaces, regularize indentation, shorten outdated package comments, and add brief explanations for forwarding priority, WB bypass, load-result availability, and signed arithmetic shifts. The legacy register-dump test's “SINGLE CYCLE” heading now says “PIPELINE.”

Executable SystemVerilog tokens are unchanged except for that display string. The existing SRA/SRAI scoreboard fix, test termination, assertion properties, and coverage bins were preserved. No new CPU feature or architectural fix was introduced.

### Scripts and layout

- `sim/regression.sh`: replaced invalid shell comments, made the default 1,000-seed heading dynamic, added an optional seed count, checked simulator status and complete summaries, rejected stale/missing logs, retained assertion checks, saved console output, and returned failure status when any seed fails.
- `sim/run.sh`: resolves its own working directory, validates test and seed arguments, quotes paths and arguments, and reports a missing simulator clearly. Its simulation options and coverage setup are retained.
- Moved `rtl/synth_riscv.tcl` to `synth/run_genus.tcl`. The script resolves RTL paths, accepts the library path and clock target through environment variables, retains the original clock and I/O constraint recipe, and sends new reports to `synth/build/`.
- Moved `rtl/reports_riscv*` to `synth/reports/{10ns,8ns,6ns,5ns,4ns}`. These reports and netlists are byte-identical to the originals.
- Added `.gitignore`, `.gitattributes`, the main README, and debugging notes. No Git repository or remote is embedded in the package.

## Local validation

The following checks were performed during cleanup:

| Check | Result |
| --- | --- |
| Compare all 46 SystemVerilog token streams with the originals | Match, allowing only the legacy display-label correction |
| Compare archived reports, netlists, and `program.hex` with the input | Byte-identical |
| Shell syntax for both runners | Passed |
| Verilator 5.052 lint of the RTL and bound assertions | No errors; existing warnings listed below |
| Regression runner with controlled simulator outputs | 22 cases passed, including every assertion message, simulator failure, missing/stale logs, incomplete summaries, UVM errors, and scoreboard errors |
| Invalid seed counts | Four cases rejected as expected |
| Single-run wrapper | Arguments, working directory, and simulator exit status checked |
| Synthesis Tcl with mocked Genus commands | All five target settings resolved sources, constraints, and output paths; invalid target rejected |
| File-list entries, UVM includes, and Markdown links | Resolved to included files |
| Ignore rules | Source, screenshots, and archived results remain eligible for Git; generated outputs are excluded |
| Final ZIP | Integrity, file contents, and shell executable modes checked |

Verilator warnings concern the existing `wbmux.sv` / `wb_mux` filename mismatch, unused instruction/control bits, and reset observed in both asynchronous RTL logic and clocked assertion checks. Three original missing-newline warnings were removed by formatting. The remaining warnings were not hidden by editing RTL behavior. The lint invocation used `-Wall -Wno-fatal --assert` so warnings remain visible without making the command fail.

The script checks used mocks and do not constitute processor simulation or synthesis. **Xcelium and Genus were not installed in the cleanup environment**, so the full UVM regression, coverage collection, and synthesis were not rerun. Reported project performance and coverage remain the historical measurements documented in the README.

## Included screenshots

| File | Content |
| --- | --- |
| [Pipeline waveform](images/pipeline-waveform.png) | Successful Bubble Sort pipeline activity |
| [Bubble Sort result](images/bubblesort-result.png) | 169 cycles, 121 retired instructions, CPI 1.397, sorted output |
| [Full Bubble Sort output](images/bubblesort-full-output.png) | UVM summary, scoreboard count, and disabled coverage messages |
| [Final regression](images/regression-1000-pass.png) | 1,000 passes, zero failures, and original shell/header issues |
| [Earlier regression](images/regression-before-fix.png) | 88 passes and twelve failures before the scoreboard correction |
| [Coverage](images/coverage-seed25.png) | Full-test seed-25 coverage and scoreboard summary |
| [4 ns synthesis summary](images/synthesis-4ns-summary.png) | Timing, cell counts, and area |
| [4 ns synthesis QoR](images/synthesis-4ns-qor.png) | Extended Genus QoR output |
