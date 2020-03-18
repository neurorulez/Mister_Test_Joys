`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   01:24:02 08/15/2016 
// Design Name: 
// Module Name:   tld_test_prod_v4 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module tld_test_placa_mister (
  input wire clk7,
  input wire BTN_USER,
  //---------------------------
  output wire CLK_VIDEO,
  //---------------------------
  input wire [15:0] joy1,
  input wire [15:0] joy2,
  //---------------------------
  output wire [5:0] r_to_vga,//r,
  output wire [5:0] g_to_vga,//g,
  output wire [5:0] b_to_vga,//b,
  output wire hsync_to_vga,//hsync,
  output wire vsync_to_vga,//vsync
  output wire hblank_to_vga,
  output wire vblank_to_vga,	  
  output wire csync_to_vga
  );

  
  wire clk100, clk100n, clk14;//, clk7;
  wire clocks_ready;

  assign CLK_VIDEO = clk7;

  wire mode, vga; //=vga^cambio_vga;
  reg cambio_vga = 0, BTN_USER_r = 1;
	always @(posedge clk7) begin  
	 BTN_USER_r <= BTN_USER;
	 if ( !BTN_USER_r & BTN_USER) cambio_vga <= ~cambio_vga;
	end
  
  //wire [5:0] r_to_vga, g_to_vga, b_to_vga;
  //wire hsync_to_vga, vsync_to_vga, csync_to_vga;

  wire sdtest_init, sdtest_progress, sdtest_result;
  wire flashtest_init, flashtest_progress, flashtest_result;
  wire sdramtest_init, sdramtest_progress, sdramtest_result;
  wire hidetextwindow;

  wire [2:0] mousebutton;  // M R L
  wire mousetest_init;

  wire [15:0] flash_vendor_id;

/* 
  relojes los_relojes (
   .inclk0(clk50mhz),
   .c0(clk100),
   .c1(clk100n),
   .c2(clk14),
   .c3(clk7),
   .locked(clocks_ready)
   );
*/	

  updater mensajes (
    .clk(clk7),
    .mode(mode),
    .vga(vga),
	 
	 .dna(),
    .joystick1(joy1),
    .joystick2(joy2),

    .sdtest_progress(sdtest_progress),
    .sdtest_result(sdtest_result),
    .flashtest_progress(flashtest_progress),
    .flashtest_result(flashtest_result),
    .flash_vendor_id(flash_vendor_id),
    .sdramtest_progress(sdramtest_progress),
    .sdramtest_result(sdramtest_result),
    .mousebutton(mousebutton),
    .hidetextwindow(hidetextwindow),
    
    .r(r_to_vga),
    .g(g_to_vga),
    .b(b_to_vga),
    .hsync(hsync_to_vga),
    .vsync(vsync_to_vga),
	 .hblank(hblank_to_vga),
	 .vblank(vblank_to_vga),
    .csync(csync_to_vga)
    );

/*
  vga_scandoubler #(.CLKVIDEO(7000)) modo_vga (
    .clkvideo(clk7),
    .clkvga(clk14),
    .enable_scandoubling(vga),
    .disable_scaneffect(1'b1),
    .ri(r_to_vga),
    .gi(g_to_vga),
    .bi(b_to_vga),
    .hsync_ext_n(hsync_to_vga),
    .vsync_ext_n(vsync_to_vga),
    .csync_ext_n(csync_to_vga),
    .ro(r),
    .go(g),
    .bo(b),
    .hsync(hsync),
    .vsync(vsync)
  );
  
*/  
endmodule
