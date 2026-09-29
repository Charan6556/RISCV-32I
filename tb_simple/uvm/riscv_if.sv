interface riscv_if(input logic clk);

    logic rst_n;

    // instruction memory
    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;

    // data memory
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_rdata;
    logic [3:0]  dmem_wstrb;
    logic        dmem_req;

    // commit signals
    logic        commit_valid;
    logic        commit_reg_write;
    logic [4:0]  commit_rd;
    logic [31:0] commit_data;
    logic [31:0] commit_pc;

    // pipeline signals
    logic        stall;
    logic        redirect;
    logic [1:0]  forward_a;
    logic [1:0]  forward_b;

    // driver clocking block
    clocking drv_cb @(posedge clk);
        input  rst_n;
        input  imem_addr;
        output imem_rdata;
        input  dmem_addr;
        input  dmem_wdata;
        input  dmem_wstrb;
        input  dmem_req;
        output dmem_rdata;
    endclocking

    // monitor clocking block
    clocking mon_cb @(posedge clk);
        input rst_n;
        input imem_addr;
        input imem_rdata;
        input dmem_addr;
        input dmem_wdata;
        input dmem_rdata;
        input dmem_wstrb;
        input dmem_req;
        input commit_valid;
        input commit_reg_write;
        input commit_rd;
        input commit_data;
        input commit_pc;

        input stall;
        input redirect;
        input forward_a;
        input forward_b;

    endclocking

    // DUT
    modport DUT (
        input  clk,
        input  rst_n,
        output imem_addr,
        input  imem_rdata,
        output dmem_addr,
        output dmem_wdata,
        output dmem_wstrb,
        output dmem_req,
        input  dmem_rdata
    );

    // driver
    modport DRIVER (clocking drv_cb);

    // monitor
    modport MONITOR (clocking mon_cb );
endinterface
