module terrain		(	input		clk, we, reset,
							input		[511:0]	terrain_in, 
							input		[9:0]		read_addr, write_addr, rng,
							output	[511:0]	terrain_out,
							output	[8:0]		terrain_height);
							
		logic select;
		
		logic 		toSRAM_we;
		logic [9:0] init_addr, noise, noise_last;
		logic [9:0] toSRAM_addr;
		logic [511:0] init_terrain;
		logic	[511:0] toSRAM_terrain;
		logic [8:0] height;
		
		parameter [8:0] default_height = 239;
		parameter [8:0] floor = 479;
		
		assign noise = rng;
		
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
					
					
		SRAM sram0	(	.clk, .we(toSRAM_we), .read_addr, .write_addr(toSRAM_addr), 
							.data(toSRAM_terrain), .q(terrain_out)	);
		
		
		parameter [9:0] Ncolumns = 640;
		
		always_ff @ (posedge clk)
		begin
		
				if (reset) begin
					
					height <= default_height;
					init_terrain[floor:default_height] <= {(floor-default_height){1'b1}};
					init_terrain[default_height-1:0] <= {default_height{1'b0}};
					init_addr <= 10'b0;
					
					noise_last <= 10'b0;
					
				end
					
					
					
				if ( init_addr < Ncolumns ) begin
				
					select <= 1'b1;
					
					height <= height + noise_last[4:1] + noise[6:3] - 10'd8;
					init_terrain[height+:32] <= 32'b1;
					init_terrain[height-:32] <= 32'b0;
					init_addr <= init_addr + 1'b1;
					
				
				end
				else begin
					
					select <= 1'b0;
					
				end
				
				
				noise_last <= noise;
		
		
		end
							
endmodule
							