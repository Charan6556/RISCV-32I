module mem_wb_reg
    import riscv_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    input  logic [31:0] alu_result_in,
    input  logic [31:0] load_data_in,
    input  logic [31:0] pc4_in,
    input  logic [4:0]  rd_in,

    input  ctrl_t       ctrl_in,
    input  logic        valid_in,

    output logic [31:0] alu_result_out,
    output logic [31:0] load_data_out,
    output logic [31:0] pc4_out,
    output logic [4:0]  rd_out,

    output ctrl_t       ctrl_out,
    output logic        valid_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_result_out <= 32'b0;
            load_data_out  <= 32'b0;
            pc4_out        <= 32'b0;
            rd_out         <= 5'b0;

            ctrl_out       <= CTRL_NOP;
            valid_out      <= 1'b0;
        end

        else begin
            alu_result_out <= alu_result_in;
            load_data_out  <= load_data_in;
            pc4_out        <= pc4_in;
            rd_out         <= rd_in;

            ctrl_out       <= ctrl_in;
            valid_out      <= valid_in;
        end
    end

endmodule
