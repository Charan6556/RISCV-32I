// simple test system around riscv_core_top to run C programs
//   0x0000_0000 - 0x0000_3FFF : 16 KB RAM (instructions + data)
//   0x1000_0000               : console, sb writes one character
//   0x1000_0004               : exit, sw prints the counters and ends the sim
module tb_soc;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    always #5 clk = ~clk;

    logic [31:0] imem_addr, imem_rdata;
    logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    logic [3:0]  dmem_wstrb;
    logic        dmem_req;

    riscv_core_top dut (.*);

    localparam int WORDS = 4096;
    logic [31:0] mem [0:WORDS-1];

    wire is_io = (dmem_addr[31:28] == 4'h1);

    assign imem_rdata = mem[imem_addr[13:2]];
    assign dmem_rdata = is_io ? 32'h0 : mem[dmem_addr[13:2]];

    longint cycles = 0, retired = 0, stalls = 0, redirects = 0;
    longint max_cycles = 200_000_000;

    always @(posedge clk) begin
        if (rst_n) begin
            cycles <= cycles + 1;
            if (dut.mem_wb_valid) retired   <= retired + 1;
            if (dut.hazard_stall) stalls    <= stalls + 1;
            if (dut.ex_redirect)  redirects <= redirects + 1;

            if (dmem_req && dmem_wstrb != 4'b0) begin
                if (!is_io) begin
                    if (dmem_wstrb[0]) mem[dmem_addr[13:2]][7:0]   <= dmem_wdata[7:0];
                    if (dmem_wstrb[1]) mem[dmem_addr[13:2]][15:8]  <= dmem_wdata[15:8];
                    if (dmem_wstrb[2]) mem[dmem_addr[13:2]][23:16] <= dmem_wdata[23:16];
                    if (dmem_wstrb[3]) mem[dmem_addr[13:2]][31:24] <= dmem_wdata[31:24];
                end else if (dmem_addr == 32'h1000_0000) begin
                    $write("%c", dmem_wdata[7:0]);
                end else if (dmem_addr == 32'h1000_0004) begin
                    $display("");
                    $display("[tb] exit code    : %0d", dmem_wdata);
                    $display("[tb] cycles       : %0d", cycles);
                    $display("[tb] retired      : %0d", retired);
                    $display("[tb] CPI          : %0.3f", real'(cycles) / real'(retired));
                    $display("[tb] load-use stalls : %0d", stalls);
                    $display("[tb] taken redirects : %0d", redirects);
                    $fflush();
                    $finish;
                end
            end

            if (cycles > max_cycles) begin
                $display("\n[tb] TIMEOUT after %0d cycles, pc=%h", cycles, imem_addr);
                $finish;
            end
        end
    end

    initial begin
        string hexfile;
        for (int i = 0; i < WORDS; i++) mem[i] = 32'h0;
        if (!$value$plusargs("HEX=%s", hexfile)) hexfile = "prog.hex";
        $readmemh(hexfile, mem);
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
    end
endmodule
