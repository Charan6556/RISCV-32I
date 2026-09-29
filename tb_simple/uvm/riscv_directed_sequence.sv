class riscv_directed_sequence extends uvm_sequence #(riscv_transaction);

    `uvm_object_utils(riscv_directed_sequence)

    riscv_transaction trans;

    function new(string name = "riscv_directed_sequence");
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
        // setup
        send_instr(32'h0000_0000, 32'h0050_0093); // ADDI x1, x0, 5
        send_instr(32'h0000_0004, 32'h0030_0113); // ADDI x2, x0, 3

        // R type
        send_instr(32'h0000_0008, 32'h0020_81b3); // ADD
        send_instr(32'h0000_000c, 32'h4020_8233); // SUB
        send_instr(32'h0000_0010, 32'h0020_92b3); // SLL
        send_instr(32'h0000_0014, 32'h0011_2333); // SLT
        send_instr(32'h0000_0018, 32'h0011_33b3); // SLTU
        send_instr(32'h0000_001c, 32'h0020_c433); // XOR
        send_instr(32'h0000_0020, 32'h0022_d4b3); // SRL
        send_instr(32'h0000_0024, 32'h4022_d533); // SRA
        send_instr(32'h0000_0028, 32'h0020_e5b3); // OR
        send_instr(32'h0000_002c, 32'h0020_f633); // AND

        // I type
        send_instr(32'h0000_0030, 32'h0051_2693); // SLTI
        send_instr(32'h0000_0034, 32'h0051_3713); // SLTIU
        send_instr(32'h0000_0038, 32'h0030_c793); // XORI
        send_instr(32'h0000_003c, 32'h0020_e813); // ORI
        send_instr(32'h0000_0040, 32'h0030_f893); // ANDI
        send_instr(32'h0000_0044, 32'h0010_9913); // SLLI
        send_instr(32'h0000_0048, 32'h0019_5993); // SRLI
        send_instr(32'h0000_004c, 32'h4019_5a13); // SRAI

        // upper immediate
        send_instr(32'h0000_0050, 32'h0000_1ab7); // LUI
        send_instr(32'h0000_0054, 32'h0000_0b17); // AUIPC

        // stores
        send_instr(32'h0000_0058, 32'h0010_2023); // SW
        send_instr(32'h0000_005c, 32'h0020_1223); // SH
        send_instr(32'h0000_0060, 32'h0010_0323); // SB

        // loads
        send_instr(32'h0000_0064, 32'h0000_2b83); // LW
        send_instr(32'h0000_0068, 32'h0040_1c03); // LH
        send_instr(32'h0000_006c, 32'h0060_0c83); // LB
        send_instr(32'h0000_0070, 32'h0040_5d03); // LHU
        send_instr(32'h0000_0074, 32'h0060_4d83); // LBU

        // branches
        send_instr(32'h0000_0078, 32'h0010_8263); // BEQ
        send_instr(32'h0000_007c, 32'h0020_9263); // BNE
        send_instr(32'h0000_0080, 32'h0011_4263); // BLT
        send_instr(32'h0000_0084, 32'h0011_5263); // BGE
        send_instr(32'h0000_0088, 32'h0020_e263); // BLTU
        send_instr(32'h0000_008c, 32'h0011_7263); // BGEU

        // jumps
        send_instr(32'h0000_0090, 32'h0040_0e6f); // JAL
        send_instr(32'h0000_0094, 32'h044b_0ee7); // JALR
    endtask
endclass
