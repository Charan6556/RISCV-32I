//==============================================================================
// riscv_core_top.sv
//   Top-level single-cycle RV32I core. Wires the eight sub-modules together
//   and hosts the four convergence points that live nowhere else:
//     (1) the two ALU source muxes (mux A, mux B)
//     (2) the two target adders (br_jal_target, jalr_target)
//     (3) the 3-input writeback mux
//     (4) the pc_sel combining logic (folds is_jal, is_jalr, is_branch·br_taken)
//
//   Boundary pins match spec §2.2 / Addendum A.1 exactly. This same boundary
//   becomes the AXI4-Lite master port in Stage 5 -- the migration replaces
//   the memory model, not this module's ports.
//==============================================================================
module riscv_core_top
  import riscv_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // Instruction memory interface (combinational in Stage 1)
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,

    // Data memory interface (combinational in Stage 1; wstrb becomes AXI WSTRB later)
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic [3:0]  dmem_wstrb,
    output logic        dmem_req,
    input  logic [31:0] dmem_rdata
);

    // -------------------------------------------------------------------
    // Internal wires: everything connecting sub-modules to each other.
    // Ports on this module (imem_*, dmem_*) do NOT get redeclared here.
    // -------------------------------------------------------------------
    ctrl_t              ctrl;

    logic [31:0]        pc, pc4;
    logic [31:0]        imm;
    logic [31:0]        rs1_data, rs2_data;
    logic [31:0]        alu_op_a, alu_op_b;
    logic [31:0]        alu_result;
    logic [31:0]        load_data;
    logic [31:0]        wb_data;

    logic [31:0]        br_jal_target;
    logic [31:0]        jalr_target;
    logic               br_taken;
    logic [1:0]         pc_sel;

    // Register indices are fixed slices of the instruction (§1.3):
    logic [4:0]         rs1_addr, rs2_addr, rd_addr;
    assign rs1_addr = imem_rdata[19:15];
    assign rs2_addr = imem_rdata[24:20];
    assign rd_addr  = imem_rdata[11:7];

    // -------------------------------------------------------------------
    // pc_unit -- IF: holds PC, computes pc+4, selects next-PC
    // -------------------------------------------------------------------
    pc_unit u_pc_unit (
        .clk           (clk),
        .rst_n         (rst_n),
        .pc_en         (1'b1),          // Stage 1: never stalls; Stage 2 wires to hazard unit
        .pc_sel        (pc_sel),
        .br_jal_target (br_jal_target),
        .jalr_target   (jalr_target),
        .pc            (pc),
        .pc4           (pc4)
    );

    // PC drives the instruction-memory address port
    assign imem_addr = pc;

    // -------------------------------------------------------------------
    // decoder -- ID: instruction bits -> ctrl_t control word
    // -------------------------------------------------------------------
    decoder u_decoder (
        .instr (imem_rdata),
        .ctrl  (ctrl)
    );

    // -------------------------------------------------------------------
    // regfile -- ID: async 2 reads, sync 1 write; x0 forced to zero
    // -------------------------------------------------------------------
    regfile u_regfile (
        .clk       (clk),
        .rst_n     (rst_n),
        .rs1_addr  (rs1_addr),
        .rs2_addr  (rs2_addr),
        .rd_addr   (rd_addr),
        .rd_we     (ctrl.reg_write),
        .rd_data   (wb_data),
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
    );

    // -------------------------------------------------------------------
    // immgen -- ID: builds 32-bit immediate per format
    // -------------------------------------------------------------------
    immgen u_immgen (
        .instr   (imem_rdata),
        .imm_sel (ctrl.imm_sel),
        .imm     (imm)
    );

    // -------------------------------------------------------------------
    // Convergence point 1: the two ALU source muxes
    //   Mux A picks rs1_data (default) or pc (AUIPC, JAL)
    //   Mux B picks rs2_data (R-type) or imm (everything else)
    // -------------------------------------------------------------------
    assign alu_op_a = ctrl.alu_src_a ? pc  : rs1_data;
    assign alu_op_b = ctrl.alu_src_b ? imm : rs2_data;

    // -------------------------------------------------------------------
    // alu -- EX: 11 combinational ops
    // -------------------------------------------------------------------
    alu u_alu (
        .op_a       (alu_op_a),
        .op_b       (alu_op_b),
        .alu_op     (ctrl.alu_op),
        .alu_result (alu_result)
    );

    // -------------------------------------------------------------------
    // branch_cond -- EX: 6 comparisons, gated by is_branch
    //   Takes rs1/rs2 pre-mux (branches compare registers, never immediates)
    // -------------------------------------------------------------------
    branch_cond u_branch_cond (
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data),
        .funct3    (ctrl.funct3_q),
        .is_branch (ctrl.is_branch),
        .br_taken  (br_taken)
    );

    // -------------------------------------------------------------------
    // lsu -- MEM: byte lanes + wstrb; alu_result is the memory address
    // -------------------------------------------------------------------
    lsu u_lsu (
        .addr        (alu_result),
        .funct3      (ctrl.funct3_q),
        .mem_read    (ctrl.mem_read),
        .mem_write   (ctrl.mem_write),
        .store_data  (rs2_data),
        .dmem_rdata  (dmem_rdata),
        .dmem_addr   (dmem_addr),
        .dmem_wdata  (dmem_wdata),
        .dmem_wstrb  (dmem_wstrb),
        .dmem_req    (dmem_req),
        .load_data   (load_data)
    );

    // -------------------------------------------------------------------
    // Convergence point 2: target adders
    //   br_jal_target = pc + imm    (BRANCH taken, JAL)
    //   jalr_target   = (rs1 + imm) & ~1   (JALR; LSB forced to 0)
    //
    // These live here because they need signals from multiple modules
    // (pc from pc_unit, imm from immgen, rs1_data from regfile) that no
    // single module owns.
    // -------------------------------------------------------------------
    assign br_jal_target = pc + imm;
    assign jalr_target   = (rs1_data + imm) & ~32'h1;

    // -------------------------------------------------------------------
    // Convergence point 3: writeback mux (3 inputs, selected by wb_sel)
    // -------------------------------------------------------------------
    always_comb begin
        unique case (ctrl.wb_sel)
            WB_ALU:  wb_data = alu_result;
            WB_LOAD: wb_data = load_data;
            WB_PC4:  wb_data = pc4;
            default: wb_data = alu_result;   // no latch; safe default
        endcase
    end

    // -------------------------------------------------------------------
    // Convergence point 4: pc_sel combining logic
    //   Priority: jalr > jal > taken-branch > pc+4
    //   JAL and taken-branches share pc_sel=1 (both go to br_jal_target)
    // -------------------------------------------------------------------
    always_comb begin
        if      (ctrl.is_jalr)                  pc_sel = 2'b10;   // jalr_target
        else if (ctrl.is_jal)                   pc_sel = 2'b01;   // br_jal_target
        else if (ctrl.is_branch && br_taken)    pc_sel = 2'b01;   // br_jal_target
        else                                    pc_sel = 2'b00;   // pc + 4
    end

endmodule