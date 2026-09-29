class riscv_agent extends uvm_agent;
    `uvm_component_utils(riscv_agent)

    riscv_sequencer sequencer;
    riscv_driver    driver;
    riscv_monitor   monitor;

    function new(string name = "riscv_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = riscv_monitor::type_id::create("monitor", this);
        if (is_active == UVM_ACTIVE) begin
            sequencer = riscv_sequencer::type_id::create("sequencer", this);
            driver    = riscv_driver::type_id::create("driver", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (is_active == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
