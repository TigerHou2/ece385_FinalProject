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
								input				[511:0]	terrain_data,
								input				[10:0]	addrPlayer, addrBomb,
								input							drawPlayer, drawBomb, blank,
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
		logic [10:0] 	read_address;
		logic [7:0]		palette;

		spriteRAM ram0 (	.clk, .we(1'b0), .write_address(11'd0), .data_in(8'd0), 
													  .read_address, .data_out(palette)	);
  
		// map palette index to RGB
		logic [23:0]	RGB;
		always_comb
		begin
			unique case (palette)
				8'd0	:	RGB = 24'h23405B;
				8'd1	:	RGB = 24'hBB7182;
				8'd2	:	RGB = 24'hF8B293;
				8'd3	:	RGB = 24'h515474;
				8'd4	:	RGB = 24'hF9CE96;
				8'd5	:	RGB = 24'hF0737F;
				8'd6	:	RGB = 24'h035550;
				8'd7	:	RGB = 24'h2FBDA1;
				8'd8	:	RGB = 24'h93E2C0;
				8'd9	:	RGB = 24'h06837E;
				8'd10	:	RGB = 24'h62D8B6;
				8'd11	:	RGB = 24'hDFECCF;
				8'd12	:	RGB = 24'h252033;
				8'd13	:	RGB = 24'h5F4F71;
				8'd14	:	RGB = 24'h9E738F;
				8'd15	:	RGB = 24'h342845;
				8'd16	:	RGB = 24'h7A5E7E;
				8'd17	:	RGB = 24'h453D5E;
				8'd18	:	RGB = 24'h000000;
				8'd19	:	RGB = 24'h555555;
				8'd20	:	RGB = 24'hBBBBBB;
				8'd21	:	RGB = 24'hFFFFFF;
				8'd22	:	RGB = 24'h844731;
				8'd23	:	RGB = 24'h987632;
				8'd24	:	RGB = 24'h0055AA;
				8'd25	:	RGB = 24'h4E89C4;
				8'd26	:	RGB = 24'hBA3420;
				8'd27	:	RGB = 24'hEF5953;
				8'd28	:	RGB = 24'h231F20;
				8'd29	:	RGB = 24'hEB1A27;
				8'd30	:	RGB = 24'hF1EB30;
				8'd31	:	RGB = 24'hFBAF3A;
			endcase
		end
		
		assign Red 		= RGB[23:16];
		assign Green 	= RGB[15:8];
		assign Blue		= RGB[7:0];
		
		// select palette index
		always_comb
		begin:RGB_Display
			
			if (blank == 1'b0)
				read_address = 11'd1706;
				
			else if (drawBomb == 1'b1) 
				read_address = addrBomb;
				
			else if (drawPlayer == 1'b1) 
				read_address = addrPlayer;
				
			else if (terrain_on == 1'b1)
				read_address = 11'd1705;
				
			else 
				read_address = 11'd1704;
			
		end 
    
endmodule
