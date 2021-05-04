
module finalsoc (
	clk_50_clk,
	hex_digits_export,
	key_external_connection_export,
	keycode_export,
	leds_export,
	reset_50_reset_n,
	sdram_clk_clk,
	sdram_wire_addr,
	sdram_wire_ba,
	sdram_wire_cas_n,
	sdram_wire_cke,
	sdram_wire_cs_n,
	sdram_wire_dq,
	sdram_wire_dqm,
	sdram_wire_ras_n,
	sdram_wire_we_n,
	spi0_MISO,
	spi0_MOSI,
	spi0_SCLK,
	spi0_SS_n,
	usb_gpx_export,
	usb_irq_export,
	usb_rst_export,
	p1_pos_export,
	p2_pos_export,
	p1_vel_export,
	p2_vel_export,
	b1_pos_export,
	b1_vel_export,
	aim_export);	

	input		clk_50_clk;
	output	[15:0]	hex_digits_export;
	input	[1:0]	key_external_connection_export;
	output	[15:0]	keycode_export;
	output	[13:0]	leds_export;
	input		reset_50_reset_n;
	output		sdram_clk_clk;
	output	[12:0]	sdram_wire_addr;
	output	[1:0]	sdram_wire_ba;
	output		sdram_wire_cas_n;
	output		sdram_wire_cke;
	output		sdram_wire_cs_n;
	inout	[15:0]	sdram_wire_dq;
	output	[1:0]	sdram_wire_dqm;
	output		sdram_wire_ras_n;
	output		sdram_wire_we_n;
	input		spi0_MISO;
	output		spi0_MOSI;
	output		spi0_SCLK;
	output		spi0_SS_n;
	input		usb_gpx_export;
	input		usb_irq_export;
	output		usb_rst_export;
	input	[31:0]	p1_pos_export;
	input	[31:0]	p2_pos_export;
	input	[31:0]	p1_vel_export;
	input	[31:0]	p2_vel_export;
	input	[31:0]	b1_pos_export;
	input	[31:0]	b1_vel_export;
	input	[31:0]	aim_export;
endmodule
