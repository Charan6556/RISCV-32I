class riscv_sequencer extends uvm_sequencer #(riscv_transaction);
    `uvm_component_utils(riscv_sequencer)

    function new(string name = "riscv_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass
