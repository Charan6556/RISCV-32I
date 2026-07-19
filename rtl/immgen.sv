module immgen
  import riscv_pkg::*;
(
    input  logic [31:0]  instr,
    input  imm_sel_e     imm_sel,
    output logic [31:0]  imm
);
always_comb begin
    case (imm_sel)
        IMM_I:   imm = {{20{instr[31]}}, instr[31:20]};
        IMM_B:   imm = {{19{instr[31]}}, instr[31], instr[7],instr[30:25], instr[11:8], 1'b0};
        IMM_S :  imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        IMM_U:   imm = {instr[31:12], 12'b0};
        IMM_J:   imm = {{11{instr[31]}}, instr[31], instr[19:12],instr[20], instr[30:21], 1'b0};
         default: 
                imm = 32'h0000_0000;
    endcase
end
endmodule