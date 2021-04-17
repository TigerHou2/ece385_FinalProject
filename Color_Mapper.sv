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


module  color_mapper (	input				[9:0]		PX, PY, PS,
								input				[9:0]		DrawX, DrawY,
								input				[9:0]		BX, BY, BS, 
								input				[511:0]	terrain_data,
								input							blank, exploded,
								output logic	[7:0]		Red, Green, Blue );
    
		logic player_on, bomb_on, terrain_on;
	 
 /* Old Ball: Generated square box by checking if the current pixel is within a square of length
    2*PS, centered at (PX, PY).  Note that this requires unsigned comparisons.
	 
    if ((DrawX >= PX - PS) &&
       (DrawX <= PX + PS) &&
       (DrawY >= PY - PS) &&
       (DrawY <= PY + PS))

     New Ball: Generates (pixelated) circle by using the standard circle formula.  Note that while 
     this single line is quite powerful descriptively, it causes the synthesis tool to use up three
     of the 12 available multipliers on the chip!  Since the multiplicants are required to be signed,
	  we have to first cast them from logic to int (signed by default) before they are multiplied). */
	  
		int Dist_PX, Dist_PY, PSize;
		assign Dist_PX = DrawX - PX;
		assign Dist_PY = DrawY - PY;
		assign PSize = PS;
	  
		always_comb
		begin:player_on_proc
			if ( ( Dist_PX*Dist_PX + Dist_PY*Dist_PY) <= (PSize * PSize) ) 
				player_on = 1'b1;
			else 
				player_on = 1'b0;
		end 
		
		
		int Dist_BX, Dist_BY, BSize;
		assign Dist_BX = DrawX - BX;
		assign Dist_BY = DrawY - BY;
		assign BSize = BS;
		
		always_comb
		begin:bomb_on_proc
			if ( exploded == 1'b1 )
				bomb_on = 1'b0;
			else if ( ( Dist_BX*Dist_BX + Dist_BY*Dist_BY) <= (BSize * BSize) ) 
				bomb_on = 1'b1;
			else 
				bomb_on = 1'b0;
		end
  
		always_comb
		begin:Terrain_on_proc
			if ( terrain_data[DrawY] == 1'b1 )
				terrain_on = 1'b1;
			else
				terrain_on = 1'b0;
		end
       
		always_comb
		begin:RGB_Display
			
			if (blank == 1'b0)
				begin
					Red = 8'h00;
					Green = 8'h00;
					Blue = 8'h00;
				end
			else if (bomb_on == 1'b1) 
				begin 
					Red = 8'h00;
					Green = 8'h00;
					Blue = 8'h00;
				end
			else if (player_on == 1'b1) 
				begin 
					Red = 8'hcc;
					Green = 8'h33;
					Blue = 8'h00;
				end
			else if (terrain_on == 1'b1)
				begin 
					Red = 8'h00;
					Green = 8'h99;
					Blue = 8'h33;
				end
			else 
				begin 
					Red = 8'h80; 
					Green = 8'ha6;
					Blue = 8'hff;
				end
			
		end 
    
endmodule
