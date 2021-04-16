// Pseudo-random number generator

module PRNG	(	input 			Clk, Reset,
					input		[9:0]	Seed,
					output	[9:0] Out	);
					
	logic [9:0] seed0, seed1, seed2;
	logic [9:0] out0, out1, out2;
	
	assign seed0 = Seed;
	assign seed1 = {Seed[4:0], Seed[9:5]};
	assign seed2 = {Seed[0],Seed[1],Seed[2],Seed[3],Seed[4],Seed[5],Seed[6],Seed[7],Seed[8],Seed[9]};
	
	LFSR_A	LA (.Clk, .Reset, .Seed(seed0), .Out(out0));
	LFSR_B	LB (.Clk, .Reset, .Seed(seed1), .Out(out1));
	CASR		C0 (.Clk, .Reset, .Seed(seed2), .Out(out2));
	
	assign Out = out0 ^ out1 ^ out2;
					
endmodule


// x^10 + x^3 + 1
// Linear Feedback Shift Register using Galois form
// http://rdsl.csit-sun.pub.ro/docs/PROIECTARE%20cu%20FPGA%20CURS/lecture6[1].pdf
module LFSR_A (	input 			Clk, Reset,
						input		[9:0]	Seed,
						output	[9:0] Out	);

	logic [9:0] state; // 2^10-1 possible states for maximum length sequence
	
	always_ff @ (posedge Clk or posedge Reset) // asynchronous reset
	begin
	
		if (Reset)
			state <= Seed;
		else
			state <= {state[0], state[9:8], state[7]^state[0], state[6:1]};
	
	end
	
	assign Out = state;

endmodule


// another shifting pattern
// Linear Feedback Shift Register using Galois form
// http://rdsl.csit-sun.pub.ro/docs/PROIECTARE%20cu%20FPGA%20CURS/lecture6[1].pdf
module LFSR_B (	input 			Clk, Reset,
						input		[9:0]	Seed,
						output	[9:0] Out	);

	logic [9:0] state; // 2^10-1 possible states for maximum length sequence
	
	always_ff @ (posedge Clk or posedge Reset) // asynchronous reset
	begin
	
		if (Reset)
			state <= Seed;
		else
			state <= {state[8], state[7]^state[0], state[6:0], state[9]};
	
	end
	
	assign Out = state;

endmodule


// Cellular Automata Shift Register
// http://rdsl.csit-sun.pub.ro/docs/PROIECTARE%20cu%20FPGA%20CURS/lecture6[1].pdf
module CASR (	input 			Clk, Reset,
					input		[9:0]	Seed,
					output	[9:0] Out	);

	logic [12:0] state; // 2^10-1 possible states for maximum length sequence
	
	always_ff @ (posedge Clk or posedge Reset) // asynchronous reset
	begin
	
		if (Reset)
			state <= {3'b1,Seed};
		else begin
			state[12] <= state[11] ^ state[0];
			state[11] <= state[10] ^ state[12];
			state[10] <= state[9]  ^ state[11];
			state[9]  <= state[8]  ^ state[10];
			state[8]  <= state[7]  ^ state[9];
			state[7]  <= state[6]  ^ state[8];
			state[6]  <= state[5]  ^ state[7];
			state[5]  <= state[4]  ^ state[6];
			state[4]  <= state[3]  ^ state[5];
			state[3]  <= state[2]  ^ state[4];
			state[2]  <= state[1]  ^ state[3];
			state[1]  <= state[0]  ^ state[2];
			state[0]  <= state[12] ^ state[1];
		end
	
	end
	
	assign Out = state[9:0];

endmodule
