//==============================================================================
// riscv_pkg.sv
//   Shared declarations for the RV32I + AXI4-Lite + UVM project.
//   Pure declarations only: types + encoding constants. NO logic.
//   Every RTL module does `import riscv_pkg::*;`
//
//   Source of truth: module-specs doc section 0. If you change an encoding,
//   change it HERE and nowhere else.
//==============================================================================
package riscv_pkg;

  //--------------------------------------------------------------------------
  // alu_op[3:0]  (module-specs 0.2)
  //   PASS_B implements LUI (result = operand B = imm_U) per design decision D1.
  //--------------------------------------------------------------------------
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

  //--------------------------------------------------------------------------
  // wb_sel[1:0]  (module-specs 0.3)  -- writeback source select
  //--------------------------------------------------------------------------
  typedef enum logic [1:0] {
    WB_ALU  = 2'b00,   // alu_result (incl. LUI/AUIPC per D1)
    WB_LOAD = 2'b01,   // load_data
    WB_PC4  = 2'b10    // pc + 4 (JAL/JALR link)
    // 2'b11 reserved
  } wb_sel_e;

  //--------------------------------------------------------------------------
  // imm_sel  -- which immediate format immgen builds
  //   Kept in ctrl_t (Option B): decoder classifies format once, immgen obeys.
  //--------------------------------------------------------------------------
  typedef enum logic [2:0] {
    IMM_I = 3'b000,
    IMM_S = 3'b001,
    IMM_B = 3'b010,
    IMM_U = 3'b011,
    IMM_J = 3'b100
  } imm_sel_e;

  //--------------------------------------------------------------------------
  // pc_sel[1:0]  (module-specs 0.4)  -- next-pc source select
  //   NOTE: pc_unit.sv currently takes pc_sel as a raw logic [1:0]. That is
  //   fine -- these constants just name the same bit patterns. Priority if
  //   multiple conditions imply a redirect: jalr > jal > branch > pc+4.
  //--------------------------------------------------------------------------
  typedef enum logic [1:0] {
    PC_PLUS4 = 2'b00,   // pc + 4
    PC_BRJAL = 2'b01,   // pc + imm  (taken branch or JAL)
    PC_JALR  = 2'b10    // (rs1 + imm) & ~1
  } pc_sel_e;

  //--------------------------------------------------------------------------
  // ctrl_t  -- the control word the decoder produces (spec §2.3).
  //   Every field below is one datapath decision. Extended with imm_sel
  //   (Option B) so immgen need not re-decode the opcode.
  //--------------------------------------------------------------------------
  typedef struct packed {
    logic       reg_write;   // rd written this instr
    wb_sel_e    wb_sel;      // writeback source (0.3)
    logic       mem_read;
    logic       mem_write;
    logic [2:0] funct3_q;    // passed through: load/store size, branch cond
    logic       alu_src_a;   // 0 = rs1, 1 = pc      (AUIPC/JAL need pc)
    logic       alu_src_b;   // 0 = rs2, 1 = imm
    alu_op_e    alu_op;      // ALU operation (0.2)
    imm_sel_e   imm_sel;     // immediate format for immgen
    logic       is_branch;
    logic       is_jal;
    logic       is_jalr;
  } ctrl_t;

  //--------------------------------------------------------------------------
  // CTRL_NOP  -- the inactive control word.
  //   decoder assigns this first, then overrides per opcode (default-then-
  //   override). Also the Stage-2 bubble control word. Every "do nothing"
  //   field takes its safe value here; datapath fields are don't-care but
  //   given defined values to avoid X and latches.
  //--------------------------------------------------------------------------
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

  //--------------------------------------------------------------------------
  // NOP instruction encoding: addi x0, x0, 0
  //   Used by TB / IF-ID bubble injection in Stage 2.
  //--------------------------------------------------------------------------
  localparam logic [31:0] NOP_INSTR = 32'h0000_0013;

endpackage : riscv_pkg
