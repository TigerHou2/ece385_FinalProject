module terrain_collider	(	input				clk, reset,
									input	[479:0]	terrain_data, 
									input [9:0]		X, Y, DrawX, 
									input	[9:0]		D, U, L, R,
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
					DD <= terrain_data[Y+D];
					UU <= terrain_data[Y-U];
				end
			
				if ( (X-L) == DrawX )
				begin
					LL <= terrain_data[Y];
				end
			
				if ( (X+R) == DrawX )
				begin
					RR <= terrain_data[Y];
				end
			end
		end
							
endmodule

module player_collider	(	input [9:0]		X, Y, PX, PY, radius,
									output			collided	);
				
		int DX, DY;
		assign DX = X - PX;
		assign DY = Y - PY;
				
		always_comb
		begin
			if (DX*DX + DY*DY <= radius*radius)
				collided = 1'b1;
			else
				collided = 1'b0;
		end
									
endmodule
							