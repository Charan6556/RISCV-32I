class riscv_driver extends uvm_driver #(riscv_transaction);
    `uvm_component_utils(riscv_driver)

    virtual riscv_if vif;

    logic [31:0] imem [0:1023];
    logic [31:0] dmem [0:1023];

    function new(string name = "riscv_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        init_memory();

        fork
            load_program();
            drive_imem();
            drive_dmem();
            write_dmem();
        join
    endtask

    // initialize memory
    task init_memory();
        for (int i = 0; i < 1024; i++) begin
            imem[i] = 32'h00000013;
            dmem[i] = 32'h00000000;
        end
        vif.imem_rdata = 32'h00000013;
        vif.dmem_rdata = 32'h00000000;
    endtask

    // load instructions
    task load_program();
        riscv_transaction trans;
        forever begin
            seq_item_port.get_next_item(trans);
            imem[trans.pc[11:2]] = trans.instr;
            `uvm_info("DRV",
                $sformatf("PC = %08h  INSTR = %08h",trans.pc, trans.instr),
                UVM_LOW)
            seq_item_port.item_done();
        end
    endtask

    // instruction memory
    task drive_imem();
        forever begin
            @(negedge vif.clk);
            if (!vif.rst_n)
                vif.imem_rdata <= 32'h00000013;
            else
                vif.imem_rdata <= imem[vif.imem_addr[11:2]];
        end
    endtask

    // data memory read
    task drive_dmem();
        forever begin
            @(negedge vif.clk);
            if (!vif.rst_n)
                vif.dmem_rdata <= 32'h00000000;
            else
                vif.dmem_rdata <= dmem[vif.dmem_addr[11:2]];
        end
    endtask
    // data memory write
    task write_dmem();
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n && vif.dmem_req) begin
                if (vif.dmem_wstrb[0])
                    dmem[vif.dmem_addr[11:2]][7:0] <=
                    vif.dmem_wdata[7:0];

                if (vif.dmem_wstrb[1])
                    dmem[vif.dmem_addr[11:2]][15:8] <=
                    vif.dmem_wdata[15:8];

                if (vif.dmem_wstrb[2])
                    dmem[vif.dmem_addr[11:2]][23:16] <=
                    vif.dmem_wdata[23:16];

                if (vif.dmem_wstrb[3])
                    dmem[vif.dmem_addr[11:2]][31:24] <=
                    vif.dmem_wdata[31:24];
            end
        end
    endtask
endclass
