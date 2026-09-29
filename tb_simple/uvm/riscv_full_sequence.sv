class riscv_full_sequence extends uvm_sequence #(riscv_transaction);

    `uvm_object_utils(riscv_full_sequence)

    riscv_transaction trans;

    bit [31:0] pc;

    function new(string name = "riscv_full_sequence");
        super.new(name);
    endfunction

    task send_instr(bit [31:0] instr);
        trans = riscv_transaction::type_id::create("trans");

        start_item(trans);

        trans.pc = pc;
        trans.instr = instr;

        finish_item(trans);

        pc = pc + 4;
    endtask

    // r type instruction
    function bit [31:0] make_r(bit [6:0] funct7,
                               bit [4:0] rs2,
                               bit [4:0] rs1,
                               bit [2:0] funct3,
                               bit [4:0] rd);

        return {funct7, rs2, rs1, funct3, rd, 7'b0110011};
    endfunction

    // i type instruction
    function bit [31:0] make_i(bit [11:0] imm,
                               bit [4:0] rs1,
                               bit [2:0] funct3,
                               bit [4:0] rd);

        return {imm, rs1, funct3, rd, 7'b0010011};
    endfunction

    // load instruction
    function bit [31:0] make_load(bit [11:0] imm,
                                  bit [4:0] rs1,
                                  bit [2:0] funct3,
                                  bit [4:0] rd);

        return {imm, rs1, funct3, rd, 7'b0000011};
    endfunction

    // store instruction
    function bit [31:0] make_store(bit [11:0] imm,
                                   bit [4:0] rs2,
                                   bit [4:0] rs1,
                                   bit [2:0] funct3);

        return {imm[11:5], rs2, rs1, funct3, imm[4:0], 7'b0100011};
    endfunction

    task body();
        bit [31:0] instr;

        bit [4:0] rd;
        bit [4:0] rs1;
        bit [4:0] rs2;
        bit [4:0] shamt;

        bit [11:0] imm;

        int op;

        pc = 32'h0000_0000;

        // basic setup
        send_instr(32'h0050_0093); // ADDI x1, x0, 5
        send_instr(32'h0030_0113); // ADDI x2, x0, 3

        // r type
        send_instr(32'h0020_81b3); // ADD
        send_instr(32'h4020_8233); // SUB
        send_instr(32'h0020_92b3); // SLL
        send_instr(32'h0011_2333); // SLT
        send_instr(32'h0011_33b3); // SLTU
        send_instr(32'h0020_c433); // XOR
        send_instr(32'h0022_d4b3); // SRL
        send_instr(32'h4022_d533); // SRA
        send_instr(32'h0020_e5b3); // OR
        send_instr(32'h0020_f633); // AND

        // i type
        send_instr(32'h0051_2693); // SLTI
        send_instr(32'h0051_3713); // SLTIU
        send_instr(32'h0030_c793); // XORI
        send_instr(32'h0020_e813); // ORI
        send_instr(32'h0030_f893); // ANDI
        send_instr(32'h0010_9913); // SLLI
        send_instr(32'h0019_5993); // SRLI
        send_instr(32'h4019_5a13); // SRAI

        // upper immediate
        send_instr(32'h0000_1ab7); // LUI
        send_instr(32'h0000_0b17); // AUIPC

        // stores
        send_instr(32'h0010_2023); // SW
        send_instr(32'h0020_1223); // SH
        send_instr(32'h0010_0323); // SB

        // loads
        send_instr(32'h0000_2b83); // LW
        send_instr(32'h0040_1c03); // LH
        send_instr(32'h0060_0c83); // LB
        send_instr(32'h0040_5d03); // LHU
        send_instr(32'h0060_4d83); // LBU

        // branches
        send_instr(32'h0010_8263); // BEQ
        send_instr(32'h0020_9263); // BNE
        send_instr(32'h0011_4263); // BLT
        send_instr(32'h0011_5263); // BGE
        send_instr(32'h0020_e263); // BLTU
        send_instr(32'h0011_7263); // BGEU

        // jumps
        send_instr(32'h0040_0e6f); // JAL
        send_instr(32'h044b_0ee7); // JALR

        // hazard test
        send_instr(32'h0050_0093); // x1 = 5
        send_instr(32'h0030_8113); // x2 = x1 + 3
        send_instr(32'h0011_01b3); // x3 = x2 + x1

        send_instr(32'h0030_2023); // store x3
        send_instr(32'h0000_2203); // load x4

        send_instr(32'h0012_02b3); // load use hazard
        send_instr(32'h0042_8333); // forwarding

        send_instr(32'h0063_0463); // branch taken
        send_instr(32'h0630_0393); // flushed
        send_instr(32'h0070_0393); // branch target

        // forwarding setup
        send_instr(make_i(12'd10, 5'd0, 3'b000, 5'd1));
        send_instr(make_i(12'd20, 5'd0, 3'b000, 5'd2));

        // normal operands
        send_instr(make_r(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3));

        // ex/mem forward a
        send_instr(make_r(7'b0000000, 5'd2, 5'd3, 3'b000, 5'd4));

        // ex/mem forward b
        send_instr(make_r(7'b0000000, 5'd4, 5'd1, 3'b000, 5'd5));

        // ex/mem forward both
        send_instr(make_r(7'b0000000, 5'd5, 5'd5, 3'b000, 5'd6));

        // mem/wb forward a
        send_instr(make_i(12'd7, 5'd0, 3'b000, 5'd7));
        send_instr(32'h0000_0013);
        send_instr(make_r(7'b0000000, 5'd1, 5'd7, 3'b000, 5'd8));

        // mem/wb forward b
        send_instr(make_i(12'd9, 5'd0, 3'b000, 5'd9));
        send_instr(32'h0000_0013);
        send_instr(make_r(7'b0000000, 5'd9, 5'd1, 3'b000, 5'd10));

        // mem/wb forward both
        send_instr(make_i(12'd11, 5'd0, 3'b000, 5'd11));
        send_instr(32'h0000_0013);
        send_instr(make_r(7'b0000000, 5'd11, 5'd11, 3'b000, 5'd12));

        // ex/mem a and mem/wb b
        send_instr(make_i(12'd13, 5'd0, 3'b000, 5'd13));
        send_instr(make_i(12'd14, 5'd0, 3'b000, 5'd14));
        send_instr(make_r(7'b0000000, 5'd13, 5'd14, 3'b000, 5'd15));

        // mem/wb a and ex/mem b
        send_instr(make_i(12'd16, 5'd0, 3'b000, 5'd16));
        send_instr(make_i(12'd17, 5'd0, 3'b000, 5'd17));
        send_instr(make_r(7'b0000000, 5'd17, 5'd16, 3'b000, 5'd18));

        // memory data
        send_instr(make_i(12'd127, 5'd0, 3'b000, 5'd20));

        // byte stores
        send_instr(make_store(12'd0, 5'd20, 5'd0, 3'b000));
        send_instr(make_store(12'd1, 5'd20, 5'd0, 3'b000));
        send_instr(make_store(12'd2, 5'd20, 5'd0, 3'b000));
        send_instr(make_store(12'd3, 5'd20, 5'd0, 3'b000));

        // half stores
        send_instr(make_store(12'd8, 5'd20, 5'd0, 3'b001));
        send_instr(make_store(12'd10, 5'd20, 5'd0, 3'b001));

        // word store
        send_instr(make_store(12'd12, 5'd20, 5'd0, 3'b010));

        // memory loads
        send_instr(make_load(12'd0, 5'd0, 3'b000, 5'd21));  // LB
        send_instr(make_load(12'd8, 5'd0, 3'b001, 5'd22));  // LH
        send_instr(make_load(12'd12, 5'd0, 3'b010, 5'd23)); // LW

        // random instructions
        repeat(60) begin
            rd = $urandom_range(1, 31);
            rs1 = $urandom_range(0, 31);
            rs2 = $urandom_range(0, 31);
            shamt = $urandom_range(0, 31);

            imm = $urandom_range(0, 31);

            op = $urandom_range(0, 20);

            case(op)
                // r type
                0: instr = make_r(7'b0000000, rs2, rs1, 3'b000, rd); // ADD
                1: instr = make_r(7'b0100000, rs2, rs1, 3'b000, rd); // SUB
                2: instr = make_r(7'b0000000, rs2, rs1, 3'b001, rd); // SLL
                3: instr = make_r(7'b0000000, rs2, rs1, 3'b010, rd); // SLT
                4: instr = make_r(7'b0000000, rs2, rs1, 3'b011, rd); // SLTU
                5: instr = make_r(7'b0000000, rs2, rs1, 3'b100, rd); // XOR
                6: instr = make_r(7'b0000000, rs2, rs1, 3'b101, rd); // SRL
                7: instr = make_r(7'b0100000, rs2, rs1, 3'b101, rd); // SRA
                8: instr = make_r(7'b0000000, rs2, rs1, 3'b110, rd); // OR
                9: instr = make_r(7'b0000000, rs2, rs1, 3'b111, rd); // AND

                // i type
                10: instr = make_i(imm, rs1, 3'b000, rd); // ADDI
                11: instr = make_i(imm, rs1, 3'b010, rd); // SLTI
                12: instr = make_i(imm, rs1, 3'b011, rd); // SLTIU
                13: instr = make_i(imm, rs1, 3'b100, rd); // XORI
                14: instr = make_i(imm, rs1, 3'b110, rd); // ORI
                15: instr = make_i(imm, rs1, 3'b111, rd); // ANDI

                // shifts
                16: instr = make_i({7'b0000000, shamt}, rs1, 3'b001, rd); // SLLI
                17: instr = make_i({7'b0000000, shamt}, rs1, 3'b101, rd); // SRLI
                18: instr = make_i({7'b0100000, shamt}, rs1, 3'b101, rd); // SRAI

                // lw
                19: begin
                    imm = $urandom_range(0, 15) * 4;
                    instr = make_load(imm, 5'd0, 3'b010, rd);
                end

                // sw
                20: begin
                    imm = $urandom_range(0, 15) * 4;
                    instr = make_store(imm, rs2, 5'd0, 3'b010);
                end
            endcase

            send_instr(instr);
        end
    endtask
endclass
