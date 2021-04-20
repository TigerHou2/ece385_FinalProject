/*
 * ECE385-HelperTools/PNG-To-Txt
 * Author: Rishi Thakkar
 *
 */

module spriteRAM
(
		input [7:0] data_in,
		input [10:0] write_address, read_address,
		input we, clk,

		output logic [7:0] data_out
);

// mem has width of 5 bits (32 colors) and a total of 1707 addresses
logic [7:0] mem [0:1706];

initial
begin
	 $readmemh("sprites/on_chip_memory/sprite_bytes/cannonball.txt", mem, 0, 203);
	 $readmemh("sprites/on_chip_memory/sprite_bytes/demomanR_red.txt", mem, 204, 578);
	 $readmemh("sprites/on_chip_memory/sprite_bytes/demomanL_red.txt", mem, 579, 953);
	 $readmemh("sprites/on_chip_memory/sprite_bytes/demomanR_blu.txt", mem, 954, 1328);
	 $readmemh("sprites/on_chip_memory/sprite_bytes/demomanL_blu.txt", mem, 1329, 1703);
	 $readmemh("sprites/on_chip_memory/sprite_bytes/sky_uniform.txt", mem, 1704, 1704);
	 $readmemh("sprites/on_chip_memory/sprite_bytes/ground_uniform.txt", mem, 1705, 1705);
	 $readmemh("sprites/on_chip_memory/sprite_bytes/blanking.txt", mem, 1706, 1706);
end


always_ff @ (posedge clk) begin
	if (we)
		mem[write_address] <= data_in;
	data_out<= mem[read_address];
end

endmodule
