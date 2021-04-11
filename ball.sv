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


module ball (	input 			Reset, frame_clk,
					input  [7:0]	keycode,
					output [9:0]	BallX, BallY, BallS );
    
	logic [9:0] Ball_X_Pos, Ball_X_Motion, Ball_Y_Pos, Ball_Y_Motion, Ball_Size;
	 
	parameter [9:0] Ball_X_Center=320;  // Center position on the X axis
	parameter [9:0] Ball_Y_Center=240;  // Center position on the Y axis
	parameter [9:0] Ball_X_Min=0;       // Leftmost point on the X axis
	parameter [9:0] Ball_X_Max=639;     // Rightmost point on the X axis
	parameter [9:0] Ball_Y_Min=0;       // Topmost point on the Y axis
	parameter [9:0] Ball_Y_Max=479;     // Bottommost point on the Y axis
	parameter [9:0] Ball_V_Max=30;		// maximum ball velocity
	
	logic [7:0] gravCounter, input_X_Counter, input_Y_Counter;
	
	parameter [7:0] grav_Counter_Max = 4;
	parameter [7:0] input_X_Counter_Max = 4;
	parameter [7:0] input_Y_Counter_Max = 16;

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
		
			// X-motion
			input_X_Counter <= input_X_Counter + 8'd1;
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
			input_Y_Counter <= input_Y_Counter + 8'd1;
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
			
			
			// Gravity
			gravCounter <= gravCounter + 8'd1;
			if (gravCounter >= grav_Counter_Max)
			begin
				Ball_Y_Motion <= Ball_Y_Motion + 10'd1;
				gravCounter <= 8'h00;
			end
			
			
			// Terminal velocity
//			if ( Ball_X_Motion[9] == 1'b1 )
//				if ( (~Ball_X_Motion) > Ball_V_Max )
//					Ball_X_Motion <= (~Ball_V_Max) + 10'b01;
//			else
//				if (  Ball_X_Motion > Ball_V_Max )
//					Ball_X_Motion <=  Ball_V_Max;
//			
//			if ( Ball_Y_Motion[9] == 1'b1 )
//				if ( (~Ball_Y_Motion) > Ball_V_Max )
//					Ball_Y_Motion <= (~Ball_V_Max) + 10'b01;
//			else
//				if (  Ball_Y_Motion > Ball_V_Max )
//					Ball_Y_Motion <=  Ball_V_Max;		
			
			
			// Bouncing
			if ( Ball_Y_Pos >= (Ball_Y_Max - Ball_Size) )  // Ball is at the bottom edge, BOUNCE!
			begin
				if ( Ball_Y_Motion[9] == 1'b0 )
				begin
					Ball_Y_Motion <= (~ (Ball_Y_Motion) + 10'd1);  // 2's complement.
				end
			end
			  
			if ( Ball_Y_Pos <= (Ball_Y_Min + Ball_Size) )  // Ball is at the top edge, BOUNCE!
			begin
				if ( Ball_Y_Motion[9] == 1'b1 )
				begin
					Ball_Y_Motion <= (~ (Ball_Y_Motion) + 10'd1);  // 2's complement.
				end
			end
			  
			if ( Ball_X_Pos >= (Ball_X_Max - Ball_Size) )  // Ball is at the Right edge, BOUNCE!
			begin
				if ( Ball_X_Motion[9] == 1'b0 )
				begin
					Ball_X_Motion <= (~ (Ball_X_Motion) + 10'd1);  // 2's complement.
				end
			end
			  
			if ( Ball_X_Pos <= (Ball_X_Min + Ball_Size) )  // Ball is at the Left edge, BOUNCE!
			begin
				if ( Ball_X_Motion[9] == 1'b1 )
				begin
					Ball_X_Motion <= (~ (Ball_X_Motion) + 10'd1);  // 2's complement.
				end
			end
			
			
			// Ball position update
			Ball_Y_Pos <= (Ball_Y_Pos + Ball_Y_Motion);  // Update ball position
			Ball_X_Pos <= (Ball_X_Pos + Ball_X_Motion);
			
			
			// Ball position constraint
			if ( Ball_X_Pos[9:8] == 2'b11 )
				Ball_X_Pos <= 10'd0;
			if ( Ball_Y_Pos[9:8] == 2'b11 )
				Ball_Y_Pos <= 10'd0;


		/**************************************************************************************
		ATTENTION! Please answer the following quesiton in your lab report! Points will be allocated for the answers!
		Hidden Question #2/2:
		Note that Ball_Y_Motion in the above statement may have been changed at the same clock edge
		that is causing the assignment of Ball_Y_pos.  Will the new value of Ball_Y_Motion be used,
		or the old?  How will this impact behavior of the ball during a bounce, and how might that 
		interact with a response to a keypress?  Can you fix it?  Give an answer in your Post-Lab.
		**************************************************************************************/


		end  
	end

	assign BallX = Ball_X_Pos;

	assign BallY = Ball_Y_Pos;

	assign BallS = Ball_Size;

endmodule
