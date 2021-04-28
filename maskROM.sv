/*
 * ECE385-HelperTools/PNG-To-Txt
 * Author: Rishi Thakkar
 *
 */

module maskROM
(
		input [9:0] addr1, addr2,
		input 		clk,
		output logic out1, out2
);

// mem has width of 1 bit (transparency true/false) and a total of 954 addresses
logic mem [0:953];

initial
begin
	 $readmemb("sprites/on_chip_memory/sprite_bytes/cannonball_mask.txt", mem, 0, 203);
	 $readmemb("sprites/on_chip_memory/sprite_bytes/demomanR_mask.txt", mem, 204, 578);
	 $readmemb("sprites/on_chip_memory/sprite_bytes/demomanL_mask.txt", mem, 579, 953);
end


always_ff @ (posedge clk) begin
	out1 <= mem[addr1];
	out2 <= mem[addr2];
end

endmodule
