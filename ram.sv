/*
 * ECE385-HelperTools/PNG-To-Txt
 * Author: Rishi Thakkar
 *
 */

module spriteRAM
(
		input [4:0] data_in,
		input [17:0] write_address, read_address,
		input we, clk,

		output logic [4:0] data_out
);

// mem has width of 5 bits (32 colors) and a total of 232107 addresses
logic [4:0] mem [0:155306];

initial
begin
	 $readmemb("sprites/on_chip_memory/sprite_bytes/cannonball.txt", mem, 0, 203);
	 $readmemb("sprites/on_chip_memory/sprite_bytes/demomanR_red.txt", mem, 204, 578);
	 $readmemb("sprites/on_chip_memory/sprite_bytes/demomanL_red.txt", mem, 579, 953);
	 $readmemb("sprites/on_chip_memory/sprite_bytes/demomanR_blu.txt", mem, 954, 1328);
	 $readmemb("sprites/on_chip_memory/sprite_bytes/demomanL_blu.txt", mem, 1329, 1703);
	 $readmemb("sprites/on_chip_memory/sprite_bytes/sky_uniform.txt", mem, 1704, 1704);
	 $readmemb("sprites/on_chip_memory/sprite_bytes/ground_uniform.txt", mem, 1705, 1705);
	 $readmemb("sprites/on_chip_memory/sprite_bytes/blanking.txt", mem, 1706, 1706);
	 $readmemb("sprites/on_chip_memory/sprite_bytes/map1.txt", mem, 1707, 78506);
	 $readmemb("sprites/on_chip_memory/sprite_bytes/map2.txt", mem, 78507, 155306);
//	 $readmemb("sprites/on_chip_memory/sprite_bytes/map3.txt", mem, 155307, 232106);
end


always_ff @ (posedge clk) begin
	if (we)
		mem[write_address] <= data_in;
	data_out<= mem[read_address];
end

endmodule
