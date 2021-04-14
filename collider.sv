module collider	(	input				clk, reset,
							input	[511:0]	terrain_slice, 
							input [9:0]		row, radius, vx, vy,
							output [9:0]	vx_new, vy_new	);
							
		assign vx_new = 10'b0;
		assign vy_new = 10'b0;
							
endmodule
							