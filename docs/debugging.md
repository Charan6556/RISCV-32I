# Regression debugging record

## Initial failure

My first 100-seed regression reported **88 passes and 12 failures**:

```text
9 14 31 39 40 42 46 49 67 91 94 98
```

![Earlier failing regression](images/regression-before-fix.png)

Seed 9 failed with this scoreboard message:

```text
PC = 0000017c  INSTR = 41845793
REG FAIL PC=0000017c expected x15=000000ff got x15=ffffffff
```

`0x41845793` encodes `SRAI x15, x8, 24`. The DUT's `ffffffff` was correct (arithmetic shift of a negative value); the scoreboard's expected value was wrong. My reference model used one conditional expression that mixed a signed arithmetic shift with an unsigned logical shift. In SystemVerilog, mixing signed and unsigned operands makes the whole expression unsigned, so the sign extension was lost.

## Fix

I split SRA and SRAI into explicit branches so the signed shift is evaluated on its own. For SRAI:

```systemverilog
if (instr[30])
    result = $signed(a) >>> instr[24:20];
else
    result = a >> instr[24:20];
```

The processor RTL did not change; the bug was in the checker. I traced seed 9 in detail; I did not keep a separate trace for each of the other eleven failing seeds.

## Regression after the fix

The next run reached seed 1000 and reported:

```text
PASS = 1000
FAIL = 0
FAILED SEEDS
NONE
```

![Regression summary after the fix](images/regression-1000-pass.png)

That run used the first version of my regression script. It covered seeds 1–1000; the screenshot heading still says “100 SEED” only because I forgot to update the label when I raised the seed count. The screenshot also shows `//: Is a directory` messages from two comment lines written with `//` instead of Bash's `#`. Those messages were harmless and unrelated to the scoreboard bug.

I have since improved the script: it uses valid comments, derives its heading from the seed count, removes stale logs before each run, checks Xcelium's exit status, requires complete UVM and scoreboard summaries, and checks for assertion failures and simulator errors. I have not yet rerun all 1,000 seeds with this stricter version.
