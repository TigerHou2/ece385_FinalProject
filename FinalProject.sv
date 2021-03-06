//------------------------------------------------------------------------
//																								--
//			ECE 385 Final Project, Spring 2021										--
//			Tiger Hou																		--
//																								--
//------------------------------------------------------------------------


module FinalProject (

      ///////// Clocks /////////
      input     CLOCK_50,

      ///////// KEY /////////
      input    [ 1: 0]   KEY,

      ///////// SW /////////
      input    [ 9: 0]   SW,

      ///////// LEDR /////////
      output   [ 9: 0]   LEDR,

      ///////// HEX /////////
      output   [ 7: 0]   HEX0,
      output   [ 7: 0]   HEX1,
//      output   [ 7: 0]   HEX2,
      output   [ 7: 0]   HEX3,
      output   [ 7: 0]   HEX4,
//      output   [ 7: 0]   HEX5,

      ///////// SDRAM /////////
      output             DRAM_CLK,
      output             DRAM_CKE,
      output   [12: 0]   DRAM_ADDR,
      output   [ 1: 0]   DRAM_BA,
      inout    [15: 0]   DRAM_DQ,
      output             DRAM_LDQM,
      output             DRAM_UDQM,
      output             DRAM_CS_N,
      output             DRAM_WE_N,
      output             DRAM_CAS_N,
      output             DRAM_RAS_N,

      ///////// VGA /////////
      output             VGA_HS,
      output             VGA_VS,
      output   [ 3: 0]   VGA_R,
      output   [ 3: 0]   VGA_G,
      output   [ 3: 0]   VGA_B,


      ///////// ARDUINO /////////
      inout    [15: 0]   ARDUINO_IO,
      inout              ARDUINO_RESET_N 

);




logic Reset_h, vssig, blank, sync, VGA_Clk;


//=======================================================
//  REG/WIRE declarations
//=======================================================
	logic SPI0_CS_N, SPI0_SCLK, SPI0_MISO, SPI0_MOSI, USB_GPX, USB_IRQ, USB_RST;
	logic [3:0]		hex_num_4, hex_num_3, hex_num_1, hex_num_0; //4 bit input hex digits
	logic [9:0]		drawxsig, drawysig;
	logic [7:0]		Red, Blue, Green;
	logic [15:0]	keycode;
	logic [7:0]		key_p1, key_p2;										// (@ 2.5 MHz)	player input from keyboard/software
	logic [17:0]	P1A, P2A, B1A, B2A; 									// (@ 50 MHz)	sprite address
	logic				P1D, P2D, B1D, B2D;									// (@ 50 MHz)	player/bomb draw enable
	logic				BB1, BB2;												// (@ 60 Hz)	exploded
	logic	[47:0]	P1C, P2C;												// (fixed)		keyboard control mapping
	logic [31:0]	P2_aim;													// (@ 60 Hz)	player 2 (AI) aim angle
	logic [9:0]		B1X, B1Y, B2X, B2Y, B1VX, B1VY, B2VX, B2VY;	// (@ 60 Hz)	bomb pos/vel
	logic [9:0]		P1X, P1Y, P2X, P2Y, P1VX, P1VY, P2VX, P2VY;	// (@ 60 Hz)	player pos/vel
	logic [9:0]		HP1, HPP1, HP2, HPP2;								// (@ 60 Hz)	player health and padding
	logic [17:0]	addrBG;													// (@ 50 MHz)	background address
	logic				drawBG;													// (@ 50 MHz)	draw background enable

//=======================================================
//  Structural coding
//=======================================================
	assign ARDUINO_IO[10] = SPI0_CS_N;
	assign ARDUINO_IO[13] = SPI0_SCLK;
	assign ARDUINO_IO[11] = SPI0_MOSI;
	assign ARDUINO_IO[12] = 1'bZ;
	assign SPI0_MISO = ARDUINO_IO[12];
	
	assign ARDUINO_IO[9] = 1'bZ; 
	assign USB_IRQ = ARDUINO_IO[9];
		
	//Assignments specific to Circuits At Home UHS_20
	assign ARDUINO_RESET_N = USB_RST;
	assign ARDUINO_IO[7] = USB_RST;//USB reset 
	assign ARDUINO_IO[8] = 1'bZ; //this is GPX (set to input)
	assign USB_GPX = 1'b0;//GPX is not needed for standard USB host - set to 0 to prevent interrupt
	
	//Assign uSD CS to '1' to prevent uSD card from interfering with USB Host (if uSD card is plugged in)
	assign ARDUINO_IO[6] = 1'b1;
	
	//HEX drivers to convert numbers to HEX output
	HexDriver hex_driver4 (hex_num_4, HEX4[6:0]);
	assign HEX4[7] = 1'b1;
	
	HexDriver hex_driver3 (hex_num_3, HEX3[6:0]);
	assign HEX3[7] = 1'b1;
	
	HexDriver hex_driver1 (hex_num_1, HEX1[6:0]);
	assign HEX1[7] = 1'b1;
	
	HexDriver hex_driver0 (hex_num_0, HEX0[6:0]);
	assign HEX0[7] = 1'b1;
	
	
	logic Toggle_h, AI_on;
	
	assign {Reset_h}  = ~(KEY[0]);	// Assign key 0 to reset
	assign {Toggle_h} = ~(KEY[1]);	// Assign key 1 aimbot toggle
	
	always_ff @ (posedge Toggle_h)
	begin
			AI_on <= ~AI_on;
	end

	// Our A/D converter is only 12 bit
	assign VGA_R = Red[7:4];
	assign VGA_B = Blue[7:4];
	assign VGA_G = Green[7:4];
	
	// Terrain data assignments
	logic [479:0]	T1O, T2O, Tmerged, terrain_out;
	logic [9:0]		terrain_addr;
	logic [9:0]		terrain_height;
	logic [17:0]	addrTerrain;
	logic				drawTerrain;
	
	always_ff @ (negedge CLOCK_50)
	begin
		terrain_addr <= drawxsig - 1'b1;
	end
	
	// Player keycode assignments
	assign key_p1 = keycode[15:8];
	assign key_p2 = keycode[7:0];
	
	// Player controls
	assign P1C = {8'd26, 8'd22, 8'd04, 8'd07, 8'd20, 8'd08}; // W,S,A,D,Q,E
	assign P2C = {8'd12, 8'd14, 8'd13, 8'd15, 8'd24, 8'd18}; // I,K,J,L,U,O
	
	// Scoring
	logic				drawScore;
	logic [17:0]	addrScore;
	
	// Debug
	assign LEDR = HPP1;
	
	
	finalsoc u0 (
		.clk_50_clk                        (CLOCK_50),  		//clk_50.clk
		.reset_50_reset_n                  (1'b1),         	//reset_50.reset_n
		.altpll_0_locked_conduit_export    (),						//altpll_0_locked_conduit.export
		.altpll_0_phasedone_conduit_export (),						//altpll_0_phasedone_conduit.export
		.altpll_0_areset_conduit_export    (),						//altpll_0_areset_conduit.export
		.key_external_connection_export    (KEY),					//key_external_connection.export

		// SDRAM
		.sdram_clk_clk(DRAM_CLK),										//clk_sdram.clk
		.sdram_wire_addr(DRAM_ADDR),									//sdram_wire.addr
		.sdram_wire_ba(DRAM_BA),										//.ba
		.sdram_wire_cas_n(DRAM_CAS_N),								//.cas_n
		.sdram_wire_cke(DRAM_CKE),										//.cke
		.sdram_wire_cs_n(DRAM_CS_N),									//.cs_n
		.sdram_wire_dq(DRAM_DQ),										//.dq
		.sdram_wire_dqm({DRAM_UDQM,DRAM_LDQM}),					//.dqm
		.sdram_wire_ras_n(DRAM_RAS_N),								//.ras_n
		.sdram_wire_we_n(DRAM_WE_N),									//.we_n

		// USB SPI	
		.spi0_SS_n(SPI0_CS_N),
		.spi0_MOSI(SPI0_MOSI),
		.spi0_MISO(SPI0_MISO),
		.spi0_SCLK(SPI0_SCLK),
		
		// USB GPIO
		.usb_rst_export(USB_RST),
		.usb_irq_export(USB_IRQ),
		.usb_gpx_export(USB_GPX),
		
		// LEDs and HEX
		.hex_digits_export({hex_num_4, hex_num_3, hex_num_1, hex_num_0}),
//		.leds_export({hundreds, signs, LEDR}),
		.keycode_export(keycode),
		
		// Player and bomb pos/vel
		.p1_pos_export({6'd0,P1X,6'd0,P1Y}),
		.p1_vel_export({{6{P1VX[9]}},P1VX,{6{P1VY[9]}},P1VY}),
		.p2_pos_export({6'd0,P2X,6'd0,P2Y}),
		.p2_vel_export({{6{P2VX[9]}},P2VX,{6{P2VY[9]}},P2VY}),
		.b1_pos_export({6'd0,B1X,6'd0,B1Y}),
		.b1_vel_export({{6{B1VX[9]}},B1VX,{6{B1VY[9]}},B1VY}),
		
		// AI aim
		.aim_export(P2_aim), 
		
		// AI toggle
		.aim_toggle_export(AI_on)
		
	 );


//instantiate a vga_controller, ball, and color_mapper here with the ports.

player P1				(	.clk(CLOCK_50), .reset(Reset_h), .frame_clk(VGA_VS), .terrain_data(terrain_out),
								.keycode(key_p1), .DrawX(drawxsig), .DrawY(drawysig), .ID(1'b0), .controls(P1C),
								.DX(B2X), .DY(B2Y), .Dboomed(BB2), .boomed(BB1), .HP(HP1), .HPP(HPP1),
								.EX(P2X), .EY(P2Y), .PX(P1X), .PY(P1Y), .VX(P1VX), .VY(P1VY), 
								.BX(B1X), .BY(B1Y), .BVX(B1VX), .BVY(B1VY),
								.drawPlayer(P1D), .drawBomb(B1D), .addrPlayer(P1A), .addrBomb(B1A),
								.terrain_out(T1O));
								
player P2				(	.clk(CLOCK_50), .reset(Reset_h), .frame_clk(VGA_VS), .terrain_data(terrain_out),
								.keycode(key_p2), .DrawX(drawxsig), .DrawY(drawysig), .ID(1'b1), .controls(P2C),
								.DX(B1X), .DY(B1Y), .Dboomed(BB1), .boomed(BB2), .aim(P2_aim), .HP(HP2), .HPP(HPP2),
								.EX(P1X), .EY(P1Y), .PX(P2X), .PY(P2Y), .VX(P2VX), .VY(P2VY), 
								.BX(B2X), .BY(B2Y), .BVX(B2VX), .BVY(B2VY),
								.drawPlayer(P2D), .drawBomb(B2D), .addrPlayer(P2A), .addrBomb(B2A),
								.terrain_out(T2O));
				
vga_controller VGA	(	.Clk(CLOCK_50), .Reset(Reset_h), .hs(VGA_HS), .vs(VGA_VS),
								.pixel_clk(VGA_Clk), .blank, .sync, .DrawX(drawxsig), .DrawY(drawysig)  );

color_mapper CMAP		(	.clk(CLOCK_50), 
								.P1A, .P2A, .B1A, .B2A, .addrBG, .addrTerrain, .addrScore,
								.P1D, .P2D, .B1D, .B2D, .drawBG, .drawTerrain, .drawScore,
								.blank, .Red, .Green, .Blue  );

terrain TERRAIN		(	.clk(CLOCK_50), .we((~B1D)&(~B2D)&blank), .reset(Reset_h), 
								.DrawX(drawxsig), .DrawY(drawysig), .terrain_in(Tmerged), 
								.read_addr(drawxsig), .write_addr(terrain_addr), .rngSeed(SW), 
								.terrain_out, .terrain_height, .addrTerrain, .drawTerrain);
								
terrain_merger MERGER(	.T1(T1O), .T2(T2O), .Tout(Tmerged)	);

background BACKGROUND(	.mapSelect(SW[9]), .DrawX(drawxsig), .DrawY(drawysig), .drawBG, .addrBG);

scoreboard SCOREBOARD(	.DrawX(drawxsig), .DrawY(drawysig), .HP1, .HPP1, .HP2, .HPP2, .drawScore, .addrScore);

endmodule
