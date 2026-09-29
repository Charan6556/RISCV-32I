module imem_model (
    input  logic [31:0] imem_addr,
    output logic [31:0] imem_rdata
);
    logic [31:0] mem [0:1023];

    assign imem_rdata = mem[imem_addr[11:2]];

    initial begin
        for (int i = 0; i < 1024; i++) mem[i] = 32'h0;
        $readmemh("program.hex", mem);
    end
endmodule
