module alu (
  input  logic [31:0]        op_a,
  input  logic [31:0]        op_b,
  input  riscv_pkg::alu_op_e alu_op,
  output logic [31:0]        alu_result
);

  import riscv_pkg::*;

  // RV32I combinational ALU
  always_comb begin
    unique case (alu_op)

      ALU_ADD:    alu_result = op_a + op_b;                         // ADD, ADDI, LW/SW address, AUIPC

      ALU_SUB:    alu_result = op_a - op_b;                         // SUB

      ALU_SLL:    alu_result = op_a << op_b[4:0];                   // SLL, SLLI

      ALU_SLT:    alu_result = ($signed(op_a) < $signed(op_b)) 
                               ? 32'h0000_0001 
                               : 32'h0000_0000;                     // signed compare

      ALU_SLTU:   alu_result = (op_a < op_b) 
                               ? 32'h0000_0001 
                               : 32'h0000_0000;                     // unsigned compare

      ALU_XOR:    alu_result = op_a ^ op_b;                         // XOR, XORI

      ALU_SRL:    alu_result = op_a >> op_b[4:0];                   // logical right shift, zero-fill

      ALU_SRA:    alu_result = $signed(op_a) >>> op_b[4:0];         // arithmetic right shift, sign-fill

      ALU_OR:     alu_result = op_a | op_b;                         // OR, ORI

      ALU_AND:    alu_result = op_a & op_b;                         // AND, ANDI

      ALU_PASS_B: alu_result = op_b;                                // LUI, pass imm_U

      default:    alu_result = 32'h0000_0000;                       // no latch

    endcase
  end

endmodule

