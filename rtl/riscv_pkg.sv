// shared control types and instruction encodings
package riscv_pkg;

    // ALU operations; PASS_B is used by LUI
    typedef enum logic [3:0] {
        ALU_ADD    = 4'b0000,
        ALU_SUB    = 4'b0001,
        ALU_SLL    = 4'b0010,
        ALU_SLT    = 4'b0011,
        ALU_SLTU   = 4'b0100,
        ALU_XOR    = 4'b0101,
        ALU_SRL    = 4'b0110,
        ALU_SRA    = 4'b0111,
        ALU_OR     = 4'b1000,
        ALU_AND    = 4'b1001,
        ALU_PASS_B = 4'b1010
    } alu_op_e;

    // writeback source
    typedef enum logic [1:0] {
        WB_ALU  = 2'b00,   // ALU result, including LUI/AUIPC
        WB_LOAD = 2'b01,   // load_data
        WB_PC4  = 2'b10    // pc + 4 (JAL/JALR link)
        // 2'b11 reserved
    } wb_sel_e;

    // immediate format
    typedef enum logic [2:0] {
        IMM_I = 3'b000,
        IMM_S = 3'b001,
        IMM_B = 3'b010,
        IMM_U = 3'b011,
        IMM_J = 3'b100
    } imm_sel_e;

    // next PC source
    typedef enum logic [1:0] {
        PC_PLUS4 = 2'b00,   // pc + 4
        PC_BRJAL = 2'b01,   // pc + imm  (taken branch or JAL)
        PC_JALR  = 2'b10    // (rs1 + imm) & ~1
    } pc_sel_e;

    // decoded control word
    typedef struct packed {
        logic       reg_write;   // rd written this instr
        wb_sel_e    wb_sel;      // writeback source
        logic       mem_read;
        logic       mem_write;
        logic [2:0] funct3_q;    // passed through: load/store size, branch cond
        logic       alu_src_a;   // 0 = rs1, 1 = pc      (AUIPC/JAL need pc)
        logic       alu_src_b;   // 0 = rs2, 1 = imm
        alu_op_e    alu_op;      // ALU operation
        imm_sel_e   imm_sel;     // immediate format for immgen
        logic       is_branch;
        logic       is_jal;
        logic       is_jalr;
    } ctrl_t;

    // inactive controls for reset, flush and unrecognized opcodes
    localparam ctrl_t CTRL_NOP = '{
        reg_write : 1'b0,
        wb_sel    : WB_ALU,
        mem_read  : 1'b0,
        mem_write : 1'b0,
        funct3_q  : 3'b000,
        alu_src_a : 1'b0,
        alu_src_b : 1'b0,
        alu_op    : ALU_ADD,
        imm_sel   : IMM_I,
        is_branch : 1'b0,
        is_jal    : 1'b0,
        is_jalr   : 1'b0
    };

    // addi x0, x0, 0
    localparam logic [31:0] NOP_INSTR = 32'h0000_0013;
endpackage : riscv_pkg
