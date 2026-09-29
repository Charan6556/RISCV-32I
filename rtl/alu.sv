module alu (
    input  logic [31:0]        op_a,
    input  logic [31:0]        op_b,
    input  riscv_pkg::alu_op_e alu_op,
    output logic [31:0]        alu_result
);
    import riscv_pkg::*;

    always_comb begin
        unique case (alu_op)
            ALU_ADD:    alu_result = op_a + op_b;
            ALU_SUB:    alu_result = op_a - op_b;
            ALU_SLL:    alu_result = op_a << op_b[4:0];
            ALU_SLT:    alu_result = ($signed(op_a) < $signed(op_b))
                                    ? 32'h0000_0001 : 32'h0000_0000;
            ALU_SLTU:   alu_result = (op_a < op_b)
                                    ? 32'h0000_0001 : 32'h0000_0000;
            ALU_XOR:    alu_result = op_a ^ op_b;
            ALU_SRL:    alu_result = op_a >> op_b[4:0];          // zero fill
            ALU_SRA:    alu_result = $signed(op_a) >>> op_b[4:0]; // sign fill
            ALU_OR:     alu_result = op_a | op_b;
            ALU_AND:    alu_result = op_a & op_b;
            ALU_PASS_B: alu_result = op_b;                       // LUI
            default:    alu_result = 32'h0000_0000;
        endcase
    end
endmodule
