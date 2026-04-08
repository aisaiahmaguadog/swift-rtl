// bin_ram_tb.sv
module bin_ram_tb;
   
    logic clk;
    logic we;    // write enable
    logic [5:0] addr;  // bin index (0-63)
    logic signed [22:0] data_in_re;  // bin state real to write (Q9.14)
    logic signed [22:0] data_in_im;  // bin state imag to write (Q9.14)
    logic signed [22:0] data_out_re; // bin state real read out (Q9.14)
    logic signed [22:0] data_out_im;  // bin state imag read out (Q9.14)


    bin_ram uut (
        .clk    (clk),
        .we     (we),
        .addr   (addr),
        .data_in_re   (data_in_re),
        .data_in_im   (data_in_im),
        .data_out_re   (data_out_re),
        .data_out_im   (data_out_im)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        we = 0;
        addr = 0;
        data_in_re = 0;
        data_in_im = 0;
        @(posedge clk); #1;

        // Test 1 - check write and read functions
        we = 1;
        addr = 6'd0;
        data_in_re = 23'sd16384;
        data_in_im = 23'sd8192;
        @(posedge clk); #1;

        we = 0;
        @(posedge clk); #1;

        if (data_out_re === 23'sd16384 && data_out_im === 23'sd8192)
            $display("PASS: Test 1 - write/read addr 0");
        else
            $display("FAIL: Test 1 - re=%0d im=%0d ", data_out_re, data_out_im);

        // Test 2 - write and read to 2 registers, check for aliasing
        we = 1;
        addr = 6'd0;
        data_in_re = 23'sd14000;
        data_in_im = 23'sd7000;
        @(posedge clk); #1;
        we = 0;
        @(posedge clk); #1;

        we = 1;
        addr = 6'd5;
        data_in_re = 23'sd16000;
        data_in_im = 23'sd8000;
        @(posedge clk); #1;
        we = 0;

        addr = 6'd0;
        @(posedge clk); #1;
        if (data_out_re ===  23'sd14000 && data_out_im === 23'sd7000)
            $display("PASS: Test 2a - write/read addr 0");
        else
            $display("FAIL: Test 2a - re=%0d im=%0d", data_out_re, data_out_im);

        addr = 6'd5;
        @(posedge clk); #1;
        if (data_out_re ===  23'sd16000 && data_out_im === 23'sd8000)
            $display("PASS: Test 2b - write/read addr 5");
        else
            $display("FAIL: Test 2b - re=%0d im=%0d", data_out_re, data_out_im);

        // Test 3 - read before write
        we = 1;
        addr = 6'd42;
        data_in_re = 23'sd7500;
        data_in_im = 23'sd3500;
        @(posedge clk); #1;
        data_in_re = 23'sd10000;
        data_in_im = 23'sd4000;
        @(posedge clk); #1;
        we = 0;
        if (data_out_re ===  23'sd7500 && data_out_im === 23'sd3500)
            $display("PASS: Test 3 - read before write addr 42");
        else
            $display("FAIL: Test 3 - re=%0d im=%0d", data_out_re, data_out_im);

        // Test 4 - write enable off
        we = 1;
        addr = 6'd62;
        data_in_re = 23'sd12756;
        data_in_im = 23'sd7284;
        @(posedge clk); #1;
        we = 0;
        addr = 6'd62;
        data_in_re = 23'sd16000;
        data_in_im = 23'sd8000;
        @(posedge clk); #1;
        addr = 6'd62;
        if (data_out_re ===  23'sd12756 && data_out_im === 23'sd7284)
            $display("PASS: Test 4 - write enable off");
        else
            $display("FAIL: Test 4 - re=%0d im=%0d", data_out_re, data_out_im);

        // Test 5 - check uninitialized 
        we = 0;
        addr = 6'd47;
        @(posedge clk); #1;
        if (data_out_re ===  23'sd0 && data_out_im === 23'sd0)
            $display("PASS: Test 5 - uninitialized value");
        else
            $display("FAIL: Test 5 - re=%0d im=%0d", data_out_re, data_out_im);
        
        $finish;
    end
endmodule

