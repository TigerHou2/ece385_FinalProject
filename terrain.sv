module terrain		(	input  logic	clk, we, reset,
							input	 logic	[479:0]	terrain_in, 
							input	 logic	[9:0]		read_addr, write_addr, rngSeed,
							output logic	[479:0]	terrain_out,
							output logic	[9:0]		terrain_height	);
							
		logic select;
		
		logic 		toSRAM_we;
		logic [9:0] init_addr;
		logic [9:0] toSRAM_addr;
		logic [479:0] init_terrain;
		logic	[479:0] toSRAM_terrain;
		logic [9:0] height;
		assign terrain_height = height;
		
		parameter [9:0] default_height = 310;
		parameter [9:0] floor = 479;
		parameter [9:0] Ncolumns = 640;
		int idx;
		
		
		// Instantiate pseudo-random number generator
		
		logic [9:0] rng;
		PRNG rngTerrain(	.Clk(clk), .Reset(reset), .Seed(rngSeed), .Out(rng)	);
		
		
		// Combinatorial logic for mux-ing data to SRAM
		
		always_comb
		begin
				unique case (select)
						
						1'b0:	begin
								toSRAM_we		= we;
								toSRAM_addr 	= write_addr;
								toSRAM_terrain = terrain_in;
								end
						
						1'b1:	begin
								toSRAM_we		= 1'b1;
								toSRAM_addr 	= init_addr;
								toSRAM_terrain = init_terrain;
								end
								
				endcase
		end
		
		
		logic [9:0] noise;
		
		
		// Instatiate SRAM to store terrain data
		
		SRAM sram0	(	.clk(clk), .we(toSRAM_we), .read_addr(read_addr), .write_addr(toSRAM_addr), 
							.data(toSRAM_terrain), .q(terrain_out)	);
							
		
		
		// Control logic for generating / modifying terrain
		
		always_ff @ (posedge clk or posedge reset)
		begin
		
				// game reset, regenerate terrain
				if (reset) begin
				
					select <= 1'b1;
					
					noise <= 10'd0; // we achieve a sort of floating point precision by
										 // storing some bits after the decimal
					
					height <= default_height;
					for (idx = 0; idx <=floor; idx++)
					begin
						init_terrain[idx] <= (idx < height) ? 1'b0 : 1'b1;
					end
					init_addr <= 10'd0;
					
				end
				
				// regenerating terrain takes multiple cycles
				else if ( init_addr <= Ncolumns ) begin
				
					select <= 1'b1;
					
					// two terrain options:
					// -10'd53, rng[9:3], noise[9:7]  --  flatter
					// -10'd58, rng[9:3], noise[9:6]  --  exaggerated
					noise <= {noise[9],noise[9:1]} + {{2{noise[9]}},noise[9:2]} 
								+ {{3{noise[9]}},noise[9:3]} + {3'd0,rng[9:3]} - 10'd58;
					
					height <= height + {{6{noise[9]}},noise[9:6]};
					for (idx = 0; idx <=floor; idx++)
					begin
						init_terrain[idx] <= (idx < height) ? 1'b0 : 1'b1;
					end
					init_addr <= init_addr + 10'd1;
				
				end
				
				// terrain generation complete, do other things
				else begin
					
					select <= 1'b0;
					
					noise <= noise;
					
					height <= height;
					init_addr <= init_addr;
					init_terrain <= init_terrain;
					
				end
		
		
		end
							
endmodule
							