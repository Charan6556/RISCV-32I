class riscv_bubblesort_sequence extends uvm_sequence #(riscv_transaction);

    `uvm_object_utils(riscv_bubblesort_sequence)

    logic [31:0] pc;

    function new(string name = "riscv_bubblesort_sequence");
        super.new(name);
    endfunction

    task send_instr(input logic [31:0] instr);
        riscv_transaction trans;

        trans = riscv_transaction::type_id::create("trans");

        start_item(trans);

        trans.pc    = pc;
        trans.instr = instr;

        finish_item(trans);

        pc = pc + 4;
    endtask

    task body();
        pc = 32'h00000000;

        // base address
        send_instr(32'h00000093); // addi x1,x0,0

        // data = 5,1,4,2,8
        send_instr(32'h00500393); // addi x7,x0,5
        send_instr(32'h0070a023); // sw x7,0(x1)

        send_instr(32'h00100393); // addi x7,x0,1
        send_instr(32'h0070a223); // sw x7,4(x1)

        send_instr(32'h00400393); // addi x7,x0,4
        send_instr(32'h0070a423); // sw x7,8(x1)

        send_instr(32'h00200393); // addi x7,x0,2
        send_instr(32'h0070a623); // sw x7,12(x1)

        send_instr(32'h00800393); // addi x7,x0,8
        send_instr(32'h0070a823); // sw x7,16(x1)

        // setup
        send_instr(32'h00500113); // addi x2,x0,5
        send_instr(32'h00000193); // addi x3,x0,0

        // outer loop
        send_instr(32'h00000213); // addi x4,x0,0
        send_instr(32'hfff10293); // addi x5,x2,-1
        send_instr(32'h403282b3); // sub x5,x5,x3

        // inner loop
        send_instr(32'h00221313); // slli x6,x4,2
        send_instr(32'h00608333); // add x6,x1,x6

        send_instr(32'h00032383); // lw x7,0(x6)
        send_instr(32'h00432403); // lw x8,4(x6)

        send_instr(32'h02744263); // blt x8,x7,swap

        send_instr(32'h00120213); // addi x4,x4,1
        send_instr(32'hfe5244e3); // blt x4,x5,inner

        send_instr(32'h00118193); // addi x3,x3,1
        send_instr(32'hfff10513); // addi x10,x2,-1
        send_instr(32'hfca1c8e3); // blt x3,x10,outer

        // done
        send_instr(32'h00100593); // addi x11,x0,1
        send_instr(32'h10b02023); // sw x11,256(x0)

        send_instr(32'h0000006f); // jal x0,0

        // swap
        send_instr(32'h00832023); // sw x8,0(x6)
        send_instr(32'h00732223); // sw x7,4(x6)
        send_instr(32'hfd9ff06f); // jal x0,noswap
    endtask
endclass
