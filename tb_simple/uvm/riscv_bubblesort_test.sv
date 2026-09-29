class riscv_bubblesort_test extends uvm_test;

    `uvm_component_utils(riscv_bubblesort_test)

    riscv_env env;
    virtual riscv_if vif;

    function new(string name = "riscv_bubblesort_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = riscv_env::type_id::create("env", this);

        if (!uvm_config_db #(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal("TEST", "interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        riscv_bubblesort_sequence seq;

        int cycle_count;
        int commit_count;

        real cpi;

        phase.raise_objection(this);

        vif.rst_n = 0;

        seq = riscv_bubblesort_sequence::type_id::create("seq");

        seq.start(env.agent.sequencer);

        repeat(2)
            @(posedge vif.clk);

        vif.rst_n = 1;

        cycle_count  = 0;
        commit_count = 0;

        // count cycles and retired instructions
        forever begin
            @(negedge vif.clk);

            cycle_count++;

            if (vif.commit_valid)
                commit_count++;

            // completion instruction committed
            if (vif.commit_valid &&
                vif.commit_pc == 32'h0000006c)
                break;
        end

        cpi = $itor(cycle_count) / $itor(commit_count);

        `uvm_info("BUBBLE",
            $sformatf("Cycles = %0d", cycle_count),
            UVM_NONE)

        `uvm_info("BUBBLE",
            $sformatf("Retired Instructions = %0d", commit_count),
            UVM_NONE)

        `uvm_info("BUBBLE",
            $sformatf("CPI = %.3f", cpi),
            UVM_NONE)

        // check result
        if ((env.agent.driver.dmem[0] == 32'd1) &&
            (env.agent.driver.dmem[1] == 32'd2) &&
            (env.agent.driver.dmem[2] == 32'd4) &&
            (env.agent.driver.dmem[3] == 32'd5) &&
            (env.agent.driver.dmem[4] == 32'd8))

            `uvm_info("BUBBLE",
                "BUBBLE SORT PASS : 1 2 4 5 8",
                UVM_NONE)

        else
            `uvm_error("BUBBLE", "BUBBLE SORT FAIL")

        `uvm_info("BUBBLE",
            $sformatf("MEM = %0d %0d %0d %0d %0d",
                env.agent.driver.dmem[0],
                env.agent.driver.dmem[1],
                env.agent.driver.dmem[2],
                env.agent.driver.dmem[3],
                env.agent.driver.dmem[4]),
            UVM_NONE)

        phase.drop_objection(this);
    endtask
endclass
