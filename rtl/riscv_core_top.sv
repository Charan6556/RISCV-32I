module riscv_core_top
    import riscv_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // instruction memory
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,

    // data memory
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic [3:0]  dmem_wstrb,
    output logic        dmem_req,
    input  logic [31:0] dmem_rdata
);

    // IF stage
    logic [31:0] pc;
    logic [31:0] pc4;
    logic [1:0]  pc_sel;
    logic        pc_en;

    logic [31:0] br_jal_target;
    logic [31:0] jalr_target;

    // IF ID signals
    logic [31:0] if_id_pc;
    logic [31:0] if_id_pc4;
    logic [31:0] if_id_instr;
    logic        if_id_valid;

    logic        if_id_stall;
    logic        if_id_flush;

    // ID stage
    ctrl_t       id_ctrl;

    logic [4:0]  id_rs1;
    logic [4:0]  id_rs2;
    logic [4:0]  id_rd;

    logic [31:0] id_rs1_data;
    logic [31:0] id_rs2_data;
    logic [31:0] id_rs1_value;
    logic [31:0] id_rs2_value;

    logic [31:0] id_imm;

    // ID EX signals
    logic [31:0] id_ex_pc;
    logic [31:0] id_ex_pc4;

    logic [31:0] id_ex_rs1_data;
    logic [31:0] id_ex_rs2_data;
    logic [31:0] id_ex_imm;

    logic [4:0]  id_ex_rs1;
    logic [4:0]  id_ex_rs2;
    logic [4:0]  id_ex_rd;

    ctrl_t       id_ex_ctrl;
    logic        id_ex_valid;

    logic        id_ex_flush;

    // forwarding signals
    logic [1:0]  forward_a;
    logic [1:0]  forward_b;

    logic [31:0] ex_rs1_forwarded;
    logic [31:0] ex_rs2_forwarded;
    logic [31:0] ex_mem_forward_data;

    // hazard signal
    logic        hazard_stall;

    // EX stage
    logic [31:0] ex_alu_a;
    logic [31:0] ex_alu_b;
    logic [31:0] ex_alu_result;

    logic        ex_br_taken;
    logic        ex_redirect;

    // EX MEM signals
    logic [31:0] ex_mem_alu_result;
    logic [31:0] ex_mem_store_data;
    logic [31:0] ex_mem_pc4;

    logic [4:0]  ex_mem_rd;

    ctrl_t       ex_mem_ctrl;
    logic        ex_mem_valid;

    // MEM stage
    logic [31:0] mem_load_data;

    // MEM WB signals
    logic [31:0] mem_wb_alu_result;
    logic [31:0] mem_wb_load_data;
    logic [31:0] mem_wb_pc4;

    logic [4:0]  mem_wb_rd;

    ctrl_t       mem_wb_ctrl;
    logic        mem_wb_valid;

    // WB stage
    logic [31:0] wb_data;

    // pc
    assign pc_en = !hazard_stall;

    pc_unit u_pc_unit (
        .clk           (clk),
        .rst_n         (rst_n),
        .pc_en         (pc_en),
        .pc_sel        (pc_sel),
        .br_jal_target (br_jal_target),
        .jalr_target   (jalr_target),
        .pc            (pc),
        .pc4           (pc4)
    );

    assign imem_addr = pc;

    // IF ID register
    assign if_id_stall = hazard_stall;
    assign if_id_flush = ex_redirect;

    if_id_reg u_if_id (
        .clk       (clk),
        .rst_n     (rst_n),
        .stall     (if_id_stall),
        .flush     (if_id_flush),

        .pc_in     (pc),
        .pc4_in    (pc4),
        .instr_in  (imem_rdata),
        .valid_in  (1'b1),

        .pc_out    (if_id_pc),
        .pc4_out   (if_id_pc4),
        .instr_out (if_id_instr),
        .valid_out (if_id_valid)
    );

    // register addresses
    assign id_rs1 = if_id_instr[19:15];
    assign id_rs2 = if_id_instr[24:20];
    assign id_rd  = if_id_instr[11:7];

    // decoder
    decoder u_decoder (
        .instr (if_id_instr),
        .ctrl  (id_ctrl)
    );

    // register file
    regfile u_regfile (
        .clk       (clk),
        .rst_n     (rst_n),

        .rs1_addr  (id_rs1),
        .rs2_addr  (id_rs2),

        .rd_addr   (mem_wb_rd),
        .rd_we     (mem_wb_ctrl.reg_write &&
                    mem_wb_valid),

        .rd_data   (wb_data),

        .rs1_data  (id_rs1_data),
        .rs2_data  (id_rs2_data)
    );

    // WB bypass handles a write and decode read in the same cycle
    always_comb begin
        id_rs1_value = id_rs1_data;
        id_rs2_value = id_rs2_data;

        if (mem_wb_valid &&
            mem_wb_ctrl.reg_write &&
            (mem_wb_rd != 5'b0) &&
            (mem_wb_rd == id_rs1))

            id_rs1_value = wb_data;

        if (mem_wb_valid &&
            mem_wb_ctrl.reg_write &&
            (mem_wb_rd != 5'b0) &&
            (mem_wb_rd == id_rs2))

            id_rs2_value = wb_data;
    end

    // immediate
    immgen u_immgen (
        .instr   (if_id_instr),
        .imm_sel (id_ctrl.imm_sel),
        .imm     (id_imm)
    );

    // hazard unit
    hazard_unit u_hazard (
        .id_ex_mem_read (
            id_ex_ctrl.mem_read &&
            id_ex_valid
        ),

        .id_ex_rd   (id_ex_rd),

        .if_id_rs1  (id_rs1),
        .if_id_rs2  (id_rs2),

        .stall      (hazard_stall)
    );

    // insert a bubble on a load-use stall; flush on a redirect
    assign id_ex_flush =
        ex_redirect || hazard_stall;

    // ID EX register
    id_ex_reg u_id_ex (
        .clk          (clk),
        .rst_n        (rst_n),
        .flush        (id_ex_flush),

        .pc_in        (if_id_pc),
        .pc4_in       (if_id_pc4),

        .rs1_data_in  (id_rs1_value),
        .rs2_data_in  (id_rs2_value),
        .imm_in       (id_imm),

        .rs1_in       (id_rs1),
        .rs2_in       (id_rs2),
        .rd_in        (id_rd),

        .ctrl_in      (id_ctrl),
        .valid_in     (if_id_valid),

        .pc_out       (id_ex_pc),
        .pc4_out      (id_ex_pc4),

        .rs1_data_out (id_ex_rs1_data),
        .rs2_data_out (id_ex_rs2_data),
        .imm_out      (id_ex_imm),

        .rs1_out      (id_ex_rs1),
        .rs2_out      (id_ex_rs2),
        .rd_out       (id_ex_rd),

        .ctrl_out     (id_ex_ctrl),
        .valid_out    (id_ex_valid)
    );

    // forwarding unit
    forwarding_unit u_forwarding (
        .id_ex_rs1        (id_ex_rs1),
        .id_ex_rs2        (id_ex_rs2),

        .ex_mem_rd        (ex_mem_rd),

        // load data is available in MEM/WB, not EX/MEM
        .ex_mem_reg_write (
            ex_mem_ctrl.reg_write &&
            ex_mem_valid &&
            (ex_mem_ctrl.wb_sel != WB_LOAD)
        ),

        .mem_wb_rd        (mem_wb_rd),

        .mem_wb_reg_write (
            mem_wb_ctrl.reg_write &&
            mem_wb_valid
        ),

        .forward_a        (forward_a),
        .forward_b        (forward_b)
    );

    // EX MEM forward data
    always_comb begin
        unique case (ex_mem_ctrl.wb_sel)
            WB_ALU:
                ex_mem_forward_data = ex_mem_alu_result;

            WB_PC4:
                ex_mem_forward_data = ex_mem_pc4;

            default:
                ex_mem_forward_data = ex_mem_alu_result;
        endcase
    end

    // forwarding mux
    always_comb begin
        unique case (forward_a)
            2'b00:
                ex_rs1_forwarded = id_ex_rs1_data;

            2'b01:
                ex_rs1_forwarded = wb_data;

            2'b10:
                ex_rs1_forwarded = ex_mem_forward_data;

            default:
                ex_rs1_forwarded = id_ex_rs1_data;
        endcase

        unique case (forward_b)
            2'b00:
                ex_rs2_forwarded = id_ex_rs2_data;

            2'b01:
                ex_rs2_forwarded = wb_data;

            2'b10:
                ex_rs2_forwarded = ex_mem_forward_data;

            default:
                ex_rs2_forwarded = id_ex_rs2_data;
        endcase
    end

    // alu inputs
    assign ex_alu_a =
        id_ex_ctrl.alu_src_a ?
        id_ex_pc :
        ex_rs1_forwarded;

    assign ex_alu_b =
        id_ex_ctrl.alu_src_b ?
        id_ex_imm :
        ex_rs2_forwarded;

    // alu
    alu u_alu (
        .op_a       (ex_alu_a),
        .op_b       (ex_alu_b),
        .alu_op     (id_ex_ctrl.alu_op),
        .alu_result (ex_alu_result)
    );

    // branch check
    branch_cond u_branch_cond (
        .rs1_data  (ex_rs1_forwarded),
        .rs2_data  (ex_rs2_forwarded),
        .funct3    (id_ex_ctrl.funct3_q),
        .is_branch (id_ex_ctrl.is_branch),
        .br_taken  (ex_br_taken)
    );

    // branch target
    assign br_jal_target =
        id_ex_pc + id_ex_imm;

    // jalr target
    assign jalr_target =
        (ex_rs1_forwarded + id_ex_imm)
        & ~32'h1;

    // redirect
    assign ex_redirect =
        id_ex_valid &&
        (
            id_ex_ctrl.is_jal ||
            id_ex_ctrl.is_jalr ||
            (id_ex_ctrl.is_branch &&
             ex_br_taken)
        );

    // pc select
    always_comb begin
        if (id_ex_valid &&
            id_ex_ctrl.is_jalr)

            pc_sel = PC_JALR;

        else if (id_ex_valid &&
                 id_ex_ctrl.is_jal)

            pc_sel = PC_BRJAL;

        else if (id_ex_valid &&
                 id_ex_ctrl.is_branch &&
                 ex_br_taken)

            pc_sel = PC_BRJAL;

        else
            pc_sel = PC_PLUS4;
    end

    // EX MEM register
    ex_mem_reg u_ex_mem (
        .clk            (clk),
        .rst_n          (rst_n),

        .alu_result_in  (ex_alu_result),
        .store_data_in  (ex_rs2_forwarded),

        .pc4_in         (id_ex_pc4),
        .rd_in          (id_ex_rd),

        .ctrl_in        (id_ex_ctrl),
        .valid_in       (id_ex_valid),

        .alu_result_out (ex_mem_alu_result),
        .store_data_out (ex_mem_store_data),

        .pc4_out        (ex_mem_pc4),
        .rd_out         (ex_mem_rd),

        .ctrl_out       (ex_mem_ctrl),
        .valid_out      (ex_mem_valid)
    );

    // load store unit
    lsu u_lsu (
        .addr       (ex_mem_alu_result),
        .funct3     (ex_mem_ctrl.funct3_q),

        .mem_read   (
            ex_mem_ctrl.mem_read &&
            ex_mem_valid
        ),

        .mem_write  (
            ex_mem_ctrl.mem_write &&
            ex_mem_valid
        ),

        .store_data (ex_mem_store_data),

        .dmem_rdata (dmem_rdata),

        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_wstrb (dmem_wstrb),
        .dmem_req   (dmem_req),

        .load_data  (mem_load_data)
    );

    // MEM WB register
    mem_wb_reg u_mem_wb (
        .clk            (clk),
        .rst_n          (rst_n),

        .alu_result_in  (ex_mem_alu_result),
        .load_data_in   (mem_load_data),

        .pc4_in         (ex_mem_pc4),
        .rd_in          (ex_mem_rd),

        .ctrl_in        (ex_mem_ctrl),
        .valid_in       (ex_mem_valid),

        .alu_result_out (mem_wb_alu_result),
        .load_data_out  (mem_wb_load_data),

        .pc4_out        (mem_wb_pc4),
        .rd_out         (mem_wb_rd),

        .ctrl_out       (mem_wb_ctrl),
        .valid_out      (mem_wb_valid)
    );

    // write back
    always_comb begin
        unique case (mem_wb_ctrl.wb_sel)
            WB_ALU:
                wb_data = mem_wb_alu_result;

            WB_LOAD:
                wb_data = mem_wb_load_data;

            WB_PC4:
                wb_data = mem_wb_pc4;

            default:
                wb_data = mem_wb_alu_result;
        endcase
    end
endmodule
