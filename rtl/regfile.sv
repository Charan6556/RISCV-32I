module regfile( input logic clk,
        input logic [4:0] rs1_addr, rs2_addr, rd_addr,
        input logic rst_n,
        input logic rd_we,
        input logic [31:0] rd_data,
        output logic [31:0] rs1_data, rs2_data);

    logic [31:0] regs [32];

always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
        for (int i = 0; i < 32; i++) regs[i] <= 32'h0;
    end else if (rd_we && rd_addr != 0) begin
        regs[rd_addr] <= rd_data;
    end
assign rs1_data = (rs1_addr == 5'd0) ? 32'h0 : regs[rs1_addr];
assign rs2_data = (rs2_addr == 5'd0) ? 32'h0 : regs[rs2_addr];

endmodule