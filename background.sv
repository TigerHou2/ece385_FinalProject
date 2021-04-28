module background	(	input					mapSelect,
							input		[9:0]		DrawX, DrawY,
							output				drawBG,
							output	[17:0]	addrBG	);
							
		logic [17:0] width, height, spriteOffset;
		
		assign width	= 320;
		assign height	= 240;
		
		always_comb
		begin
			unique case (mapSelect)
				1'b0:	spriteOffset = 18'd1707;
				1'b1:	spriteOffset = 18'd78507;
			endcase
		end
		
		always_comb
		begin
			if ( 	DrawX[9:1] >= 8'd0 && DrawX[9:1] <= width &&
					DrawY[9:1] >= 8'd0 && DrawY[9:1] <= height	)
				drawBG = 1'b1;
			else 
				drawBG = 1'b0;
		end
		
		assign addrBG = width*({9'd0,DrawY[9:1]})+({9'd0,DrawX[9:1]})+spriteOffset;
							
							
endmodule
