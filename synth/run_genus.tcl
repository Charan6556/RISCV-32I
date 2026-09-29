# Genus synthesis for the five-stage core using SKY130 HD.
set script_dir [file dirname [file normalize [info script]]]
set rtl_dir [file normalize [file join $script_dir ../rtl]]

set clock_period 4
if {[info exists env(CLOCK_PERIOD_NS)]} {
    set clock_period $env(CLOCK_PERIOD_NS)
}
if {![string is double -strict $clock_period] || $clock_period <= 0} {
    error "CLOCK_PERIOD_NS must be a positive number"
}

set library_file [file join $env(HOME) sky130_lib sky130_fd_sc_hd__tt_025C_1v80.lib]
if {[info exists env(SKY130_LIB)]} {
    set library_file $env(SKY130_LIB)
}
if {![file isfile $library_file]} {
    error "SKY130 library not found: $library_file (set SKY130_LIB to its path)"
}
set_db library [file normalize $library_file]

# Read the package before modules that use its types.
set rtl_files {
    riscv_pkg.sv
    alu.sv branch_cond.sv decoder.sv immgen.sv regfile.sv
    pc_unit.sv lsu.sv wbmux.sv
    if_id_reg.sv id_ex_reg.sv ex_mem_reg.sv mem_wb_reg.sv
    forwarding_unit.sv hazard_unit.sv
    riscv_core_top.sv
}
set sources {}
foreach name $rtl_files {
    lappend sources [file join $rtl_dir $name]
}
read_hdl -sv $sources
elaborate riscv_core_top
check_design -unresolved

# Keep the original 2 ns input/output delays for comparison with saved runs.
create_clock -name clk -period $clock_period [get_ports clk]
set_input_delay 2 -clock clk [all_inputs]
set_output_delay 2 -clock clk [all_outputs]

syn_generic
syn_map
syn_opt

# New runs go here; archived reports remain in synth/reports/.
set output_dir [file join $script_dir build "${clock_period}ns"]
file mkdir $output_dir
report_area   > [file join $output_dir area.rpt]
report_timing > [file join $output_dir timing.rpt]
report_qor    > [file join $output_dir qor.rpt]
report_gates  > [file join $output_dir gates.rpt]
write_hdl     > [file join $output_dir riscv_core_netlist.v]

exit
