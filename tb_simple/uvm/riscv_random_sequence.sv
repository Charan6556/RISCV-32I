class riscv_random_sequence extends uvm_sequence #(riscv_transaction);

    `uvm_object_utils(riscv_random_sequence)

    riscv_transaction trans;

    function new(string name = "riscv_random_sequence");
        super.new(name);
    endfunction

    task send_instr(bit [31:0] pc, bit [31:0] instr);
        trans = riscv_transaction::type_id::create("trans");

        start_item(trans);
        trans.pc    = pc;
        trans.instr = instr;
        finish_item(trans);
    endtask

    function bit [31:0] make_r(
        bit [6:0] funct7,
        bit [4:0] rs2,
        bit [4:0] rs1,
        bit [2:0] funct3,
        bit [4:0] rd
    );

        return {funct7, rs2, rs1, funct3, rd, 7'b0110011};
    endfunction

    function bit [31:0] make_i(
        bit [11:0] imm,
        bit [4:0] rs1,
        bit [2:0] funct3,
        bit [4:0] rd
    );

        return {imm, rs1, funct3, rd, 7'b0010011};
    endfunction

    function bit [31:0] make_load(
        bit [11:0] imm,
        bit [4:0] rd
    );

        return {imm, 5'd0, 3'b010, rd, 7'b0000011};
    endfunction

    function bit [31:0] make_store(
        bit [11:0] imm,
        bit [4:0] rs2
    );

        return {
            imm[11:5],
            rs2,
            5'd0,
            3'b010,
            imm[4:0],
            7'b0100011
        };
    endfunction

    task body();
        bit [31:0] pc;
        bit [31:0] instr;

        bit [4:0] rd;
        bit [4:0] rs1;
        bit [4:0] rs2;

        bit [4:0] shamt;
        bit [11:0] imm;

        int op;

        pc = 0;

        repeat(60) begin
            rd    = $urandom_range(1, 31);
            rs1   = $urandom_range(0, 31);
            rs2   = $urandom_range(0, 31);
            shamt = $urandom_range(0, 31);
            imm   = $urandom_range(0, 31);

            op = $urandom_range(0, 20);

            case (op)
                // R type
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

                // I type
                10: instr = make_i(imm, rs1, 3'b000, rd); // ADDI
                11: instr = make_i(imm, rs1, 3'b010, rd); // SLTI
                12: instr = make_i(imm, rs1, 3'b011, rd); // SLTIU
                13: instr = make_i(imm, rs1, 3'b100, rd); // XORI
                14: instr = make_i(imm, rs1, 3'b110, rd); // ORI
                15: instr = make_i(imm, rs1, 3'b111, rd); // ANDI

                16:
                    instr = make_i(
                        {7'b0000000, shamt},
                        rs1,
                        3'b001,
                        rd
                    ); // SLLI

                17:
                    instr = make_i(
                        {7'b0000000, shamt},
                        rs1,
                        3'b101,
                        rd
                    ); // SRLI

                18:
                    instr = make_i(
                        {7'b0100000, shamt},
                        rs1,
                        3'b101,
                        rd
                    ); // SRAI

                // LW
                19:
                    instr = make_load(
                        {$urandom_range(0, 15), 2'b00},
                        rd
                    );

                // SW
                20:
                    instr = make_store(
                        {$urandom_range(0, 15), 2'b00},
                        rs2
                    );
            endcase

            send_instr(pc, instr);

            pc = pc + 4;
        end
    endtask
endclass
