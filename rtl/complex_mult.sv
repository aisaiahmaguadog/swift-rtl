// complex_mult.sv
// Computes (a + jb) * (c + jd)
//   a, b  — decay factor  Q1.15,  16-bit signed
//   c, d  — bin state     Q9.14,  23-bit signed
//
// Stage 1: four 16x23 multiplies  -> Q10.29, 39-bit
// Stage 2: subtract/add + >>15    -> Q11.14, 25-bit

module complex_mult (
    input  logic signed [15:0] a,       // decay factor real (Q1.15)
    input  logic signed [15:0] b,       // decay factor imag (Q1.15)
    input  logic signed [22:0] c,       // bin state real    (Q9.14)
    input  logic signed [22:0] d,       // bin state imag    (Q9.14)
    output logic signed [24:0] re_out,  // product real      (Q11.14)
    output logic signed [24:0] im_out   // product imag      (Q11.14)
);

    logic signed [38:0] ac, bd, ad, bc;  // full-precision intermediates (Q10.29)

    always_comb begin
        ac = a * c;
        bd = b * d;
        ad = a * d;
        bc = b * c;

        re_out = (ac - bd) >>> 15;  // real: ac - bd, scale back to Q11.14
        im_out = (ad + bc) >>> 15;  // imag: ad + bc, scale back to Q11.14
    end

endmodule
