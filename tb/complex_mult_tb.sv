// complex_mult_tb.sv
// Testbench for complex_mult.sv (combinational)

module complex_mult_tb;

    logic signed [15:0] a, b; // decay factor (Q1.15)
    logic signed [22:0] c, d; // bin state (Q9.14)
    logic signed [24:0] re_out, im_out; // product (Q11.14)

    complex_mult uut (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .re_out(re_out),
        .im_out(im_out)
    );

    initial begin
        a = 0; b = 0; c = 0; d = 0;
        #10;

        // Test 1: bin 1 decay factor * (1.0 + 0j) — result should match decay factor
        a = 16'sd31607;  // bin 1 decay real: 0.96456 * 2^15
        b = 16'sd3113;   // bin 1 decay imag: 0.09501 * 2^15
        c = 23'sd16384;  // bin state real: 1.0 in Q9.14
        d = 23'sd0;      // bin state imag: 0
        #10;
        if (re_out === 25'sd15803 && im_out === 25'sd1556)  // expected: decay factor scaled by 1.0
            $display("PASS: Test 1");
        else
            $display("FAIL: Test 1 — re_out=%0d im_out=%0d", re_out, im_out);

        // Test 2: bin 0 decay factor * (1.0 + 0j) — bin 0 is purely real, so imag should be 0
        a = 16'sd31760;  // bin 0 decay real: 0.96923 * 2^15
        b = 16'sd0;      // bin 0 decay imag: 0
        c = 23'sd16384;  // bin state real: 1.0 in Q9.14
        d = 23'sd0;      // bin state imag: 0
        #10;
        if (re_out === 25'sd15880 && im_out === 25'sd0)  // expected: purely real output
            $display("PASS: Test 2");
        else
            $display("FAIL: Test 2 — re_out=%0d im_out=%0d", re_out, im_out);

        // Test 3: bin 8 decay factor * (0.5 + 0.25j) — non-trivial state, both outputs nonzero
        a = 16'sd22458;  // bin 8 decay real: 0.6854 * 2^15
        b = 16'sd22458;  // bin 8 decay imag: 0.6854 * 2^15 (45 degree bin)
        c = 23'sd8192;   // bin state real: 0.5 in Q9.14
        d = 23'sd4096;   // bin state imag: 0.25 in Q9.14
        #10;
        if (re_out === 25'sd2807 && im_out === 25'sd8421)
            $display("PASS: Test 3");
        else
            $display("FAIL: Test 3 — re_out=%0d im_out=%0d", re_out, im_out);

        // Test 4: bin 1 decay factor * (-1.0 + 0j) — negative bin state, outputs should negate Test 1
        a = 16'sd31607;   // bin 1 decay real: 0.96456 * 2^15
        b = 16'sd3113;    // bin 1 decay imag: 0.09501 * 2^15
        c = -23'sd16384;  // bin state real: -1.0 in Q9.14
        d = 23'sd0;       // bin state imag: 0
        #10;
        if (re_out === -25'sd15804 && im_out === -25'sd1557)
            $display("PASS: Test 4");
        else
            $display("FAIL: Test 4 — re_out=%0d im_out=%0d", re_out, im_out);

        // Test 5: bin 4 decay factor * (0.5 + 0.5j) — both inputs have imaginary parts
        a = 16'sd29342;  // bin 4 decay real: 0.8955 * 2^15
        b = 16'sd12154;  // bin 4 decay imag: 0.3709 * 2^15
        c = 23'sd8192;   // bin state real: 0.5 in Q9.14
        d = 23'sd8192;   // bin state imag: 0.5 in Q9.14
        #10;
        if (re_out === 25'sd4297 && im_out === 25'sd10374)
            $display("PASS: Test 5");
        else
            $display("FAIL: Test 5 — re_out=%0d im_out=%0d", re_out, im_out);

        $finish;
    end

endmodule
