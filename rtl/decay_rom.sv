// decay_rom.sv
// Reads precomputed decay factors from DECAY_FACTORS.hex into a ROM.
// Each entry is 32 bits: upper 16 = real (Q1.15), lower 16 = imag (Q1.15)

module decay_rom (
    input  logic clk,
    input  logic [5:0] addr,              // bin index (0-63)
    output logic signed [15:0] decay_re, // real part of decay factor (Q1.15)
    output logic signed [15:0] decay_im  // imag part of decay factor (Q1.15)
);

logic signed [31:0] mem [0:63]; // 64-entry ROM, one packed RE||IM word per bin

initial begin
    $readmemh("DECAY_FACTORS.hex", mem); // load hex file at simulation start
end

always_ff @(posedge clk) begin
    decay_re <= mem[addr][31:16]; // upper 16 bits = real
    decay_im <= mem[addr][15:0];  // lower 16 bits = imag
end

endmodule
