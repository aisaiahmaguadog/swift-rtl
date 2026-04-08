// bin_ram.sv
// Single-port synchronous BRAM storing the complex state for each of the 64 SWIFT bins.
// Each entry is 46 bits: upper 23 = real (Q9.14), lower 23 = imag (Q9.14)

module bin_ram (
    input  logic clk,
    input  logic we,    // write enable
    input  logic [5:0] addr,  // bin index (0-63)
    input  logic signed [22:0] data_in_re,  // bin state real to write (Q9.14)
    input  logic signed [22:0] data_in_im,  // bin state imag to write (Q9.14)
    output logic signed [22:0] data_out_re, // bin state real read out (Q9.14)
    output logic signed [22:0] data_out_im  // bin state imag read out (Q9.14)
);

logic signed [45:0] mem [0:63]; // 64-entry RAM, one packed RE||IM word per bin

initial begin
    

end

always_ff @(posedge clk) begin
    if (we)
        mem[addr] <= {data_in_re, data_in_im}; // pack and write both parts

    data_out_re <= mem[addr][45:23]; // upper 23 bits = real
    data_out_im <= mem[addr][22:0];  // lower 23 bits = imag
end

endmodule
