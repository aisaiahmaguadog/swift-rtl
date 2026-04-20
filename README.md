# SWIFT Algorithm — RTL Implementation (ZedBoard PoC)

**Aisaiah Maguado · LMU Computer Engineering · Spring–Summer 2026**

---

## Overview

Hand-written SystemVerilog port of the SWIFT (Sliding Window Infinite Fourier Transform) algorithm targeting a ZedBoard (Zynq XC7Z020). Rather than using HLS, this implementation describes the hardware at the register-transfer level — explicitly defining every register, clock cycle, and data path by hand.

- **Target board:** ZedBoard (Zynq XC7Z020)
- **Target clock:** 100 MHz (PL MMCM)
- **Bins:** N = 64
- **Tau:** 32
- **Arithmetic:** Fixed-point (Q1.15 coefficients, Q9.14 bin state)
- **Verification:** Python golden reference model

---

## Status

> **Current focus:** Finishing `bin_ram_tb.sv` verification before starting `swift_core.sv`.

| File | Description | Status |
|---|---|---|
| `swift_reference.py` | Python golden reference model + decay factor hex export | ✅ Done |
| `DECAY_FACTORS.hex` | 64 precomputed Q1.15 complex decay factors | ✅ Done |
| `complex_mult.sv` | Combinational complex multiplier (Q1.15 × Q9.14 → Q11.14) | ✅ Done |
| `complex_mult_tb.sv` | Testbench — 5 verified test vectors | ✅ Done |
| `decay_rom.sv` | Synchronous BRAM ROM loaded via $readmemh | ✅ Done |
| `decay_rom_tb.sv` | Testbench — addr 0, 1, 2 verified against hex file | ✅ Done |
| `bin_ram.sv` | Synchronous read/write BRAM storing 64 complex bin states | ✅ Done |
| `bin_ram_tb.sv` | Testbench — write/read verification | ✅ Done |
| `swift_core.sv` | Main state machine — recurrence loop across all 64 bins | ⬜ Next |
| `magnitude_approx.sv` | Alpha-max beta-min sqrt approximation | ⬜ Post-break |
| `swift_top.sv` | Top-level ZedBoard pin mapping, clock, reset | ⬜ Post-break |
| `swift_tb.sv` | Full system testbench vs Python reference | ⬜ Post-break |

---

## Architecture

### Module Hierarchy

```
swift_top.sv
└── swift_core.sv
    ├── complex_mult.sv
    ├── decay_rom.sv
    └── bin_ram.sv
```

### Data Flow Per Sample

```
Input sample x[n]
      ↓
swift_core.sv  (state machine, loops over 64 bins)
      ↓                    ↑
  reads addr           writes updated bin
      ↓                    ↑
  bin_ram.sv  →  old bin state (c + jd)
                      ↓
              complex_mult.sv  ←  decay_rom.sv
                      ↓              (a + jb)
              multiply result
                      ↓
              add input sample x[n]
                      ↓
              new bin state → write back to bin_ram
```

### Arithmetic Pipeline

| Stage | Format | Width |
|---|---|---|
| Decay coefficients | Q1.15 | 16 bits |
| Bin state | Q9.14 | 23 bits |
| Multiply intermediate | Q10.29 | 39 bits |
| After right-shift 15 (intermediate inside complex_mult) | Q10.14 | 24 bits |
| complex_mult final output (ac−bd / ad+bc) | Q11.14 | 25 bits |
| After add (sample + product) | Q11.14 | 25 bits |
| Saturate and store | Q9.14 | 23 bits |

### Throughput

The state machine processes one bin per 3 clock cycles (read address → synchronous BRAM data valid → compute + write back). At 100 MHz:

```
f_clk / (N × cycles_per_bin) = 100 MHz / (64 × 3) ≈ 520 kS/s
```

This is a PoC estimate; actual throughput depends on pipeline depth finalized in `swift_core.sv`.

---

## Fixed-Point Design Decisions

**Why fixed-point instead of floating-point?**
The ZedBoard has no dedicated floating-point hardware. Fixed-point maps directly to the DSP48 hard blocks on the chip — much more resource efficient and faster.

**Why Q1.15 for coefficients?**
Decay factors always have magnitude less than 1.0, so Q1.15 (range ±1.0) fits perfectly with maximum fractional precision.

**Why Q9.14 for bin state?**
The SWIFT recurrence is an IIR filter. With τ = 32, the worst-case bin state gain is:
```
1 / (1 - e^(-1/32)) ≈ 32.5
```
Q9.14 has range ±256, giving 15× headroom. Q1.15 would overflow almost immediately.

**Why τ = 32 instead of Stephen's τ = 100?**
τ = 100 gives worst-case gain ≈ 100.5, pushing close to the limits of Q9.14. τ = 32 gives the same algorithmic behavior with comfortable headroom for a PoC. Changing it later is a one-line parameter change.

---

## Verification Strategy

Every HDL module is verified against `swift_reference.py` — a Python implementation of the same algorithm using the same fixed-point arithmetic. Expected values are generated in Python and compared against simulation output in Vivado.

```
swift_reference.py
      ↓ generates
DECAY_FACTORS.hex        → loaded into decay_rom.sv
expected_magnitudes.txt  → compared against swift_tb.sv output
complex_mult_q()         → generates test vectors for complex_mult_tb.sv
```

---

## Relationship to Stephen Ude's Implementation

Stephen Ude implemented SWIFT in C++ using Xilinx HLS targeting a ZCU102 with N = 200,000 bins and floating-point arithmetic (`swiftalgo.cpp`). This implementation takes the same algorithm and hand-crafts it in RTL — the approach a chip designer would take rather than relying on the HLS compiler.

The architecture is intentionally parameterized (`N`, `TAU`, `WIDTH`) so it could be retargeted to the ZCU102 and scaled toward Stephen's full implementation in a future version.

| | Stephen (HLS) | This Project (RTL) |
|---|---|---|
| Board | ZCU102 | ZedBoard |
| Bins | 200,000 | 64 |
| Arithmetic | Float | Fixed-point |
| Implementation | HLS compiler | Hand-written RTL |
| Throughput | 14 Ms/s | ~520 kS/s (estimated PoC) |

---

## Environment

| Tool | Version |
|---|---|
| Vivado | 2023.2 (or later) |
| Python | 3.10+ |
| NumPy | 1.24+ |
| Simulator | Vivado xsim |

To regenerate `DECAY_FACTORS.hex` and verify test vectors:
```bash
python swift_reference.py
```
