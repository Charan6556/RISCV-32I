module wb_mux (
  input  logic [31:0]        alu_result,
  input  logic [31:0]        load_data,
  input  logic [31:0]        pc4,
  input  riscv_pkg::wb_sel_e wb_sel,

  output logic [31:0]        wb_data
);

  import riscv_pkg::*;

  // Writeback select mux
  always_comb begin
    unique case (wb_sel)

      WB_ALU: begin
        wb_data = alu_result;     // ALU ops, LUI, AUIPC
      end

      WB_LOAD: begin
        wb_data = load_data;      // LB, LH, LW, LBU, LHU
      end

      WB_PC4: begin
        wb_data = pc4;            // JAL, JALR link value
      end

      default: begin
        wb_data = 32'h0000_0000;  // reserved/no latch
      end

    endcase
  end

endmodule