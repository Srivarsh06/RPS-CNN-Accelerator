"""Generate test vectors + golden answers for the on-board MAC self-test (rtl/selftest_top.sv).
Run:  python gen_selftest.py      -> ../mem/selftest_vec.mem, ../mem/selftest_exp.mem

50 trials of one 3x3 window (9 taps) on 4 lanes, signed INT8.
  selftest_vec.mem: one line per tap,   {a, w0, w1, w2, w3}       (40 bits, 10 hex digits)
  selftest_exp.mem: one line per trial, {acc0, acc1, acc2, acc3}   (128 bits, 32 hex digits, two's complement)
Trials 0-1 are corner cases (-128 * -128 and -128 * 127 on every tap); the rest are random.
"""
import os
import numpy as np

TRIALS, TAPS, LANES = 50, 9, 4
rng = np.random.default_rng(385)

a = rng.integers(-128, 128, (TRIALS, TAPS))
w = rng.integers(-128, 128, (TRIALS, TAPS, LANES))
a[0], w[0] = -128, -128          # largest positive sum:  9 * 16384
a[1], w[1] = -128, 127           # largest negative sum: -9 * 16256
acc = np.einsum("tk,tkl->tl", a, w)

out = os.path.join(os.path.dirname(__file__), "..", "mem")
os.makedirs(out, exist_ok=True)
with open(os.path.join(out, "selftest_vec.mem"), "w") as f:
    for t in range(TRIALS):
        for k in range(TAPS):
            f.write("".join(f"{v & 0xFF:02x}" for v in [a[t, k], *w[t, k]]) + "\n")
with open(os.path.join(out, "selftest_exp.mem"), "w") as f:
    for t in range(TRIALS):
        f.write("".join(f"{int(v) & 0xFFFFFFFF:08x}" for v in acc[t]) + "\n")
print(f"wrote {TRIALS * TAPS} taps, {TRIALS} expected results; acc range {acc.min()} .. {acc.max()}")
