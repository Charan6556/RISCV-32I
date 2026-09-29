class riscv_hazard_sequence extends uvm_sequence #(riscv_transaction);

    `uvm_object_utils(riscv_hazard_sequence)

    riscv_transaction trans;

    function new(string name = "riscv_hazard_sequence");
        super.new(name);
    endfunction

    task send_instr(bit [31:0] pc, bit [31:0] instr);
        trans = riscv_transaction::type_id::create("trans");

        start_item(trans);
        trans.pc    = pc;
        trans.instr = instr;
        finish_item(trans);
    endtask

    task body();
        // x1 = 5
        send_instr(32'h0000_0000, 32'h0050_0093);

        // RAW dependency on x1
        // x2 = x1 + 3
        send_instr(32'h0000_0004, 32'h0030_8113);

        // forwarding
        // x3 = x2 + x1
        send_instr(32'h0000_0008, 32'h0011_01b3);

        // store x3
        send_instr(32'h0000_000c, 32'h0030_2023);

        // load x4
        send_instr(32'h0000_0010, 32'h0000_2203);

        // load-use hazard
        // x5 = x4 + x1
        send_instr(32'h0000_0014, 32'h0012_02b3);

        // forwarding
        // x6 = x5 + x4
        send_instr(32'h0000_0018, 32'h0042_8333);

        // branch taken + flush
        // BEQ x6, x6, +8
        send_instr(32'h0000_001c, 32'h0063_0463);

        // should be flushed
        send_instr(32'h0000_0020, 32'h0630_0393);

        // branch target
        // x7 = 7
        send_instr(32'h0000_0024, 32'h0070_0393);
    endtask
endclass
