
module lsu (
	    input  logic [31:0] addr,
	    input  logic [2:0]  funct3,
            input  logic        mem_read, mem_write,
            input  logic [31:0] store_data, dmem_rdata,
	    output logic [31:0] dmem_addr,
	    output logic [31:0] dmem_wdata,
	    output logic [3:0]  dmem_wstrb,
	    output logic        dmem_req,
	    output logic [31:0] load_data
					    );


	// funct3 values for RV32I load/store
  localparam logic [2:0] F3_BYTE  = 3'b000; // LB / SB
  localparam logic [2:0] F3_HALF  = 3'b001; // LH / SH
  localparam logic [2:0] F3_WORD  = 3'b010; // LW / SW
  localparam logic [2:0] F3_BYTEU = 3'b100; // LBU
  localparam logic [2:0] F3_HALFU = 3'b101; // LHU

  logic [7:0]  load_byte;
  logic [15:0] load_half;

  assign dmem_req = mem_read | mem_write;
  assign dmem_addr = addr;
    always_comb begin
    unique case (addr[1:0])
      2'b00:   load_byte = dmem_rdata[7:0];
      2'b01:   load_byte = dmem_rdata[15:8];
      2'b10:   load_byte = dmem_rdata[23:16];
      2'b11:   load_byte = dmem_rdata[31:24];
      default: load_byte = 8'h00;
    endcase
  end

   always_comb begin
    unique case (addr[1])
      1'b0:    load_half = dmem_rdata[15:0];
      1'b1:    load_half = dmem_rdata[31:16];
      default: load_half = 16'h0000;
    endcase
  end
  always_comb begin
    load_data = 32'h0000_0000;

    if (mem_read) begin
      unique case (funct3)

        F3_BYTE: begin
          load_data = {{24{load_byte[7]}}, load_byte};       // LB sign extend
        end

        F3_HALF: begin
          load_data = {{16{load_half[15]}}, load_half};      // LH sign extend
        end

        F3_WORD: begin
          load_data = dmem_rdata;                            // LW
        end

        F3_BYTEU: begin
          load_data = {24'h000000, load_byte};               // LBU zero extend
        end

        F3_HALFU: begin
          load_data = {16'h0000, load_half};                 // LHU zero extend
        end

        default: begin
          load_data = 32'h0000_0000;
        end

      endcase
    end
  end


  always_comb begin
    dmem_wdata = 32'h0000_0000;
    dmem_wstrb = 4'b0000;

    if (mem_write) begin
      unique case (funct3)

        F3_BYTE: begin // SB
          unique case (addr[1:0])
            2'b00: begin
              dmem_wstrb = 4'b0001;
              dmem_wdata = {24'h000000, store_data[7:0]};
            end

            2'b01: begin
              dmem_wstrb = 4'b0010;
              dmem_wdata = {16'h0000, store_data[7:0], 8'h00};
            end

            2'b10: begin
              dmem_wstrb = 4'b0100;
              dmem_wdata = {8'h00, store_data[7:0], 16'h0000};
            end

            2'b11: begin
              dmem_wstrb = 4'b1000;
              dmem_wdata = {store_data[7:0], 24'h000000};
            end

            default: begin
              dmem_wstrb = 4'b0000;
              dmem_wdata = 32'h0000_0000;
            end
          endcase
        end

        F3_HALF: begin // SH
          // Naturally aligned only: legal offsets are 0 and 2
          unique case (addr[1])
            1'b0: begin
              dmem_wstrb = 4'b0011;
              dmem_wdata = {16'h0000, store_data[15:0]};
            end

            1'b1: begin
              dmem_wstrb = 4'b1100;
              dmem_wdata = {store_data[15:0], 16'h0000};
            end

            default: begin
              dmem_wstrb = 4'b0000;
              dmem_wdata = 32'h0000_0000;
            end
          endcase
        end

        F3_WORD: begin // SW
          dmem_wstrb = 4'b1111;
          dmem_wdata = store_data;
        end

        default: begin
          dmem_wstrb = 4'b0000;
          dmem_wdata = 32'h0000_0000;
        end

      endcase
    end
  end

endmodule				    
