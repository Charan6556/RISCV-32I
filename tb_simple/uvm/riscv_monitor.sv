class riscv_monitor extends uvm_monitor;
    `uvm_component_utils(riscv_monitor)

    virtual riscv_if vif;
    uvm_analysis_port #(riscv_transaction) mon_port;

    function new(string name = "riscv_monitor", uvm_component parent = null);
        super.new(name, parent);
        mon_port = new("mon_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        riscv_transaction trans;
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n) begin
                trans = riscv_transaction::type_id::create("trans");

                // instruction
                trans.pc    = vif.imem_addr;
                trans.instr = vif.imem_rdata;

                // data memory
                trans.dmem_addr  = vif.dmem_addr;
                trans.dmem_wdata = vif.dmem_wdata;
                trans.dmem_rdata = vif.dmem_rdata;
                trans.dmem_wstrb = vif.dmem_wstrb;
                trans.dmem_req   = vif.dmem_req;

                // commit
                trans.commit_valid     = vif.commit_valid;
                trans.commit_reg_write = vif.commit_reg_write;
                trans.commit_rd        = vif.commit_rd;
                trans.commit_data      = vif.commit_data;
                trans.commit_pc        = vif.commit_pc;

                // pipeline
                trans.stall     = vif.stall;
                trans.redirect  = vif.redirect;
                trans.forward_a = vif.forward_a;
                trans.forward_b = vif.forward_b;

                mon_port.write(trans);

                `uvm_info("MON",
                    $sformatf("PC=%08h INSTR=%08h COMMIT=%0b RD=%0d DATA=%08h",
                    trans.pc,
                    trans.instr,
                    trans.commit_valid,
                    trans.commit_rd,
                    trans.commit_data),
                    UVM_HIGH)
            end
        end
    endtask
endclass
