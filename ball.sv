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


module player (	input 			Reset, frame_clk,
						input  [7:0]	keycode,
						input				landed, bounce, 
						output [9:0]	X, Y, S	);
    
	logic [9:0] Ball_X_Pos, Ball_X_Motion, Ball_Y_Pos, Ball_Y_Motion, Ball_Size;
	 
	parameter [9:0] Ball_X_Center=320;	// Center position on the X axis
	parameter [9:0] Ball_Y_Center=240;	// Center position on the Y axis
	parameter [9:0] Ball_X_Min=10;			// Leftmost point on the X axis
	parameter [9:0] Ball_X_Max=629;		// Rightmost point on the X axis
	parameter [9:0] Ball_Y_Min=10;			// Topmost point on the Y axis
	parameter [9:0] Ball_Y_Max=469;		// Bottommost point on the Y axis
	parameter [9:0] Ball_V_Max=10;		// maximum ball velocity
	
	logic [7:0] gravCounter, input_X_Counter, input_Y_Counter;
	
	parameter [7:0] grav_Counter_Max = 6;
	parameter [7:0] input_X_Counter_Max = 6;
	parameter [7:0] input_Y_Counter_Max = 32;

	assign Ball_Size = 4;  // assigns the value 4 as a 10-digit binary number, ie "0000000100"

	always_ff @ (posedge Reset or posedge frame_clk )
	begin: Move_Ball
		if (Reset)  // Asynchronous Reset
		begin 
			Ball_Y_Motion <= 10'd0;
			Ball_X_Motion <= 10'd0;
			Ball_Y_Pos <= Ball_Y_Center;
			Ball_X_Pos <= Ball_X_Center;
			gravCounter <= 8'h00;
			input_X_Counter <= 8'h00;
			input_Y_Counter <= 8'h00;
		end
			  
		else 
		begin 
		
		
			// Gravity
			gravCounter <= gravCounter + 8'h01;
			if (gravCounter >= grav_Counter_Max)
			begin
				Ball_Y_Motion <= Ball_Y_Motion + 10'd1;
				gravCounter <= 8'h00;
			end
			
			
			// Terrain detection
			if (landed == 1'b1) begin
				Ball_X_Motion <= 10'd0;
				if ( Ball_Y_Motion[9] == 1'b0 || Ball_Y_Motion == 10'd0 )
					Ball_Y_Motion <= 10'd0;
				Ball_Y_Pos <= Ball_Y_Pos - 10'd2;
			end
			
		
			// X-motion
			input_X_Counter <= input_X_Counter + 8'h01;
			if (input_X_Counter >= input_X_Counter_Max)
			begin
				unique case (keycode)
					8'h04 : 	Ball_X_Motion <= Ball_X_Motion - 10'd1;//A
					8'h07 : 	Ball_X_Motion <= Ball_X_Motion + 10'd1;//D
					default: ;
				endcase
				input_X_Counter <= 8'h00;
			end
			
			
			// Jump
			input_Y_Counter <= input_Y_Counter + 8'h01;
			if (input_Y_Counter >= input_Y_Counter_Max)
			begin
				unique case (keycode)
//					8'h16 : 	Ball_Y_Motion <= Ball_Y_Motion + 10'd1;//S
					8'h1A : 	begin
								Ball_Y_Motion <= Ball_Y_Motion - 10'd4;//W
								input_Y_Counter <= 8'h00;
								end
					default: ;
				endcase
			end
			
			
			// Terminal velocity
			if ( Ball_X_Motion[9] == 1'b1 ) begin
				if ( (~(Ball_X_Motion)+10'd1) > Ball_V_Max ) begin
					Ball_X_Motion <= (~Ball_V_Max) + 10'd1;
				end
			end
			else begin
				if (  Ball_X_Motion > Ball_V_Max ) begin
					Ball_X_Motion <=  Ball_V_Max;
				end
			end
			
			if ( Ball_Y_Motion[9] == 1'b1 ) begin
				if ( (~(Ball_Y_Motion)+10'd1) > Ball_V_Max ) begin
					Ball_Y_Motion <= (~Ball_V_Max) + 10'd1;
				end
			end
			else begin
				if (  Ball_Y_Motion > Ball_V_Max ) begin
					Ball_Y_Motion <=  Ball_V_Max;
				end
			end
			
			
			// Screen edge bouncing
			if ( Ball_Y_Pos >= (Ball_Y_Max - Ball_Size)) begin // bottom edge
				if ( Ball_Y_Motion[9] == 1'b0 ) begin
					Ball_Y_Motion <= (~ (Ball_Y_Motion) + 10'd1);  // 2's complement
				end
			end
			else if ( Ball_Y_Pos <= (Ball_Y_Min + Ball_Size) || bounce == 1'b1) begin // top edge
				if ( Ball_Y_Motion[9] == 1'b1 ) begin
					Ball_Y_Motion <= (~ (Ball_Y_Motion) + 10'd2);  // 2's complement + 1
				end
			end
			  
			if ( Ball_X_Pos >= (Ball_X_Max - Ball_Size) ) begin // right edge
				if ( Ball_X_Motion[9] == 1'b0 ) begin
					Ball_X_Motion <= (~ (Ball_X_Motion) + 10'd1);  // 2's complement
				end
			end
			else if ( Ball_X_Pos <= (Ball_X_Min + Ball_Size) ) begin // left edge
				if ( Ball_X_Motion[9] == 1'b1 ) begin
					Ball_X_Motion <= (~ (Ball_X_Motion) + 10'd2);  // 2's complement + 1
				end
			end
			
			
			// Ball position update
			begin
			Ball_Y_Pos <= (Ball_Y_Pos + Ball_Y_Motion);  // Update ball position
			Ball_X_Pos <= (Ball_X_Pos + Ball_X_Motion);
			end
			
			
			// Ball position constraint
			begin
			if ( Ball_X_Pos[9:8] == 2'b11 )
				Ball_X_Pos <= 10'd0;
			if ( Ball_Y_Pos[9:8] == 2'b11 )
				Ball_Y_Pos <= 10'd0;
			end


		end  
	end

	assign X = Ball_X_Pos;

	assign Y = Ball_Y_Pos;

	assign S = Ball_Size;

endmodule
