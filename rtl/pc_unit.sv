module pc_unit (
    input  logic        clk,
    input  logic        rst_n, pc_en,
    input  logic [1:0]  pc_sel,
    input  logic [31:0] br_jal_target, jalr_target,
    output logic [31:0] pc, pc4
);
    logic [31:0] pc_next;

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            pc <= 32'h0;
        else if (pc_en)
            pc <= pc_next;

    always_comb begin
        case (pc_sel)
            2'b00:   pc_next = pc4;
            2'b01:   pc_next = br_jal_target;
            2'b10:   pc_next = jalr_target;
            default: pc_next = pc4;
        endcase
    end

    assign pc4 = pc + 4;
endmodule
