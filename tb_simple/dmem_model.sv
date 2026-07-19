module dmem_model(input logic clk, 
	input logic [31:0] dmem_addr,
	input logic [31:0] dmem_wdata,
	input logic [3:0]  dmem_wstrb,
	input logic        dmem_req,
	output logic [31:0] dmem_rdata);

	logic [31:0] mem [0:1023];
        
        initial begin
        for (int i = 0; i < 1024; i++) mem[i] = 32'h0;
        end
	always @(posedge clk) 
            if (dmem_req) begin
		if (dmem_wstrb[0]) mem[dmem_addr[11:2]][7:0]   <= dmem_wdata[7:0];
                if (dmem_wstrb[1]) mem[dmem_addr[11:2]][15:8]  <= dmem_wdata[15:8];
                if (dmem_wstrb[2]) mem[dmem_addr[11:2]][23:16] <= dmem_wdata[23:16];
                if (dmem_wstrb[3]) mem[dmem_addr[11:2]][31:24] <= dmem_wdata[31:24];
	 end
        assign dmem_rdata = mem[dmem_addr[11:2]];
	 task backdoor_read(input [31:0] addr, output [31:0] data);
            data = mem[addr[11:2]];
         endtask
endmodule
