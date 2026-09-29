module forwarding_unit
(
    input  logic [4:0] id_ex_rs1,
    input  logic [4:0] id_ex_rs2,

    input  logic [4:0] ex_mem_rd,
    input  logic       ex_mem_reg_write,

    input  logic [4:0] mem_wb_rd,
    input  logic       mem_wb_reg_write,

    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);

    // the newest matching write wins: EX/MEM before MEM/WB
    always_comb begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        // rs1 forwarding
        if (ex_mem_reg_write &&
            (ex_mem_rd != 5'b0) &&
            (ex_mem_rd == id_ex_rs1))

            forward_a = 2'b10;

        else if (mem_wb_reg_write &&
                 (mem_wb_rd != 5'b0) &&
                 (mem_wb_rd == id_ex_rs1))

            forward_a = 2'b01;

        // rs2 forwarding
        if (ex_mem_reg_write &&
            (ex_mem_rd != 5'b0) &&
            (ex_mem_rd == id_ex_rs2))

            forward_b = 2'b10;

        else if (mem_wb_reg_write &&
                 (mem_wb_rd != 5'b0) &&
                 (mem_wb_rd == id_ex_rs2))

            forward_b = 2'b01;
    end

endmodule
