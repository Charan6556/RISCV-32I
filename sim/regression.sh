#!/bin/bash
set -eu

cd "$(dirname "$0")"

SEEDS=${1:-1000}
case "$SEEDS" in
    ''|*[!0-9]*|0*)
        echo "Usage: $0 [positive seed count]" >&2
        exit 2
        ;;
esac

if ! command -v xrun > /dev/null 2>&1; then
    echo "xrun not found. Load the Cadence Xcelium environment first." >&2
    exit 127
fi

PASS=0
FAIL=0
mkdir -p regression_logs
rm -f failed_seeds.txt

# These messages cover all ten assertions in riscv_assertions.sv.
ASSERT_ERRORS='Invalid forward|Load use stall missing|PC changed during stall|IF ID changed during stall|Pipeline flush failed|Unknown pipeline control|Unknown writeback value|Invalid memory strobe|Memory read and write together'

for ((SEED = 1; SEED <= SEEDS; SEED++)); do
    echo "Running seed $SEED"
    LOG="regression_logs/seed_${SEED}.log"
    CONSOLE="regression_logs/seed_${SEED}_console.log"
    rm -f "$LOG"
    XRUN_STATUS=0

    # Coverage is disabled here; use run.sh for a coverage run.
    xrun -64bit \
        -sv \
        -uvm \
        -timescale 1ns/1ps \
        -f filelist.f \
        -top tb_uvm_top \
        +UVM_TESTNAME=riscv_full_test \
        +UVM_VERBOSITY=UVM_NONE \
        +UVM_NO_RELNOTES \
        -svseed "$SEED" \
        -access +rwc \
        -l "$LOG" > "$CONSOLE" 2>&1 || XRUN_STATUS=$?

    UVM_FAIL=0
    ASSERT_FAIL=0

    # Require complete zero-error summaries, independent of spacing.
    if [ ! -s "$LOG" ] ||
       ! grep -Eq '^[[:space:]]*UVM_ERROR[[:space:]]*:[[:space:]]*0[[:space:]]*$' "$LOG" ||
       ! grep -Eq '^[[:space:]]*UVM_FATAL[[:space:]]*:[[:space:]]*0[[:space:]]*$' "$LOG" ||
       ! grep -Eq '\[SCB\].*COMMITS=[1-9][0-9]*[[:space:]]+ERRORS=0[[:space:]]*$' "$LOG"; then
        UVM_FAIL=1
    fi

    # Check assertion messages and simulator errors even after a UVM summary.
    if [ -s "$LOG" ] && grep -Eq "$ASSERT_ERRORS|\*[EF],|^[[:space:]]*UVM_(ERROR|FATAL)[[:space:]]+[^:[:space:]]" "$LOG"; then
        ASSERT_FAIL=1
    fi

    if [ "$XRUN_STATUS" -eq 0 ] && [ "$UVM_FAIL" -eq 0 ] && [ "$ASSERT_FAIL" -eq 0 ]; then
        echo "SEED $SEED : PASS"
        PASS=$((PASS + 1))
    else
        echo "SEED $SEED : FAIL (see $LOG and $CONSOLE)"
        echo "$SEED" >> failed_seeds.txt
        FAIL=$((FAIL + 1))
    fi
done

echo
echo "================================="
echo "RISC-V $SEEDS SEED REGRESSION"
echo "PASS = $PASS"
echo "FAIL = $FAIL"
echo "================================="
echo
echo "FAILED SEEDS"

if [ -s failed_seeds.txt ]; then
    cat failed_seeds.txt
else
    echo "NONE"
fi

[ "$FAIL" -eq 0 ]
