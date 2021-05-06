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
						input  [479:0]	terrain_data,
						input  [7:0]	keycode,
						input  [9:0]	DrawX, DrawY,
						input				ID,
						input  [47:0]	controls,
						input  [9:0]	DX, DY,
						input				Dboomed,
						input  [9:0]	EX, EY,				// enemy position
						output [9:0]	PX, PY, VX, VY,	// self position and velocity
						output [9:0]	BX, BY, BVX, BVY,	// enemy bomb position and velocity
						output [31:0]	aim,
						output			boomed,
						output [9:0]	HP, HPP,
						output			drawPlayer, drawBomb,
						output [17:0]	addrPlayer, addrBomb,
						output [479:0]	terrain_out	);
    
	logic [9:0] X_Pos, X_Vel, Y_Pos, Y_Vel, width, height, centerX, centerY, health, health_padded;
	logic [17:0] facingOffset;
	
	assign PX = X_Pos;
	assign PY = Y_Pos;
	assign VX = X_Vel;
	assign VY = Y_Vel;
	
	assign HP	= health;
	assign HPP	= health_padded;
	
	logic [7:0] Jump, Shoot, Left, Right, AimL, AimR;
	assign Jump		= controls[47:40];
	assign Shoot	= controls[39:32];
	assign Left		= controls[31:24];
	assign Right	= controls[23:16];
	assign AimL		= controls[15:8];
	assign AimR		= controls[7:0];
	
	logic PowLast, PowThis;
	 
	parameter [9:0] X_Center=128;	// Center position on the X axis
	parameter [9:0] Y_Center=200;	// Center position on the Y axis
	parameter [9:0] X_Min=5;		// Leftmost point on the X axis
	parameter [9:0] X_Max=634;		// Rightmost point on the X axis
	parameter [9:0] Y_Min=5;		// Topmost point on the Y axis
	parameter [9:0] Y_Max=474;		// Bottommost point on the Y axis
	parameter [9:0] V_Max=7;		// maximum ball velocity
	parameter [9:0] health_Max = 100; // starting health
	
	logic [9:0] boomRadius, dmgRadius;
	assign boomRadius = 10'd19; // explosion radius
	assign  dmgRadius = 10'd30; // damage radius
	
	logic [7:0] gravCounter, input_X_Counter, input_Y_Counter, aim_Counter, health_Counter, dmg_Counter;
	
	parameter [7:0] grav_Counter_Max = 6;
	parameter [7:0] input_X_Counter_Max = 6;
	parameter [7:0] input_Y_Counter_Max = 32;
	parameter [7:0] aim_Counter_Max = 12;
	parameter [7:0] health_Counter_Max = 24;
	parameter [7:0] dmg_Counter_Max = 16;

	assign width 	= 15;
	assign height	= 25;
	assign centerX	= 8;
	assign centerY	= 13;
	
	logic	DD, UU, LL, RR;
	terrain_collider COLLIDER (	.clk, .reset, .terrain_data, 
											.X(X_Pos), .Y(Y_Pos), .DrawX, 
											.D(height-centerY), .U(centerY), .L(centerX), .R(width-centerX),
											.DD, .UU, .LL, .RR	);
	
	logic launch;
	logic [3:0]	angle;
	logic [2:0] power;
	logic			drawBombNaive;
	assign aim = {13'd0,power,12'd0,angle};
	
	parameter [3:0]	angle_Max = 8;
	parameter [2:0]	power_Max = 7;
	
	bomb BOMB	(	.clk, .reset, .frame_clk, .launch, .launchX(X_Pos), .launchY(Y_Pos), 
						.angle, .power, .terrain_data, .DrawX, .DrawY, .boomRadius, 
						.EX, .EY, .X(BX), .Y(BY), .VX(BVX), .VY(BVY), .boomed,
						.drawBomb(drawBombNaive), .addrBomb, .terrain_out	);
						
						
	int boomX, boomY;
	always_comb
	begin
		boomX = X_Pos - DX;
		boomY = Y_Pos - DY;
	end
	
	logic [9:0] dmgX, dmgY, dmgTot;
	always_comb
	begin
		if (X_Pos >= DX)
			dmgX = X_Pos - DX;
		else
			dmgX = DX - X_Pos;
		if (Y_Pos >= DY)
			dmgY = Y_Pos - DY;
		else
			dmgY = DY - Y_Pos;
		dmgTot = 10'd55 - dmgX - dmgY;
	end
	

	always_ff @ (posedge reset or posedge frame_clk )
	begin: Move_Ball
		if (reset)  // Asynchronous Reset
		begin 
			Y_Vel <= 10'd0;
			X_Vel <= 10'd0;
			Y_Pos <= Y_Center;
			X_Pos <= X_Center + {1'b0,{2{ID}},7'd0}; // set the two players apart
			gravCounter <= 8'h00;
			input_X_Counter <= 8'h00;
			input_Y_Counter <= 8'h00;
			aim_Counter <= 8'h00;
			health_Counter <= 8'h00;
			dmg_Counter <= 8'h00;
			angle <= 4'd6;
			power <= 3'd7;
			PowLast = 1'b0;
			PowThis = 1'b0;
			health <= health_Max;
			health_padded <= health_Max;
		end
			  
		else 
		begin
		
			// Damage detection
			dmg_Counter <= dmg_Counter + 1'b1;
			if ( ( ( boomX*boomX + boomY*boomY ) <= dmgRadius*dmgRadius )
					&& ( Dboomed )
					&& ( dmg_Counter >= dmg_Counter_Max ) ) begin
				health <= health - dmgTot;
				health_padded <= health - {1'b0,dmgTot[9:1]};
				dmg_Counter <= 8'h00;
			end
			
			// Health limits
			if (health[9] == 1'b1) begin
				health <= 10'd0;
				health_padded <= 10'd0;
			end
			
			
			// Health recovery
			health_Counter <= health_Counter + 1'b1;
			if (health_Counter >= health_Counter_Max) begin
				if (health < health_padded)
					health <= health + 1'b1;
				health_Counter <= 8'h00;
			end
		
		
			// Bomb controls
			aim_Counter <= aim_Counter + 1'b1;
			if (aim_Counter >= aim_Counter_Max) begin
			
				PowThis = 1'b0;
			
				unique case (keycode)
					AimL	:	if ( angle > 4'd0 ) begin			// Q, turn aim ccw
									angle <= angle - 1'b1;
									aim_Counter <= 8'h00;
								end
									
					AimR	:	if ( angle < angle_Max ) begin	// E, turn aim cw
									angle <= angle + 1'b1;
									aim_Counter <= 8'h00;
								end
					
					Shoot	:	begin										// S, launch bomb
									aim_Counter <= 8'h00;
									PowThis = 1'b1;
									power <= power + 1'b1;
								end
									
					default: launch <= 1'b0;
				endcase
				
				if ( PowThis == 1'b0 && PowLast == 1'b1 )
					launch <= 1'b1;
				else if ( PowThis == 1'b0 && PowLast == 1'b0 )
					power <= 3'd7;
					
				PowLast = PowThis;
				
			end
		
		
			// Gravity
			gravCounter <= gravCounter + 8'h01;
			if ( (DD == 1'b0) && (gravCounter >= grav_Counter_Max) )
			begin
				Y_Vel <= Y_Vel + 10'd1;
				gravCounter <= 8'h00;
			end
			
			
			// Terrain detection
			if ( (DD&UU) == 1'b1 ) begin
				X_Vel <= (~10'd1) + X_Vel[9] + X_Vel[9];
				Y_Vel <= (~10'd1) + Y_Vel[9] + Y_Vel[9];
			end
			else if (DD == 1'b1) begin
				X_Vel <= 10'd0;
				if ( Y_Vel[9] == 1'b0 )
					Y_Vel <= 10'd0;
				Y_Pos <= Y_Pos - 10'd2;
			end
			else if (UU == 1'b1) begin
				Y_Vel <= 10'd1;
			end
			
			if ( (LL&RR) == 1'b1 ) begin
				X_Vel <= 10'd0;
			end
			else if ( LL == 1'b1 ) begin
				X_Vel <= 10'd1;
			end
			else if (RR == 1'b1 ) begin
				X_Vel <= ~(10'd0);
			end
				
			
			// X-motion
			input_X_Counter <= input_X_Counter + 8'h01;
			if (input_X_Counter >= input_X_Counter_Max)
			begin
				unique case (keycode)
					Left	: 	X_Vel <= X_Vel - 10'd1;//A
					Right	: 	X_Vel <= X_Vel + 10'd1;//D
					default: ;
				endcase
				input_X_Counter <= 8'h00;
			end
			
			
			// Jump
			input_Y_Counter <= input_Y_Counter + 8'h01;
			if (input_Y_Counter >= input_Y_Counter_Max)
			begin
				unique case (keycode)
					Jump : 	begin
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
			if ( Y_Pos > (Y_Max - height + centerY) ) begin // bottom edge
				if ( Y_Vel[9] == 1'b0 ) begin
					Y_Pos <= Y_Max;
					Y_Vel <= ~(10'd0);
				end
			end
			else if ( Y_Pos < (Y_Min + centerY) ) begin // top edge
				if ( Y_Vel[9] == 1'b1 ) begin
					Y_Pos <= Y_Min;
					Y_Vel <= 10'd1;
				end
			end
			  
			if ( X_Pos > (X_Max - width + centerX) ) begin // right edge
				if ( X_Vel[9] == 1'b0 ) begin
					X_Pos <= X_Max;
					X_Vel <= ~(10'd0);
				end
			end
			else if ( X_Pos < (X_Min + centerX) ) begin // left edge
				if ( X_Vel[9] == 1'b1 ) begin
					X_Pos <= X_Min;
					X_Vel <= 10'd1;
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
			
			begin
			if ( keycode == Left ) // A
				facingOffset <= 18'd579;
			else if ( keycode == Right ) // D
				facingOffset <= 18'd204;
			end


		end  
	end
	
	
	// Draw power bar under health bar
	
	parameter [9:0] chargeL = 15; // length of one charge bar (8 total)
	parameter [9:0] chargeH = 7;  // width of one charge bar
	parameter [9:0] chargeG = 3;  // gap between charge bars
	parameter [9:0] charge_P1 = 32;  // starting X position of P1 charge bar
	parameter [9:0] charge_P2 = 416; // starting X position of P2 charge bar
	parameter [9:0] chargeY = 43; // Y position of charge bars
	
	logic [9:0] chargeX;
	
	always_comb
	begin
		if ( ID == 1'b0 )
			chargeX = charge_P1;
		else
			chargeX = charge_P2;
	end
	
	// Check electron beam position to determine whether sprite pixel is drawn
	
	int L_edge, U_edge;
	assign L_edge = X_Pos - centerX;
	assign U_edge = Y_Pos - centerY;
	
	// Check transparency mask to determine whether sprite pixel is drawn
	
	logic [17:0]	addrMaskPlayer;
	logic				letDrawPlayer, letDrawBomb;
	assign addrMaskPlayer = {8'd0,width}*({8'd0,DrawY}-U_edge[17:0])+({8'd0,DrawX}-L_edge[17:0])+facingOffset;
	maskROM mask (	.clk(~clk), .addr1(addrMaskPlayer[9:0]), .out1(letDrawPlayer),
										.addr2(addrBomb[9:0]), .out2(letDrawBomb));
										
	assign drawBomb = drawBombNaive & letDrawBomb;

	
	// Switch player color depending on team
	
	logic [17:0]	colorOffset;
	
	always_comb
	begin
		unique case (ID)
			1'b0:	colorOffset = 18'd0;
			1'b1:	colorOffset = 18'd750;
		endcase
	end
	
	// Combine above logic to set player color address and draw enable
	
	always_comb
	begin
		if (	DrawY >= chargeY && DrawY < chargeY+chargeH	) begin
		
			addrPlayer = 18'd1706;
			
			if ( 	DrawX >= chargeX && DrawX < chargeX+{3'b0,power,4'b0} && DrawX[3:2] != 2'b00 )
				drawPlayer = 1'b1;
			else
				drawPlayer = 1'b0;
		
		end else begin
		
			if ( 	DrawX >= L_edge && DrawX < L_edge + width &&
					DrawY >= U_edge && DrawY < U_edge + height	)
				drawPlayer = letDrawPlayer;
			else 
				drawPlayer = 1'b0;
		
			addrPlayer = addrMaskPlayer + colorOffset;
			
		end
	end
	
endmodule
