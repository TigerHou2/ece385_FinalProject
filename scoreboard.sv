module scoreboard	(	input		[9:0]	DrawX, DrawY,
							input		[9:0]	HP1, HPP1, HP2, HPP2,
							output			drawScore,
							output  [17:0]	addrScore	);
							
	// health bar sizing
	parameter [9:0] U = 25;
	parameter [9:0] D = 34;
	parameter [9:0] P1L = 30;
	parameter [9:0] P1R = 229;
	parameter [9:0] P2L = 410;
	parameter [9:0] P2R = 609;
	parameter [9:0] border = 4;
	
	// health values. doubled to display length
	logic [9:0] hp1, hpp1, hp2, hpp2;
	assign hp1	= { HP1[8:0],1'b0};
	assign hpp1	= {HPP1[8:0],1'b0};
	assign hp2	= { HP2[8:0],1'b0};
	assign hpp2	= {HPP2[8:0],1'b0};
	
	always_comb
	begin
	
		// draw health bar frame
		
		if 		( ( ( ( DrawX >= P1L-border && DrawX < P1L ) || ( DrawX >= P1R && DrawX < P1R+border ) ) && 
						 ( ( DrawY >=  U -border && DrawY <  D +border ) ) ) || 
					  ( ( ( DrawY >=  U -border && DrawY <  U  ) || ( DrawY >=  D  && DrawY <  D +border ) ) && 
						 ( ( DrawX >= P1L-border && DrawX < P1R+border ) ) ) ) begin
			drawScore = 1'b1;
			addrScore = 18'd1706;
		end
		else if	( ( ( ( DrawX >= P2L-border && DrawX < P2L ) || ( DrawX >= P2R && DrawX < P2R+border ) ) && 
						 ( ( DrawY >=  U -border && DrawY <  D +border ) ) ) || 
					  ( ( ( DrawY >=  U -border && DrawY <  U  ) || ( DrawY >=  D  && DrawY <  D +border ) ) && 
						 ( ( DrawX >= P2L-border && DrawX < P2R+border ) ) ) ) begin
			drawScore = 1'b1;
			addrScore = 18'd1706;
		end
		
		// draw base health bar
		
		else if	( ( DrawX >= P1L && DrawX < P1L+hp1 ) && ( DrawY >= U && DrawY < D ) ) begin
			drawScore = 1'b1;
			addrScore = 18'd156331;
		end
		else if	( ( DrawX >= P2L && DrawX < P2L+hp2 ) && ( DrawY >= U && DrawY < D ) ) begin
			drawScore = 1'b1;
			addrScore = 18'd156331;
		end
		
		// draw padded health bar
		
		else if	( ( DrawX >= P1L && DrawX < P1L+hpp1 ) && ( DrawY >= U && DrawY < D ) ) begin
			drawScore = 1'b1;
			addrScore = 18'd156332;
		end
		else if	( ( DrawX >= P2L && DrawX < P2L+hpp2 ) && ( DrawY >= U && DrawY < D ) ) begin
			drawScore = 1'b1;
			addrScore = 18'd156332;
		end
		
		// no draw
		
		else begin
			drawScore = 1'b0;
			addrScore = 18'd1706;
		end
	end
		
		
endmodule
