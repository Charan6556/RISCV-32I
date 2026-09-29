#!/bin/bash
set -eu

cd "$(dirname "$0")"

TEST=${1:-riscv_smoke_test}
SEED=${2:-1}
COV_NAME=${TEST}_seed${SEED}

case "$TEST" in
    riscv_smoke_test|riscv_directed_test|riscv_hazard_test|riscv_random_test|riscv_full_test|riscv_bubblesort_test) ;;
    *) echo "Unknown test: $TEST" >&2; exit 2 ;;
esac
case "$SEED" in
    ''|*[!0-9]*) echo "Seed must be a nonnegative integer." >&2; exit 2 ;;
esac

if ! command -v xrun > /dev/null 2>&1; then
    echo "xrun not found. Load the Cadence Xcelium environment first." >&2
    exit 127
fi

mkdir -p logs cov_work

echo "TEST : $TEST"
echo "SEED : $SEED"
echo "COV  : $COV_NAME"

exec xrun -64bit \
    -sv \
    -uvm \
    -timescale 1ns/1ps \
    -f filelist.f \
    -top tb_uvm_top \
    +UVM_TESTNAME="$TEST" \
    +UVM_VERBOSITY=UVM_NONE \
    +UVM_NO_RELNOTES \
    -svseed "$SEED" \
    -access +rwc \
    -coverage all \
    -covworkdir cov_work \
    -covtest "$COV_NAME" \
    -covoverwrite \
    -l "logs/${COV_NAME}.log"
