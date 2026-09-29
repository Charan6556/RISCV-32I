class riscv_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(riscv_scoreboard)

    uvm_analysis_imp #(riscv_transaction, riscv_scoreboard) sb_port;

    bit [31:0] ref_regs [0:31];
    bit [7:0]  ref_mem  [0:4095];

    bit [31:0] instr_mem [0:1023];
    bit        instr_valid [0:1023];

    bit [31:0] expected_pc;
    bit        pc_valid;

    int commit_count;
    int error_count;

    function new(string name = "riscv_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        sb_port = new("sb_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        foreach (ref_regs[i])
            ref_regs[i] = 0;

        foreach (ref_mem[i])
            ref_mem[i] = 0;

        foreach (instr_mem[i]) begin
            instr_mem[i] = 32'h00000013;
            instr_valid[i] = 0;
        end

        pc_valid = 0;
        commit_count = 0;
        error_count = 0;
    endfunction

    // immediate functions
    function bit [31:0] get_i_imm(bit [31:0] instr);
        return {{20{instr[31]}}, instr[31:20]};
    endfunction

    function bit [31:0] get_s_imm(bit [31:0] instr);
        return {{20{instr[31]}}, instr[31:25], instr[11:7]};
    endfunction

    function bit [31:0] get_b_imm(bit [31:0] instr);
        return {{19{instr[31]}}, instr[31], instr[7],
                instr[30:25], instr[11:8], 1'b0};
    endfunction

    function bit [31:0] get_u_imm(bit [31:0] instr);
        return {instr[31:12], 12'b0};
    endfunction

    function bit [31:0] get_j_imm(bit [31:0] instr);
        return {{11{instr[31]}}, instr[31], instr[19:12],
                instr[20], instr[30:21], 1'b0};
    endfunction

    function bit [7:0] read_byte(bit [31:0] addr);
        return ref_mem[addr[11:0]];
    endfunction

    function void write_byte(bit [31:0] addr, bit [7:0] data);
        ref_mem[addr[11:0]] = data;
    endfunction

    function void write(riscv_transaction trans);
        // save fetched instruction
        instr_mem[trans.pc[11:2]] = trans.instr;
        instr_valid[trans.pc[11:2]] = 1'b1;

        // check only committed instructions
        if (trans.commit_valid)
            check_instruction(trans);
    endfunction

    function void check_instruction(riscv_transaction trans);
        bit [31:0] instr;

        bit [6:0] opcode;
        bit [2:0] funct3;

        bit [4:0] rs1;
        bit [4:0] rs2;
        bit [4:0] rd;

        bit [31:0] a;
        bit [31:0] b;

        bit [31:0] result;
        bit [31:0] addr;
        bit [31:0] next_pc;

        bit exp_we;
        bit branch_taken;

        commit_count++;

        if (!instr_valid[trans.commit_pc[11:2]]) begin
            error_count++;

            `uvm_error("SCB",
                $sformatf("Instruction not found for PC=%08h",
                trans.commit_pc))

            return;
        end

        instr = instr_mem[trans.commit_pc[11:2]];

        opcode = instr[6:0];
        funct3 = instr[14:12];

        rs1 = instr[19:15];
        rs2 = instr[24:20];
        rd  = instr[11:7];

        a = ref_regs[rs1];
        b = ref_regs[rs2];

        result = 0;
        exp_we = 0;
        branch_taken = 0;

        next_pc = trans.commit_pc + 4;

        // check PC
        if (pc_valid && trans.commit_pc != expected_pc) begin
            error_count++;

            `uvm_error("SCB",
                $sformatf("PC FAIL expected=%08h got=%08h",
                expected_pc,
                trans.commit_pc))
        end

        case (opcode)
            // R type
            7'b0110011: begin
                exp_we = (rd != 0);

                case (funct3)
                    3'b000:
                        result = instr[30] ? a - b : a + b;

                    3'b001:
                        result = a << b[4:0];

                    3'b010:
                        result = ($signed(a) < $signed(b));

                    3'b011:
                        result = (a < b);

                    3'b100:
                        result = a ^ b;

                    3'b101: begin
                        // keep the arithmetic shift in a signed expression
                        if (instr[30])
                            result = $signed(a) >>> b[4:0];
                        else
                            result = a >> b[4:0];
                    end

                    3'b110:
                        result = a | b;

                    3'b111:
                        result = a & b;
                endcase
            end

            // I type
            7'b0010011: begin
                exp_we = (rd != 0);

                case (funct3)
                    3'b000:
                        result = a + get_i_imm(instr);

                    3'b010:
                        result =
                        ($signed(a) < $signed(get_i_imm(instr)));

                    3'b011:
                        result = (a < get_i_imm(instr));

                    3'b100:
                        result = a ^ get_i_imm(instr);

                    3'b110:
                        result = a | get_i_imm(instr);

                    3'b111:
                        result = a & get_i_imm(instr);

                    3'b001:
                        result = a << instr[24:20];

                    3'b101: begin
                        // keep the arithmetic shift in a signed expression
                        if (instr[30])
                            result = $signed(a) >>> instr[24:20];
                        else
                            result = a >> instr[24:20];
                    end
                endcase
            end

            // load
            7'b0000011: begin
                exp_we = (rd != 0);

                addr = a + get_i_imm(instr);

                case (funct3)
                    // LB
                    3'b000:
                        result =
                        {{24{read_byte(addr)[7]}},
                        read_byte(addr)};

                    // LH
                    3'b001:
                        result =
                        {{16{read_byte(addr + 1)[7]}},
                        read_byte(addr + 1),
                        read_byte(addr)};

                    // LW
                    3'b010:
                        result =
                        {read_byte(addr + 3),
                         read_byte(addr + 2),
                         read_byte(addr + 1),
                         read_byte(addr)};

                    // LBU
                    3'b100:
                        result =
                        {24'b0, read_byte(addr)};

                    // LHU
                    3'b101:
                        result =
                        {16'b0,
                         read_byte(addr + 1),
                         read_byte(addr)};
                endcase
            end

            // store
            7'b0100011: begin
                addr = a + get_s_imm(instr);

                case (funct3)
                    // SB
                    3'b000:
                        write_byte(addr, b[7:0]);

                    // SH
                    3'b001: begin
                        write_byte(addr,     b[7:0]);
                        write_byte(addr + 1, b[15:8]);
                    end

                    // SW
                    3'b010: begin
                        write_byte(addr,     b[7:0]);
                        write_byte(addr + 1, b[15:8]);
                        write_byte(addr + 2, b[23:16]);
                        write_byte(addr + 3, b[31:24]);
                    end
                endcase
            end

            // branch
            7'b1100011: begin
                case (funct3)
                    3'b000:
                        branch_taken = (a == b);

                    3'b001:
                        branch_taken = (a != b);

                    3'b100:
                        branch_taken =
                        ($signed(a) < $signed(b));

                    3'b101:
                        branch_taken =
                        ($signed(a) >= $signed(b));

                    3'b110:
                        branch_taken = (a < b);

                    3'b111:
                        branch_taken = (a >= b);
                endcase

                if (branch_taken)
                    next_pc =
                    trans.commit_pc + get_b_imm(instr);
            end

            // LUI
            7'b0110111: begin
                exp_we = (rd != 0);
                result = get_u_imm(instr);
            end

            // AUIPC
            7'b0010111: begin
                exp_we = (rd != 0);

                result =
                trans.commit_pc + get_u_imm(instr);
            end

            // JAL
            7'b1101111: begin
                exp_we = (rd != 0);

                result = trans.commit_pc + 4;

                next_pc =
                trans.commit_pc + get_j_imm(instr);
            end

            // JALR
            7'b1100111: begin
                exp_we = (rd != 0);

                result = trans.commit_pc + 4;

                next_pc =
                (a + get_i_imm(instr)) & 32'hffff_fffe;
            end
        endcase

        // check writeback
        if (exp_we) begin
            if (!trans.commit_reg_write) begin
                error_count++;

                `uvm_error("SCB",
                    $sformatf("Missing register write PC=%08h",
                    trans.commit_pc))
            end

            else if ((trans.commit_rd != rd) ||
                     (trans.commit_data != result)) begin
                error_count++;

                `uvm_error("SCB",
                    $sformatf(
                    "REG FAIL PC=%08h expected x%0d=%08h got x%0d=%08h",
                    trans.commit_pc,
                    rd,
                    result,
                    trans.commit_rd,
                    trans.commit_data))
            end

            else begin
                `uvm_info("SCB",
                    $sformatf(
                    "PASS PC=%08h x%0d=%08h",
                    trans.commit_pc,
                    rd,
                    result),
                    UVM_LOW)
            end

            ref_regs[rd] = result;
        end

        else if (trans.commit_reg_write &&
                 trans.commit_rd != 0) begin
            error_count++;

            `uvm_error("SCB",
                $sformatf(
                "Unexpected register write PC=%08h",
                trans.commit_pc))
        end

        // x0 always zero
        ref_regs[0] = 0;

        expected_pc = next_pc;
        pc_valid = 1;
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("SCB",
            $sformatf(
            "COMMITS=%0d ERRORS=%0d",
            commit_count,
            error_count),
            UVM_NONE)
    endfunction
endclass
