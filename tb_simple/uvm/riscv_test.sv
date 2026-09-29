class riscv_test extends uvm_test;
    `uvm_component_utils(riscv_test)

    riscv_env env;
    riscv_sequence seq;

    function new(string name = "riscv_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_db #(uvm_active_passive_enum)::set(this, "env.agent", "is_active", UVM_ACTIVE);
        env = riscv_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq = riscv_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);

        #500;

        phase.drop_objection(this);
    endtask
endclass
