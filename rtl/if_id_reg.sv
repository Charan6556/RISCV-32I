module if_id_reg
    import riscv_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        stall,
    input  logic        flush,

    input  logic [31:0] pc_in,
    input  logic [31:0] pc4_in,
    input  logic [31:0] instr_in,
    input  logic        valid_in,

    output logic [31:0] pc_out,
    output logic [31:0] pc4_out,
    output logic [31:0] instr_out,
    output logic        valid_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out    <= 32'b0;
            pc4_out   <= 32'b0;
            instr_out <= NOP_INSTR;
            valid_out <= 1'b0;
        end

        else if (flush) begin
            pc_out    <= 32'b0;
            pc4_out   <= 32'b0;
            instr_out <= NOP_INSTR;
            valid_out <= 1'b0;
        end

        else if (!stall) begin
            pc_out    <= pc_in;
            pc4_out   <= pc4_in;
            instr_out <= instr_in;
            valid_out <= valid_in;
        end
    end

endmodule
