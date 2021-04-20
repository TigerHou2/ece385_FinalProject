// Quartus Prime Verilog Template
// Simple Dual Port RAM with separate read/write addresses and
// single read/write clock

module SRAM
(
	input [479:0] data,
	input [9:0] read_addr, write_addr,
	input we, clk,
	output logic [479:0] q
);

	// Declare the RAM variable
	logic [479:0] ram[639:0];

	always_ff @ (posedge clk)
	begin
		// Write
		if (we)
			ram[write_addr] <= data;

		// Read (if read_addr == write_addr, return OLD data).	To return
		// NEW data, use = (blocking write) rather than <= (non-blocking write)
		// in the write assignment.	 NOTE: NEW data may require extra bypass
		// logic around the RAM.
		q <= ram[read_addr];
	end

endmodule
