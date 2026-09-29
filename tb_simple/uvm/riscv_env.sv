class riscv_env extends uvm_env;

    `uvm_component_utils(riscv_env)

    riscv_agent      agent;
    riscv_scoreboard scoreboard;
    riscv_coverage   coverage;

    function new(string name = "riscv_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent      = riscv_agent::type_id::create("agent", this);
        scoreboard = riscv_scoreboard::type_id::create("scoreboard", this);
        coverage   = riscv_coverage::type_id::create("coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        agent.monitor.mon_port.connect(scoreboard.sb_port);
        agent.monitor.mon_port.connect(coverage.analysis_export);
    endfunction
endclass
