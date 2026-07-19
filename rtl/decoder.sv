//==============================================================================
// decoder.sv
//   instr -> ctrl_t. Pure combinational lookup, no state.
//   Structure matches the paper table row-for-row so the rebuild pass is
//   straight transcription:
//     - default CTRL_NOP first, then override per opcode
//     - funct3_q passed through globally (no arm needs to touch it)
//     - inner cases ONLY on OP-IMM and OP, where alu_op varies by funct3
//     - LOAD/STORE/BRANCH have no inner case: same ctrl fields for every
//       funct3 within the opcode; the funct3 travels in funct3_q to the
//       consumer (LSU or branch_cond)
//==============================================================================
module decoder
  import riscv_pkg::*;
(
    input  logic [31:0] instr,
    output ctrl_t       ctrl
);

    // Fixed-position field slices (RV32I keeps opcode/funct3/rs/rd/funct7
    // in the same bit positions across all six formats).
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       f7_bit;   // instr[30] -- distinguishes ADD/SUB, SRL/SRA, SRLI/SRAI

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign f7_bit = instr[30];

    always_comb begin
        // ---- default: NOP (all inactive) --------------------------------
        ctrl          = CTRL_NOP;
        ctrl.funct3_q = funct3;   // passthrough for LSU and branch_cond;
                                  // harmless don't-care elsewhere

        unique case (opcode)

            // -------- LUI --------
            7'b0110111: begin
                ctrl.reg_write = 1'b1;
                ctrl.alu_src_b = 1'b1;
                ctrl.alu_op    = ALU_PASS_B;   // D1: imm rides through the ALU
                ctrl.imm_sel   = IMM_U;
            end

            // -------- AUIPC --------
            7'b0010111: begin
                ctrl.reg_write = 1'b1;
                ctrl.alu_src_a = 1'b1;         // pc as operand A
                ctrl.alu_src_b = 1'b1;
                ctrl.alu_op    = ALU_ADD;
                ctrl.imm_sel   = IMM_U;
            end

            // -------- JAL --------
            7'b1101111: begin
                ctrl.reg_write = 1'b1;
                ctrl.wb_sel    = WB_PC4;       // link value = pc + 4
                ctrl.alu_src_a = 1'b1;         // target = pc + imm_J
                ctrl.alu_src_b = 1'b1;
                ctrl.alu_op    = ALU_ADD;
                ctrl.imm_sel   = IMM_J;
                ctrl.is_jal    = 1'b1;
            end

            // -------- JALR --------
            7'b1100111: begin
                // Only funct3=000 is legal; other values fall through as NOP.
                if (funct3 == 3'b000) begin
                    ctrl.reg_write = 1'b1;
                    ctrl.wb_sel    = WB_PC4;
                    ctrl.alu_src_b = 1'b1;     // target = rs1 + imm_I, LSB cleared in top
                    ctrl.alu_op    = ALU_ADD;
                    ctrl.imm_sel   = IMM_I;
                    ctrl.is_jalr   = 1'b1;
                end
            end

            // -------- BRANCH (all 6 share these ctrl fields) --------
            7'b1100011: begin
                ctrl.imm_sel   = IMM_B;
                ctrl.is_branch = 1'b1;
                // No reg_write, no ALU use for the compare -- branch_cond
                // does the comparison using funct3_q.
            end

            // -------- LOAD (all 5 share these ctrl fields) --------
            7'b0000011: begin
                ctrl.reg_write = 1'b1;
                ctrl.wb_sel    = WB_LOAD;
                ctrl.mem_read  = 1'b1;
                ctrl.alu_src_b = 1'b1;         // address = rs1 + imm_I
                ctrl.alu_op    = ALU_ADD;
                ctrl.imm_sel   = IMM_I;
                // funct3_q (already assigned) carries the size to LSU.
            end

            // -------- STORE (all 3 share these ctrl fields) --------
            7'b0100011: begin
                ctrl.mem_write = 1'b1;
                ctrl.alu_src_b = 1'b1;         // address = rs1 + imm_S
                ctrl.alu_op    = ALU_ADD;
                ctrl.imm_sel   = IMM_S;
                // funct3_q carries the size to LSU.
            end

            // -------- OP-IMM (alu_op varies by funct3) --------
            7'b0010011: begin
                ctrl.reg_write = 1'b1;
                ctrl.alu_src_b = 1'b1;
                ctrl.imm_sel   = IMM_I;

                unique case (funct3)
                    3'b000: ctrl.alu_op = ALU_ADD;   // ADDI  -- f7_bit is part of imm here!
                    3'b010: ctrl.alu_op = ALU_SLT;   // SLTI
                    3'b011: ctrl.alu_op = ALU_SLTU;  // SLTIU (imm sign-extended, compare unsigned)
                    3'b100: ctrl.alu_op = ALU_XOR;   // XORI
                    3'b110: ctrl.alu_op = ALU_OR;    // ORI
                    3'b111: ctrl.alu_op = ALU_AND;   // ANDI

                    3'b001: ctrl.alu_op = ALU_SLL;   // SLLI (funct7 must be 0)
                    3'b101: begin                    // SRLI vs SRAI, distinguished by inst[30]
                        ctrl.alu_op = f7_bit ? ALU_SRA : ALU_SRL;
                    end

                    default: ; // NOP baseline
                endcase
            end

            // -------- OP (alu_op varies by funct3 + inst[30]) --------
            7'b0110011: begin
                ctrl.reg_write = 1'b1;
                // alu_src_a = 0 (rs1), alu_src_b = 0 (rs2) -- both are NOP defaults

                unique case (funct3)
                    3'b000: ctrl.alu_op = f7_bit ? ALU_SUB : ALU_ADD;  // SUB vs ADD
                    3'b001: ctrl.alu_op = ALU_SLL;
                    3'b010: ctrl.alu_op = ALU_SLT;
                    3'b011: ctrl.alu_op = ALU_SLTU;
                    3'b100: ctrl.alu_op = ALU_XOR;
                    3'b101: ctrl.alu_op = f7_bit ? ALU_SRA : ALU_SRL;  // SRA vs SRL
                    3'b110: ctrl.alu_op = ALU_OR;
                    3'b111: ctrl.alu_op = ALU_AND;

                    default: ; // unreachable in RV32I
                endcase
            end

            // -------- FENCE, ECALL, EBREAK, illegal -> NOP (spec §1.1) --------
            default: ; // ctrl already CTRL_NOP with funct3_q passthrough

        endcase
    end

endmodule