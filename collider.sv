module collider	(	input				clk, reset,
							input	[511:0]	terrain_data, 
							input [9:0]		X, Y, DrawX, radius,
							output			landed, bounce	);
							
		always_ff @ (posedge clk)
		begin
		
			if (reset)
			begin
				landed <= 1'b0;
				bounce <= 1'b0;
			end
				
			else if ( X == DrawX )
			begin
			
				if ( terrain_data[Y+radius] == 1'b1 ) begin
					landed <= 1'b1;
					bounce <= 1'b0;
				end
				else if ( terrain_data[Y-radius] == 1'b1 ) begin
					landed <= 1'b0;
					bounce <= 1'b1;
				end
				else begin
					landed <= 1'b0;
					bounce <= 1'b0;
				end
			end
		
		end
							
endmodule
							