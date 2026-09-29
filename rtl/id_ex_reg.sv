module id_ex_reg
    import riscv_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        flush,

    input  logic [31:0] pc_in,
    input  logic [31:0] pc4_in,
    input  logic [31:0] rs1_data_in,
    input  logic [31:0] rs2_data_in,
    input  logic [31:0] imm_in,

    input  logic [4:0]  rs1_in,
    input  logic [4:0]  rs2_in,
    input  logic [4:0]  rd_in,

    input  ctrl_t       ctrl_in,
    input  logic        valid_in,

    output logic [31:0] pc_out,
    output logic [31:0] pc4_out,
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] imm_out,

    output logic [4:0]  rs1_out,
    output logic [4:0]  rs2_out,
    output logic [4:0]  rd_out,

    output ctrl_t       ctrl_out,
    output logic        valid_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out       <= 32'b0;
            pc4_out      <= 32'b0;
            rs1_data_out <= 32'b0;
            rs2_data_out <= 32'b0;
            imm_out      <= 32'b0;

            rs1_out      <= 5'b0;
            rs2_out      <= 5'b0;
            rd_out       <= 5'b0;

            ctrl_out     <= CTRL_NOP;
            valid_out    <= 1'b0;
        end

        else if (flush) begin
            pc_out       <= 32'b0;
            pc4_out      <= 32'b0;
            rs1_data_out <= 32'b0;
            rs2_data_out <= 32'b0;
            imm_out      <= 32'b0;

            rs1_out      <= 5'b0;
            rs2_out      <= 5'b0;
            rd_out       <= 5'b0;

            ctrl_out     <= CTRL_NOP;
            valid_out    <= 1'b0;
        end

        else begin
            pc_out       <= pc_in;
            pc4_out      <= pc4_in;
            rs1_data_out <= rs1_data_in;
            rs2_data_out <= rs2_data_in;
            imm_out      <= imm_in;

            rs1_out      <= rs1_in;
            rs2_out      <= rs2_in;
            rd_out       <= rd_in;

            ctrl_out     <= ctrl_in;
            valid_out    <= valid_in;
        end
    end

endmodule
