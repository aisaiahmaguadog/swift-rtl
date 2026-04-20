// swift_core.sv
// Main state machine — runs the SWIFT recurrence across all 64 bins per input sample.
// Submodules (complex_mult, decay_rom, bin_ram) are instantiated here and orchestrated
// cycle-by-cycle. Both BRAMs have 1-cycle read latency; state sequencing accounts for this.

module swift_core(
    input  logic clk,
    input  logic rst,
    input  logic sample_valid,
    input  logic signed [22:0] sample_in,    // Q9.14 — held stable for all 64 bins
    output logic bin_valid,                  // high for one cycle during UPDATE
    output logic [5:0] bin_indx_out,         // which bin bin_out_re/im belong to
    output logic signed [22:0] bin_out_re,   // updated bin state real (Q9.14)
    output logic signed [22:0] bin_out_im,   // updated bin state imag (Q9.14)
    output logic done                        // pulses high after bin 63 is written
);

// decay_rom outputs — registered by BRAM, valid one cycle after address presented
logic signed [15:0] decay_re;   // Q1.15
logic signed [15:0] decay_im;   // Q1.15

// bin_ram outputs — registered by BRAM, valid one cycle after address presented
logic signed [22:0] data_out_re;  // Q9.14
logic signed [22:0] data_out_im;  // Q9.14

// captured on the cycle sample_valid pulses; held stable across all 64 bins
logic signed [22:0] sample_latched;  // Q9.14

// bin_ram write-side
logic we;
logic signed [22:0] data_in_re;  // Q9.14 — saturated result written back in UPDATE
logic signed [22:0] data_in_im;  // Q9.14

// complex_mult outputs — combinational, valid same cycle inputs are stable (MULTIPLY state)
logic signed [24:0] mult_re;  // Q11.14
logic signed [24:0] mult_im;  // Q11.14

// bin_indx drives both BRAM addresses; set to 0 in IDLE so bin 0 data is ready on first MULTIPLY
logic [5:0] bin_indx;

// IDLE     — waits for sample_valid; bin_indx=0 so both BRAMs pre-address bin 0
// WAIT     — holds one cycle after incrementing bin_indx; lets BRAM outputs settle
// MULTIPLY — decay and bin state are valid; complex_mult result available combinationally
// UPDATE   — adds sample_in to mult result, saturates, writes back; asserts bin_valid
typedef enum logic [2:0] {
    IDLE,
    WAIT,
    MULTIPLY,
    UPDATE
} state_t;

state_t state;

endmodule
