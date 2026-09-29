module riscv_assertions
(
    input logic        clk,
    input logic        rst_n,

    input logic [31:0] pc,

    input logic        hazard_stall,
    input logic        ex_redirect,

    input logic [1:0]  forward_a,
    input logic [1:0]  forward_b,

    input logic        if_id_valid,
    input logic [31:0] if_id_pc,
    input logic [31:0] if_id_instr,

    input logic        id_ex_valid,
    input logic        id_ex_mem_read,
    input logic [4:0]  id_ex_rd,
    input logic [4:0]  id_rs1,
    input logic [4:0]  id_rs2,

    input logic        ex_mem_valid,
    input logic        ex_mem_mem_read,
    input logic        ex_mem_mem_write,

    input logic        mem_wb_valid,
    input logic        mem_wb_reg_write,
    input logic [4:0]  mem_wb_rd,
    input logic [31:0] wb_data,

    input logic        dmem_req,
    input logic [3:0]  dmem_wstrb
);

    // forward a should be valid
    property p_forward_a;
        @(posedge clk)
        disable iff (!rst_n)
        forward_a != 2'b11;
    endproperty

    a_forward_a:
    assert property(p_forward_a)
    else $error("Invalid forward_a");

    // forward b should be valid
    property p_forward_b;
        @(posedge clk)
        disable iff (!rst_n)
        forward_b != 2'b11;
    endproperty

    a_forward_b:
    assert property(p_forward_b)
    else $error("Invalid forward_b");

    // load use should stall
    property p_load_use_stall;
        @(posedge clk)
        disable iff (!rst_n)

        id_ex_valid &&
        id_ex_mem_read &&
        (id_ex_rd != 0) &&
        ((id_ex_rd == id_rs1) ||
         (id_ex_rd == id_rs2))

        |-> hazard_stall;
    endproperty

    a_load_use_stall:
    assert property(p_load_use_stall)
    else $error("Load use stall missing");

    // pc should hold during stall
    property p_pc_hold;
        @(posedge clk)
        disable iff (!rst_n)

        hazard_stall |=> $stable(pc);
    endproperty

    a_pc_hold:
    assert property(p_pc_hold)
    else $error("PC changed during stall");

    // if id should hold during stall
    property p_if_id_hold;
        @(posedge clk)
        disable iff (!rst_n)

        hazard_stall
        |=> $stable(if_id_pc) &&
            $stable(if_id_instr);
    endproperty

    a_if_id_hold:
    assert property(p_if_id_hold)
    else $error("IF ID changed during stall");

    // redirect should flush younger instructions
    property p_redirect_flush;
        @(posedge clk)
        disable iff (!rst_n)

        ex_redirect
        |=> (!if_id_valid && !id_ex_valid);
    endproperty

    a_redirect_flush:
    assert property(p_redirect_flush)
    else $error("Pipeline flush failed");

    // control signals should not be unknown
    property p_control_known;
        @(posedge clk)
        disable iff (!rst_n)

        !$isunknown({
            hazard_stall,
            ex_redirect,
            forward_a,
            forward_b
        });
    endproperty

    a_control_known:
    assert property(p_control_known)
    else $error("Unknown pipeline control");

    // writeback should be valid
    property p_writeback_known;
        @(posedge clk)
        disable iff (!rst_n)

        mem_wb_valid &&
        mem_wb_reg_write

        |-> !$isunknown({
            mem_wb_rd,
            wb_data
        });
    endproperty

    a_writeback_known:
    assert property(p_writeback_known)
    else $error("Unknown writeback value");

    // memory strobe should be valid
    property p_memory_strobe;
        @(posedge clk)
        disable iff (!rst_n)

        dmem_req
        |-> dmem_wstrb inside {
            4'b0000,
            4'b0001,
            4'b0010,
            4'b0100,
            4'b1000,
            4'b0011,
            4'b0110,
            4'b1100,
            4'b1111
        };
    endproperty

    a_memory_strobe:
    assert property(p_memory_strobe)
    else $error("Invalid memory strobe");

    // read and write should not happen together
    property p_mem_read_write;
        @(posedge clk)
        disable iff (!rst_n)

        ex_mem_valid
        |-> !(ex_mem_mem_read &&
              ex_mem_mem_write);
    endproperty

    a_mem_read_write:
    assert property(p_mem_read_write)
    else $error("Memory read and write together");
endmodule
