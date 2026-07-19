`timescale 1ns/1ps

module tb_core;
// Signals: clk, rst_n, plus the DUT's memory-interface wires

logic clk;
logic rst_n;
logic [31:0] imem_addr, imem_rdata;
logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
logic [3:0]  dmem_wstrb;
logic        dmem_req;
 // Instantiate DUT + imem_model + dmem_model
riscv_core_top dut (
    .clk         (clk),
    .rst_n       (rst_n),
    .imem_addr   (imem_addr),
    .imem_rdata  (imem_rdata),
    .dmem_addr   (dmem_addr),
    .dmem_wdata  (dmem_wdata),
    .dmem_wstrb  (dmem_wstrb),
    .dmem_req    (dmem_req),
    .dmem_rdata  (dmem_rdata)
);

imem_model u_imem (
    .imem_addr  (imem_addr),
    .imem_rdata (imem_rdata)
);

dmem_model u_dmem (
    .clk        (clk),
    .dmem_addr  (dmem_addr),
    .dmem_wdata (dmem_wdata),
    .dmem_wstrb (dmem_wstrb),
    .dmem_req   (dmem_req),
    .dmem_rdata (dmem_rdata)
);

    // Cloinitial clk = 1'b0;
initial clk = 1'b0;
always #5 clk = ~clk;

    // Reset generator (initial block that pulses rst_n)
initial begin
    rst_n = 1'b0;   // reset asserted (active-low)
    #20;            // hold for two clock cycles
    rst_n = 1'b1;   // release reset
end
// ---- Full instruction test: expected vs got for all checks ----
    initial begin
        int fail_count;
        logic [31:0] expected, got;
        fail_count = 0;

        @(posedge rst_n);
        #(60 * 10);   // 60 cycles for 32 instructions with slack

        $display("=== Full instruction test ===");
        $display("  Reg   Expected   Got        Result   Test");
        $display("  ------------------------------------------------------");

        expected = 32'h00000000; got = dut.u_regfile.regs[0];
        $display("  x0    %08h   %08h   %s   x0 rule (write blocked)", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000005; got = dut.u_regfile.regs[1];
        $display("  x1    %08h   %08h   %s   addi 5", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000007; got = dut.u_regfile.regs[2];
        $display("  x2    %08h   %08h   %s   addi 7", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'hffffffff; got = dut.u_regfile.regs[3];
        $display("  x3    %08h   %08h   %s   addi -1 (sign ext)", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h0000000c; got = dut.u_regfile.regs[4];
        $display("  x4    %08h   %08h   %s   add 5+7", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000002; got = dut.u_regfile.regs[5];
        $display("  x5    %08h   %08h   %s   sub 7-5", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000005; got = dut.u_regfile.regs[6];
        $display("  x6    %08h   %08h   %s   and 5&7", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000007; got = dut.u_regfile.regs[7];
        $display("  x7    %08h   %08h   %s   or 5|7", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000002; got = dut.u_regfile.regs[8];
        $display("  x8    %08h   %08h   %s   xor 5^7", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000014; got = dut.u_regfile.regs[9];
        $display("  x9    %08h   %08h   %s   slli 5<<2", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'hffffffff; got = dut.u_regfile.regs[10];
        $display("  x10   %08h   %08h   %s   srai -1>>>1 (SRA trap)", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000001; got = dut.u_regfile.regs[11];
        $display("  x11   %08h   %08h   %s   slt -1<0 signed", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000000; got = dut.u_regfile.regs[12];
        $display("  x12   %08h   %08h   %s   sltu FFFFFFFF>0 unsigned", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h12345000; got = dut.u_regfile.regs[13];
        $display("  x13   %08h   %08h   %s   lui (PASS_B / D1)", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000034; got = dut.u_regfile.regs[14];
        $display("  x14   %08h   %08h   %s   auipc pc+0", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000064; got = dut.u_regfile.regs[15];
        $display("  x15   %08h   %08h   %s   addi 100 (base addr)", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000005; got = dut.u_regfile.regs[16];
        $display("  x16   %08h   %08h   %s   sw then lw roundtrip", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000007; got = dut.u_regfile.regs[17];
        $display("  x17   %08h   %08h   %s   sb then lbu (byte lane)", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000001; got = dut.u_regfile.regs[18];
        $display("  x18   %08h   %08h   %s   beq not taken", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000000; got = dut.u_regfile.regs[19];
        $display("  x19   %08h   %08h   %s   beq taken (skip)", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000003; got = dut.u_regfile.regs[20];
        $display("  x20   %08h   %08h   %s   sentinel after branches", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000063; got = dut.u_regfile.regs[21];
        $display("  x21   %08h   %08h   %s   99 via x0 (x0 stayed 0)", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000078; got = dut.u_regfile.regs[22];
        $display("  x22   %08h   %08h   %s   jalr link, rd==rs1 trap", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        expected = 32'h00000007; got = dut.u_regfile.regs[23];
        $display("  x23   %08h   %08h   %s   reached after jalr", expected, got, (expected===got) ? "PASS" : "FAIL");
        if (expected !== got) fail_count++;

        $display("  ------------------------------------------------------");
        if (fail_count == 0)
            $display("  *** ALL 24 CHECKS PASS ***");
        else
            $display("  *** %0d FAILURES ***", fail_count);
    end
    // Test-runner initial block
    initial begin
        @(posedge rst_n);
        #(100 * 10);
        $display("=== Simulation complete ===");
        $finish;
    end

    // X-propagation checker
    initial begin
        @(posedge rst_n);
        #10;
        for (int i = 0; i < 32; i++) begin
            if (^dut.u_regfile.regs[i] === 1'bx)
                $error("X in regfile[%0d] after reset", i);
        end
        if (^dut.u_pc_unit.pc === 1'bx)
            $error("X in PC after reset");
    end

endmodule