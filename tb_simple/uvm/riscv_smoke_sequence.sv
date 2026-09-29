class riscv_smoke_sequence extends uvm_sequence #(riscv_transaction);

    `uvm_object_utils(riscv_smoke_sequence)

    function new(string name = "riscv_smoke_sequence");
        super.new(name);
    endfunction

    task body();
        riscv_transaction trans;

        // ADDI x1, x0, 5
        trans = riscv_transaction::type_id::create("trans");
        start_item(trans);
        trans.pc    = 32'h0000_0000;
        trans.instr = 32'h0050_0093;
        finish_item(trans);

        // ADDI x2, x0, 7
        trans = riscv_transaction::type_id::create("trans");
        start_item(trans);
        trans.pc    = 32'h0000_0004;
        trans.instr = 32'h0070_0113;
        finish_item(trans);

        // ADD x3, x1, x2
        trans = riscv_transaction::type_id::create("trans");
        start_item(trans);
        trans.pc    = 32'h0000_0008;
        trans.instr = 32'h0020_81b3;
        finish_item(trans);

        // SUB x4, x2, x1
        trans = riscv_transaction::type_id::create("trans");
        start_item(trans);
        trans.pc    = 32'h0000_000c;
        trans.instr = 32'h4011_0233;
        finish_item(trans);
    endtask
endclass
