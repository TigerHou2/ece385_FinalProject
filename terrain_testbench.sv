module testbench();

timeunit 10ns;	// Half clock cycle at 50 MHz
			// This is the amount of time represented by #1 
timeprecision 1ns;

logic				clk, we, reset;
logic	[511:0]	terrain_in;
logic	[9:0]		read_addr, write_addr, rngSeed;
logic	[511:0]	terrain_out;
logic	[9:0]		terrain_height;
		
// Instantiate the SLC-3
terrain TOP(.*);

logic [9:0]	init_addr;
logic [9:0] rng;
logic [9:0] noise;
assign init_addr = TOP.init_addr;
assign rng = TOP.rng;
assign noise = TOP.noise;

// Toggle the clock
// #1 means wait for a delay of 1 timeunit
always begin : CLOCK_GENERATION
#1 clk = ~clk;
end

initial begin: CLOCK_INITIALIZATION
    clk = 0;
end 

// Testing begins here
// The initial block is not synthesizable
// Everything happens sequentially inside an initial block
// as in a software program
initial begin: TEST_VECTORS

we = 1'b0;
reset = 1'b0;
terrain_in = 512'd0;
read_addr = 10'd0;
write_addr = 10'd0;
rngSeed = 10'b0000000001;

#20 reset = 1'b1;
#20 reset = 1'b0;


end
endmodule