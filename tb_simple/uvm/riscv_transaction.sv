class riscv_transaction extends uvm_sequence_item;

    rand bit [31:0] instr;

    bit [31:0] pc;

    // data memory
    bit [31:0] dmem_addr;
    bit [31:0] dmem_wdata;
    bit [31:0] dmem_rdata;
    bit [3:0]  dmem_wstrb;
    bit        dmem_req;

    // commit signals
    bit        commit_valid;
    bit        commit_reg_write;
    bit [4:0]  commit_rd;
    bit [31:0] commit_data;
    bit [31:0] commit_pc;

    // pipeline signals
    bit        stall;
    bit        redirect;
    bit [1:0]  forward_a;
    bit [1:0]  forward_b;

    `uvm_object_utils_begin(riscv_transaction)

        `uvm_field_int(instr,            UVM_ALL_ON)
        `uvm_field_int(pc,               UVM_ALL_ON)

        `uvm_field_int(dmem_addr,        UVM_ALL_ON)
        `uvm_field_int(dmem_wdata,       UVM_ALL_ON)
        `uvm_field_int(dmem_rdata,       UVM_ALL_ON)
        `uvm_field_int(dmem_wstrb,       UVM_ALL_ON)
        `uvm_field_int(dmem_req,         UVM_ALL_ON)

        `uvm_field_int(commit_valid,     UVM_ALL_ON)
        `uvm_field_int(commit_reg_write, UVM_ALL_ON)
        `uvm_field_int(commit_rd,        UVM_ALL_ON)
        `uvm_field_int(commit_data,      UVM_ALL_ON)
        `uvm_field_int(commit_pc,        UVM_ALL_ON)

        `uvm_field_int(stall,            UVM_ALL_ON)
        `uvm_field_int(redirect,         UVM_ALL_ON)
        `uvm_field_int(forward_a,        UVM_ALL_ON)
        `uvm_field_int(forward_b,        UVM_ALL_ON)

    `uvm_object_utils_end

    function new(string name = "riscv_transaction");
        super.new(name);
    endfunction
endclass
