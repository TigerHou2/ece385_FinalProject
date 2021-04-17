//-------------------------------------------------------------------------
//    Ball.sv                                                            --
//    Viral Mehta                                                        --
//    Spring 2005                                                        --
//                                                                       --
//    Modified by Stephen Kempf 03-01-2006                               --
//                              03-12-2007                               --
//    Translated by Joe Meng    07-07-2013                               --
//    Fall 2014 Distribution                                             --
//                                                                       --
//    For use with ECE 298 Lab 7                                         --
//    UIUC ECE Department                                                --
//-------------------------------------------------------------------------


module player (	input 			clk, reset, frame_clk,
						input  [511:0]	terrain_data,
						input  [7:0]	keycode,
						input  [9:0]	DrawX, DrawY,
						output [9:0]	X, Y, S, bombX, bombY, bombS,
						output			exploded,
						output [511:0]	terrain_out	);
    
	logic [9:0] X_Pos, X_Vel, Y_Pos, Y_Vel, Size;
	 
	parameter [9:0] X_Center=320;	// Center position on the X axis
	parameter [9:0] Y_Center=200;	// Center position on the Y axis
	parameter [9:0] X_Min=5;		// Leftmost point on the X axis
	parameter [9:0] X_Max=634;		// Rightmost point on the X axis
	parameter [9:0] Y_Min=5;		// Topmost point on the Y axis
	parameter [9:0] Y_Max=474;		// Bottommost point on the Y axis
	parameter [9:0] V_Max=10;		// maximum ball velocity
	
	logic [7:0] gravCounter, input_X_Counter, input_Y_Counter, aim_Counter;
	
	parameter [7:0] grav_Counter_Max = 6;
	parameter [7:0] input_X_Counter_Max = 6;
	parameter [7:0] input_Y_Counter_Max = 32;
	parameter [7:0] aim_Counter_Max = 16;

	assign Size = 4;  // assigns the value 4 as a 10-digit binary number, ie "0000000100"
	
	logic	DD, UU, impact;
	collider COLLIDER (	.clk, .reset, .terrain_data, 
								.X(X_Pos), .Y(Y_Pos), .DrawX, .radius(Size), .DD, .UU, .impact	);
	
	logic launch;
	logic [3:0]	angle;
	logic [2:0] power;
	
	parameter [3:0]	angle_Max = 8;
	parameter [2:0]	power_Max = 7;
	
	bomb BOMB	(	.clk, .reset, .frame_clk, .launch, .launchX(X_Pos), .launchY(Y_Pos), 
						.angle, .power, .terrain_data, .DrawX, .DrawY, 
						.exploded, .X(bombX), .Y(bombY), .S(bombS), .terrain_out	);
	

	always_ff @ (posedge reset or posedge frame_clk )
	begin: Move_Ball
		if (reset)  // Asynchronous Reset
		begin 
			Y_Vel <= 10'd0;
			X_Vel <= 10'd0;
			Y_Pos <= Y_Center;
			X_Pos <= X_Center;
			gravCounter <= 8'h00;
			input_X_Counter <= 8'h00;
			input_Y_Counter <= 8'h00;
			aim_Counter <= 8'h00;
			angle <= 4'd6;
			power <= 3'd4;
		end
			  
		else 
		begin 
		
		
			// Bomb controls
			aim_Counter <= aim_Counter + 1'b1;
			if (aim_Counter >= aim_Counter_Max) begin
				unique case (keycode)
					8'h14	:	if ( angle > 4'd0 ) begin			// Q, turn aim ccw
									angle <= angle - 1'b1;
									aim_Counter <= 8'h00;
								end
									
					8'h08	:	if ( angle < angle_Max ) begin	// E, turn aim cw
									angle <= angle + 1'b1;
									aim_Counter <= 8'h00;
								end
									
					8'h1E	:	if ( power > 3'd0 ) begin			// 1, decrease power
									power <= power - 1'b1;
									aim_Counter <= 8'h00;
								end
								
					8'h20	:	if ( power < power_Max ) begin	// 3, increase power
									power <= power + 1'b1;
									aim_Counter <= 8'h00;
								end
					
					8'h16	:	begin										// S, launch bomb
									launch <= 1'b1;
									aim_Counter <= 8'h00;
								end
									
					default: launch <= 1'b0;
				endcase
			end
				
		
		
			// Gravity
			gravCounter <= gravCounter + 8'h01;
			if (gravCounter >= grav_Counter_Max)
			begin
				Y_Vel <= Y_Vel + 10'd1;
				gravCounter <= 8'h00;
			end
			
			
			// Terrain detection
			if (DD == 1'b1) begin
				X_Vel <= 10'd0;
				if ( Y_Vel[9] == 1'b0 || Y_Vel == 10'd0 )
					Y_Vel <= 10'd0;
				Y_Pos <= Y_Pos - 10'd2;
			end
			else if (UU == 1'b1) begin
				Y_Vel <= 10'd1;
			end
			
			if (impact == 1'b1) begin
				X_Vel <= 10'b0;
			end
			
		
			// X-motion
			input_X_Counter <= input_X_Counter + 8'h01;
			if (input_X_Counter >= input_X_Counter_Max)
			begin
				unique case (keycode)
					8'h04 : 	X_Vel <= X_Vel - 10'd1;//A
					8'h07 : 	X_Vel <= X_Vel + 10'd1;//D
					default: ;
				endcase
				input_X_Counter <= 8'h00;
			end
			
			
			// Jump
			input_Y_Counter <= input_Y_Counter + 8'h01;
			if (input_Y_Counter >= input_Y_Counter_Max)
			begin
				unique case (keycode)
//					8'h16 : 	Y_Vel <= Y_Vel + 10'd1;//S
					8'h1A : 	begin
								Y_Vel <= Y_Vel - 10'd4;//W
								input_Y_Counter <= 8'h00;
								end
					default: ;
				endcase
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
			
			
			// Screen edge bouncing
			if ( Y_Pos >= (Y_Max - Size)) begin // bottom edge
				if ( Y_Vel[9] == 1'b0 ) begin
					Y_Vel <= (~ (Y_Vel) + 10'd1);
				end
			end
			else if ( Y_Pos <= (Y_Min + Size)) begin // top edge
				if ( Y_Vel[9] == 1'b1 ) begin
					Y_Vel <= (~ (Y_Vel) + 10'd1);
				end
			end
			  
			if ( X_Pos >= (X_Max - Size) ) begin // right edge
				if ( X_Vel[9] == 1'b0 ) begin
					X_Vel <= (~ (X_Vel) + 10'd1);
				end
			end
			else if ( X_Pos <= (X_Min + Size) ) begin // left edge
				if ( X_Vel[9] == 1'b1 ) begin
					X_Vel <= (~ (X_Vel) + 10'd1);
				end
			end
			
			
			// Ball position update
			begin
			Y_Pos <= (Y_Pos + Y_Vel);  // Update ball position
			X_Pos <= (X_Pos + X_Vel);
			end
			
			
			// Ball position constraint
			begin
			if ( X_Pos[9:8] == 2'b11 )
				X_Pos <= 10'd0;
			if ( Y_Pos[9:8] == 2'b11 )
				Y_Pos <= 10'd0;
			end


		end  
	end

	assign X = X_Pos;

	assign Y = Y_Pos;

	assign S = Size;

endmodule
