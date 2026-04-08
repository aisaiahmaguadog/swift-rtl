import numpy as np

# SWIFT filter parameters
N = 64    # number of frequency bins
TAU = 32  # exponential decay time constant (samples)

# per-bin decay factor: alpha * e^(j*omega_k)
ALPHA = np.exp(-1 / TAU)  # decay magnitude per sample
k = np.arange(N)  # bin indices 0 to N-1
OMEGA = 2 * np.pi * k / N  # center frequency of each bin (rad/sample)
DECAY_FACTOR = ALPHA * np.exp(1j * OMEGA)  # complex decay factor per bin

# quantize to Q1.15: 1 sign bit + 15 fractional bits, stored as int16
DECAY_REAL_Q115 = np.round(DECAY_FACTOR.real * 2**15).astype(np.int16)
DECAY_IMAG_Q115 = np.round(DECAY_FACTOR.imag * 2**15).astype(np.int16)

# write to hex file: one bin per line, packed RE||IM (4 hex digits each)
with open("DECAY_FACTORS.hex", "w") as f:
    for i in range(N):
        re = int(DECAY_REAL_Q115[i]) & 0xFFFF  # reinterpret as unsigned 16-bit
        im = int(DECAY_IMAG_Q115[i]) & 0xFFFF
        f.write(f"{re:04X}{im:04X}\n")


def complex_mult_q(a, b, c, d):  # (a+jb)*(c+jd), Q1.15 x Q9.14 -> Q11.14
    ac = a * c
    bd = b * d
    ad = a * d
    bc = b * c
    re = (ac - bd) >> 15
    im = (ad + bc) >> 15
    return re, im

# verify all testbench test vectors
tests = [
    (31607, 3113, 16384, 0, "Test 1"),
    (31760, 0, 16384, 0, "Test 2"),
    (22458, 22458, 8192, 4096, "Test 3"),
    (31607, 3113, -16384, 0, "Test 4"),
    (29342, 12154, 8192, 8192, "Test 5"),
]

for a, b, c, d, label in tests:  # run each vector and print expected output
    re, im = complex_mult_q(a, b, c, d)
    print(f"{label}: re={re}, im={im}")

# sine response test: feed a sine at bin 8's frequency, expect bin 8 to peak
t = np.arange(100)
samples = np.sin(2 * np.pi * 8 * t / N)  # sine at bin 8's center frequency

bins = np.zeros(N, dtype=complex)  # filter state, one complex value per bin
for sample in samples:
    bins = sample + DECAY_FACTOR * bins  # SWIFT recurrence: update all bins each sample

magnitude = np.abs(bins)  # magnitude of each bin after all samples

# export expected magnitudes for testbench verification
with open("expected_magnitudes.txt", "w") as f:
    for i in range(N):
        f.write(f"{magnitude[i]:.6f}\n")
