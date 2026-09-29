bind riscv_core_top riscv_assertions riscv_assertions_i
(
    .clk              (clk),
    .rst_n            (rst_n),

    .pc               (pc),

    .hazard_stall     (hazard_stall),
    .ex_redirect      (ex_redirect),

    .forward_a        (forward_a),
    .forward_b        (forward_b),

    .if_id_valid      (if_id_valid),
    .if_id_pc         (if_id_pc),
    .if_id_instr      (if_id_instr),

    .id_ex_valid      (id_ex_valid),
    .id_ex_mem_read   (id_ex_ctrl.mem_read),
    .id_ex_rd         (id_ex_rd),
    .id_rs1           (id_rs1),
    .id_rs2           (id_rs2),

    .ex_mem_valid     (ex_mem_valid),
    .ex_mem_mem_read  (ex_mem_ctrl.mem_read),
    .ex_mem_mem_write (ex_mem_ctrl.mem_write),

    .mem_wb_valid     (mem_wb_valid),
    .mem_wb_reg_write (mem_wb_ctrl.reg_write),
    .mem_wb_rd        (mem_wb_rd),
    .wb_data          (wb_data),

    .dmem_req         (dmem_req),
    .dmem_wstrb       (dmem_wstrb)
);
