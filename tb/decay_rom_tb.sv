// decay_rom_tb.sv
module decay_rom_tb;

    logic clk;
    logic [5:0] addr;
    logic signed [15:0] decay_re;
    logic signed [15:0] decay_im;

    decay_rom uut (
        .clk    (clk),
        .addr   (addr),
        .decay_re   (decay_re),
        .decay_im   (decay_im)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        addr = 0;
        @(posedge clk); #1;

        // test addr 0
        addr = 6'd0;
        @(posedge clk); #1;
        if (decay_re === 16'sd31760 && decay_im === 16'sd0)
            $display("PASS: addr 0");
        else
            $display("FAIL: addr 0 - decay_re=%0d decay_im=%0d", decay_re, decay_im);
        
        // test addr 1
        addr = 6'd1;
        @(posedge clk); #1;
        if (decay_re === 16'sd31607 && decay_im === 16'sd3113)
            $display("PASS: addr 1");
        else
            $display("FAIL: addr 1 - decay_re=%0d decay_im=%0d", decay_re, decay_im);
        
        // test addr 2
        addr = 6'd2;
        @(posedge clk); #1;
        if (decay_re === 16'sd31150 && decay_im === 16'sd6196)
            $display("PASS: addr 2");
        else
            $display("FAIL: addr 2 - decay_re=%0d decay_im=%0d", decay_re, decay_im);

        $finish;
    end
endmodule
