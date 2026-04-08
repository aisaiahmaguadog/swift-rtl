module swift_core;
    logic clk;
    logic rst;
    logic sample_valid;
    logic sample_in;
    logic bin_valid;
    logic [5:0] bin_addr;
    logic signed [22:0] bin_out_re;
    logic signed [22:0] bin_out_im;

    swift_core uut (
        .clk    (clk),
        .rst   (rst),
        .sample_valid   (sample_valid),
        .sample_in   (sample_in),
        .bin_valid  (bin_valid),
        .bin_addr   (bin_addr),
        .bin_out_re (bin_out_re),
        .bin_out_im (bin_out_im)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin

        $finish
    end
endmodule