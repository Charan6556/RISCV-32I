class riscv_smoke_test extends uvm_test;

    `uvm_component_utils(riscv_smoke_test)

    riscv_env env;
    riscv_smoke_sequence seq;

    virtual riscv_if vif;

    function new(string name = "riscv_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        uvm_config_db #(uvm_active_passive_enum)::set(
            this,
            "env.agent",
            "is_active",
            UVM_ACTIVE
        );

        if (!uvm_config_db #(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal("TEST", "interface not found")

        env = riscv_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        // reset
        vif.rst_n = 0;

        seq = riscv_smoke_sequence::type_id::create("seq");

        // load program
        seq.start(env.agent.sequencer);

        repeat(2)
            @(posedge vif.clk);

        // start processor
        vif.rst_n = 1;

        // run program
        repeat(30)
            @(posedge vif.clk);

        phase.drop_objection(this);
    endtask
endclass
