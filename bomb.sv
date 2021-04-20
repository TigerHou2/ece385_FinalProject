module bomb	(	input				clk, reset, frame_clk, launch,
					input		[9:0]	launchX, launchY,
					input		[3:0]	angle,
					input		[2:0]	power,
					input	 [511:0]	terrain_data,
					input		[9:0]	DrawX, DrawY,
					output			drawBomb,
					output  [10:0]	addrBomb,
					output [511:0]	terrain_out	);
    
	logic [9:0] X_Pos, X_Vel, Y_Pos, Y_Vel, width, height, centerX, centerY, boomRadius;
	logic [9:0] X_Vel_init, Y_Vel_init;
	 
	parameter [9:0] X_Default=700;	// Default position on the X axis
	parameter [9:0] Y_Default=500;	// Default position on the Y axis
	parameter [9:0] X_Min=5;			// Leftmost point on the X axis
	parameter [9:0] X_Max=634;			// Rightmost point on the X axis
	parameter [9:0] Y_Min=5;			// Topmost point on the Y axis
	parameter [9:0] Y_Max=474;			// Bottommost point on the Y axis
	parameter [9:0] V_Max=12;			// maximum ball velocity
	
	logic [7:0] gravCounter;
	
	parameter [7:0] grav_Counter_Max = 6;

	assign width 	= 12;
	assign height	= 17;
	assign centerX	= 5;
	assign centerY	= 9;
	
	
	logic	boom, DD, UU, LL, RR, out_of_bounds;
	collider COLLIDER (	.clk, .reset, .terrain_data, 
								.X(X_Pos), .Y(Y_Pos), .DrawX, 
								.D(10'd1), .U(10'd1), .L(10'd1), .R(10'd1),
								.DD, .UU, .LL, .RR	);
	
	
	logic removePixel;
	int DistX, DistY;
	assign boomRadius = 20;	// explosion radius
	assign DistX = X_Pos - DrawX;
	assign DistY = Y_Pos - DrawY;
	
	always_comb
	begin
		if ( ( DistX*DistX + DistY*DistY) <= (boomRadius*boomRadius) )
			removePixel = 1'b1;
		else
			removePixel = 1'b0;
	end
	
	
	// launch velocity pre-calculation
	logic [9:0] v_low, v_high, v_mid, v_top;
	always_comb
	begin
	
		v_top = power + 10'd4;
	
		unique case (power)
			3'd0: begin
					v_low 	= 10'd2;
					v_mid 	= 10'd3;
					v_high	= 10'd3;
					end
			3'd1: begin
					v_low 	= 10'd3;
					v_mid 	= 10'd4;
					v_high 	= 10'd4;
					end
			3'd2: begin
					v_low 	= 10'd3;
					v_mid 	= 10'd5;
					v_high 	= 10'd6;
					end
			3'd3: begin
					v_low 	= 10'd3;
					v_mid 	= 10'd6;
					v_high 	= 10'd5;
					end
			3'd4: begin
					v_low 	= 10'd3;
					v_mid 	= 10'd7;
					v_high 	= 10'd6;
					end
			3'd5: begin
					v_low 	= 10'd4;
					v_mid 	= 10'd8;
					v_high 	= 10'd6;
					end
			3'd6: begin
					v_low 	= 10'd4;
					v_mid 	= 10'd9;
					v_high 	= 10'd7;
					end
			3'd7: begin
					v_low 	= 10'd4;
					v_mid 	= 10'd10;
					v_high 	= 10'd8;
					end
		endcase
	end
	
	
	// launch velocity determination
	always_comb
	begin
		unique case (angle)
			4'h0:	begin
					X_Vel_init	= (~v_top)	+ 1'b1;
					Y_Vel_init	= 10'b0;
					end
			4'h1:	begin
					X_Vel_init	= (~v_high)	+ 1'b1;
					Y_Vel_init	= (~v_low)	+ 1'b1;
					end
			4'h2:	begin
					X_Vel_init	= (~v_mid)	+ 1'b1;
					Y_Vel_init	= (~v_mid)	+ 1'b1;
					end
			4'h3:	begin
					X_Vel_init	= (~v_low)	+ 1'b1;
					Y_Vel_init	= (~v_high)	+ 1'b1;
					end
			4'h4:	begin
					X_Vel_init	= 10'b0;
					Y_Vel_init	= (~v_top)	+ 1'b1;
					end
			4'h5:	begin
					X_Vel_init	= v_low;
					Y_Vel_init	= (~v_high)	+ 1'b1;
					end
			4'h6:	begin
					X_Vel_init	= v_mid;
					Y_Vel_init	= (~v_mid)	+ 1'b1;
					end
			4'h7:	begin
					X_Vel_init	= v_high;
					Y_Vel_init	= (~v_low)	+ 1'b1;
					end
			4'h8:	begin
					X_Vel_init	= v_top;
					Y_Vel_init	= 10'b0;
					end
			default: begin
					X_Vel_init	= 10'b0;
					Y_Vel_init	= 10'b0;
					end
		endcase		
	end
	
	
	// Delete projectile, deform terrain
	always_ff @ (posedge clk)
	begin
		terrain_out <= terrain_data;
		if ( (boom == 1'b1) && (removePixel==1'b1) )
			terrain_out[DrawY] <= 1'b0;
	end
	

	always_ff @ (posedge reset or posedge frame_clk )
	begin: Move_Ball
		if (reset)  // Asynchronous Reset
		begin 
			Y_Vel <= 10'd0;
			X_Vel <= 10'd0;
			Y_Pos <= Y_Default;
			X_Pos <= X_Default;
			gravCounter <= 8'h00;
			out_of_bounds <= 1'b0;
			boom <= 1'b1;
		end
		
		else if (launch == 1'b1)
		begin
			X_Pos <= launchX;
			Y_Pos <= launchY - 10'd4;
			X_Vel <= X_Vel_init;
			Y_Vel <= Y_Vel_init;
			gravCounter <= 8'h00;
			out_of_bounds <= 1'b0;
			boom <= 1'b0;
		end
			  
		else 
		begin 
		
		
			// Explosion detection
			if (boom == 1'b0) begin
				boom <= DD | UU | LL | RR | out_of_bounds;
			end
			
			if (boom == 1'b1) begin
				X_Vel <= 10'd0;
				Y_Vel <= 10'd0;
			end
		
		
			// Gravity
			gravCounter <= gravCounter + 8'h01;
			if ( (boom == 1'b0) && (gravCounter >= grav_Counter_Max) )
			begin
				Y_Vel <= Y_Vel + 10'd1;
				gravCounter <= 8'h00;
			end
			
			
			// Terminal velocity
			if ( X_Vel[9] == 1'b1 ) begin
				if ( (~(X_Vel)+10'd1) > V_Max ) begin
					X_Vel <= (~V_Max) + 10'd1;
				end
			end
			else begin
				if (  X_Vel > V_Max ) begin
					X_Vel <=  V_Max;
				end
			end
			
			if ( Y_Vel[9] == 1'b1 ) begin
				if ( (~(Y_Vel)+10'd1) > V_Max ) begin
					Y_Vel <= (~V_Max) + 10'd1;
				end
			end
			else begin
				if (  Y_Vel > V_Max ) begin
					Y_Vel <=  V_Max;
				end
			end
			
			
			// Screen edge detection
			if ( Y_Pos >= (Y_Max - height + centerY)) begin // bottom edge
				out_of_bounds <= 1'b1;
			end
			else if ( Y_Pos <= (Y_Min + centerY)) begin // top edge
				out_of_bounds <= 1'b1;
			end
			  
			if ( X_Pos >= (X_Max - width + centerX) ) begin // right edge
				out_of_bounds <= 1'b1;
			end
			else if ( X_Pos <= (X_Min + centerX) ) begin // left edge
				out_of_bounds <= 1'b1;
			end
			
			
			// Bomb position update
			begin
			Y_Pos <= (Y_Pos + Y_Vel);  // Update ball position
			X_Pos <= (X_Pos + X_Vel);
			end


		end  
	end
	
	int L_edge, U_edge;
	assign L_edge = X_Pos - centerX;
	assign U_edge = Y_Pos - centerY;
	
	always_comb
	begin
		if ( boom == 1'b1 )
			drawBomb = 1'b0;
		else if ( 	DrawX >= L_edge && DrawX <= L_edge + width &&
						DrawY >= U_edge && DrawY <= U_edge + height	)
			drawBomb = 1'b1;
		else 
			drawBomb = 1'b0;
	end
	
	assign addrBomb = width * (DrawY - U_edge) + (DrawX - L_edge);
					
endmodule
