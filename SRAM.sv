// Quartus Prime Verilog Template
// Simple Dual Port RAM with separate read/write addresses and
// single read/write clock

module SRAM
(
	input [511:0] data,
	input [9:0] read_addr, write_addr,
	input we, clk,
	output logic [511:0] q
);

	// Declare the RAM variable
	logic [511:0] ram[1023:0];

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
