`timescale 1ns/1ps

module tb_core;

    logic clk;
    logic rst_n;

    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;

    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_rdata;
    logic [3:0]  dmem_wstrb;
    logic        dmem_req;

    integer i;

    // DUT
    riscv_core_top dut (
        .clk        (clk),
        .rst_n      (rst_n),

        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),

        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_wstrb (dmem_wstrb),
        .dmem_req   (dmem_req),
        .dmem_rdata (dmem_rdata)
    );

    // Instruction memory
    imem_model u_imem (
        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata)
    );

    // Data memory
    dmem_model u_dmem (
        .clk        (clk),
        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_wstrb (dmem_wstrb),
        .dmem_req   (dmem_req),
        .dmem_rdata (dmem_rdata)
    );

    // Clock
    initial
        clk = 1'b0;

    always #5 clk = ~clk;

    // Test
    initial begin
        rst_n = 1'b0;

        #20;
        rst_n = 1'b1;

        // Run full program.hex
        repeat(120)
            @(posedge clk);

        $display("");
        $display("======================================");
        $display(" RV32I PIPELINE REGISTER RESULTS");
        $display("======================================");

        for (i = 0; i < 32; i = i + 1)
            $display("x%0d = %08h", i, dut.u_regfile.regs[i]);

        $display("======================================");

        if (dut.u_regfile.regs[0] == 32'h00000000)
            $display("x0 CHECK : PASS");
        else
            $display("x0 CHECK : FAIL");

        $display("======================================");

        $finish;
    end

endmodule
