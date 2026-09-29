`timescale 1ns/1ps

module tb_uvm_top;

    import uvm_pkg::*;
    import riscv_uvm_pkg::*;

    logic clk;

    // clock
    initial
        clk = 0;

    always #5 clk = ~clk;

    // interface
    riscv_if vif(clk);

    // DUT
    riscv_core_top dut (
        .clk        (clk),
        .rst_n      (vif.rst_n),

        // instruction memory
        .imem_addr  (vif.imem_addr),
        .imem_rdata (vif.imem_rdata),

        // data memory
        .dmem_addr  (vif.dmem_addr),
        .dmem_wdata (vif.dmem_wdata),
        .dmem_wstrb (vif.dmem_wstrb),
        .dmem_req   (vif.dmem_req),
        .dmem_rdata (vif.dmem_rdata)
    );

    // commit signals
    assign vif.commit_valid =
           dut.mem_wb_valid;

    assign vif.commit_reg_write =
           dut.mem_wb_valid &&
           dut.mem_wb_ctrl.reg_write;

    assign vif.commit_rd =
           dut.mem_wb_rd;

    assign vif.commit_data =
           dut.wb_data;

    assign vif.commit_pc =
           dut.mem_wb_pc4 - 32'd4;

    // pipeline signals
    assign vif.stall =
           dut.hazard_stall;

    assign vif.redirect =
           dut.ex_redirect;

    assign vif.forward_a =
           dut.forward_a;

    assign vif.forward_b =
           dut.forward_b;

    // reset
    initial begin
        vif.rst_n = 0;

        repeat(4)
            @(posedge clk);

        vif.rst_n = 1;
    end

    // UVM
    initial begin
        uvm_config_db #(virtual riscv_if)::set(
            null,
            "*",
            "vif",
            vif
        );

        run_test();
    end
endmodule
