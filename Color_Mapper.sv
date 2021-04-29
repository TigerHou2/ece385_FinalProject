//-------------------------------------------------------------------------
//    Color_Mapper.sv                                                    --
//    Stephen Kempf                                                      --
//    3-1-06                                                             --
//                                                                       --
//    Modified by David Kesler  07-16-2008                               --
//    Translated by Joe Meng    07-07-2013                               --
//                                                                       --
//    Fall 2014 Distribution                                             --
//                                                                       --
//    For use with ECE 385 Lab 7                                         --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------


module  color_mapper (	input							clk,
								input				[9:0]		DrawY,
								input				[479:0]	terrain_data,
								input				[17:0]	P1A, P2A, B1A, B2A, addrBG,
								input							P1D, P2D, B1D, B2D, drawBG, blank,
								output logic	[7:0]		Red, Green, Blue );
    
		// Terrain drawing logic
		logic terrain_on;
		
		always_comb
		begin:Terrain_on_proc
			if ( terrain_data[DrawY] == 1'b1 )
				terrain_on = 1'b1;
			else
				terrain_on = 1'b0;
		end
		
		// read sprite from SRAM
		logic [17:0] 	read_address;
		logic [4:0]		palette;

		spriteROM ram0 (	.clock(clk), .address(read_address), .q(palette)	);
  
		// map palette index to RGB
		logic [23:0]	RGB;
		always_comb
		begin
			unique case (palette)
				5'd0	:	RGB = 24'h23405B;
				5'd1	:	RGB = 24'hBB7182;
				5'd2	:	RGB = 24'hF8B293;
				5'd3	:	RGB = 24'h515474;
				5'd4	:	RGB = 24'hF9CE96;
				5'd5	:	RGB = 24'hF0737F;
				5'd6	:	RGB = 24'h035550;
				5'd7	:	RGB = 24'h2FBDA1;
				5'd8	:	RGB = 24'h93E2C0;
				5'd9	:	RGB = 24'h06837E;
				5'd10	:	RGB = 24'h62D8B6;
				5'd11	:	RGB = 24'hDFECCF;
				5'd12	:	RGB = 24'h252033;
				5'd13	:	RGB = 24'h5F4F71;
				5'd14	:	RGB = 24'h9E738F;
				5'd15	:	RGB = 24'h342845;
				5'd16	:	RGB = 24'h7A5E7E;
				5'd17	:	RGB = 24'h453D5E;
				5'd18	:	RGB = 24'h000000;
				5'd19	:	RGB = 24'h555555;
				5'd20	:	RGB = 24'hBBBBBB;
				5'd21	:	RGB = 24'hFFFFFF;
				5'd22	:	RGB = 24'h844731;
				5'd23	:	RGB = 24'h987632;
				5'd24	:	RGB = 24'h0055AA;
				5'd25	:	RGB = 24'h4E89C4;
				5'd26	:	RGB = 24'hBA3420;
				5'd27	:	RGB = 24'hEF5953;
				5'd28	:	RGB = 24'h231F20;
				5'd29	:	RGB = 24'hEB1A27;
				5'd30	:	RGB = 24'hF1EB30;
				5'd31	:	RGB = 24'hFBAF3A;
				default:	RGB = 24'h00FF00;
			endcase
		end
		
		assign Red 		= RGB[23:16];
		assign Green 	= RGB[15:8];
		assign Blue		= RGB[7:0];
		
		// select palette index
		always_comb
		begin:RGB_Display
			
			if (blank == 1'b0)
				read_address = 18'd1706;
				
			else if (B1D == 1'b1) 
				read_address = B1A;
				
			else if (P1D == 1'b1) 
				read_address = P1A;
				
			else if (B2D == 1'b1) 
				read_address = B2A;
				
			else if (P2D == 1'b1) 
				read_address = P2A;
				
			else if (terrain_on == 1'b1)
				read_address = 18'd1705;
				
			else if (drawBG == 1'b1)
				read_address = addrBG;
				
			else 
				read_address = 18'd1704;
			
		end 
    
endmodule
