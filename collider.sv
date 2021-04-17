module collider	(	input				clk, reset,
							input	[511:0]	terrain_data, 
							input [9:0]		X, Y, DrawX, radius,
							output			DD, UU, LL, RR	);
							
		always_ff @ (posedge clk)
		begin
		
			if (reset)
			begin
				DD <= 1'b0;
				UU <= 1'b0;
				LL <= 1'b0;
				RR <= 1'b0;
			end
				
			else
			begin
				if ( X == DrawX )
				begin
					DD <= terrain_data[Y+radius];
					UU <= terrain_data[Y-radius];
				end
			
				if ( (X-radius) == DrawX )
				begin
					LL <= terrain_data[Y];
				end
			
				if ( (X+radius) == DrawX )
				begin
					RR <= terrain_data[Y];
				end
			end
		end
							
endmodule
							