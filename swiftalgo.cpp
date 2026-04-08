// Used to declare the types of variables in a slightly more efficient method for hardware
#include <ap_int.h>

// Used to implement math more efficiently on hardware
#include <hls_math.h>

// C++ library to easily declare a complex type for arrays or variables
#include <complex>

// A hardware friendly way to declare streaming variables
#include <hls_stream.h>

// Used to attach side band information to the input and output ports for the DMA
#include <ap_axi_sdata.h>

// Typedef declaring the input size (tdata), the tkeep, tstrb, and tlast
typedef ap_axiu<32,0,0,0> axis32_t;

// Main function of the hardware kernel representing the Sliding Window Infinite Fourier Transform (SWIFT)
void swift(
    hls::stream<axis32_t>& samples_in,
    hls::stream<axis32_t>& mag_out,
    int tau,
    int N,
	int samples,
	int stride)
{
	// Creates the input for the SWIFT block
#pragma HLS INTERFACE axis port=samples_in

	// Creates the output for the SWIFT block
#pragma HLS INTERFACE axis port=mag_out

	// Declares values that will be configured via the slave axilite interface by the Processing System (PS)
#pragma HLS INTERFACE s_axilite port=tau    bundle=CTRL_BUS
#pragma HLS INTERFACE s_axilite port=N     bundle=CTRL_BUS
#pragma HLS INTERFACE s_axilite port=samples bundle=CTRL_BUS
#pragma HLS INTERFACE s_axilite port=stride	bundle=CTRL_BUS

	// States this kernel produces outputs
#pragma HLS INTERFACE s_axilite port=return bundle=CTRL_BUS

    // Creates a memory space to fit float variable but fits a 32 bit variable
    // so no data loss occurs from transferring it
    union f2u { float f; int32_t u; } conv;

    // This is the real part of the decay factors, which is a constant dependent on tau
    const float decay_real = hls::expf(-1.0f / (float)tau);

    // Stores the bin state, the bins being the frequency range of the sampling rate
    static std::complex<float> bins[200000] = {};
    // Binds the bins to the BRAM element on the FPGA board
	#pragma HLS BIND_STORAGE variable=bins type=ram_t2p impl=bram latency=1

    // Decay factors used to prevent exploding or sinking behavior when implementing the SWIFT math
    static std::complex<float> decay_factors[200000];
	#pragma HLS BIND_STORAGE variable=decay_factors type=ram_t2p impl=bram latency=1

	// Flag to compute decay factors once while also contributing to the SWIFT computation during the process, efficiency
	static bool factors_init = false;

	Samp_Loop:
	for (int samp = 0; samp < samples; samp++) {

		// Reads the input sample using the typedef variable declared for the input
		axis32_t read_samp = samples_in.read();

		// Converts the typedef variable above to just the data
		ap_int<32> cur_samp = (ap_int<32>)read_samp.data;

		Bin_loop:
		for (int bin = 0; bin < N; bin++) {
			#pragma HLS PIPELINE II=1

			// Generate the factor during the first sample
			if (samp == 0 && factors_init == false) {
				float omega = 2.0f * M_PI * (float)bin / (float)N;
				decay_factors[bin] = decay_real * std::complex<float>(hls::cosf(omega), hls::sinf(omega));
			}

			// Perform the SWIFT math using the factor
			bins[bin] = std::complex<float>((float)cur_samp, 0) + (decay_factors[bin] * bins[bin]);

			// 3. Output logic
			if ((samp % stride) == 0) {
				float re = bins[bin].real();
				float im = bins[bin].imag();
				float mag = hls::sqrtf(re * re + im * im);

				// Outputs the data within the typedef declared for the output
				axis32_t out_pkt;
				conv.f = mag;
				out_pkt.data = (ap_int<32>)conv.u;
				out_pkt.keep = -1;
				out_pkt.strb = -1;
				out_pkt.last = (bin == N - 1);
				mag_out.write(out_pkt);
			}

		}
		factors_init = true;
	}
}
