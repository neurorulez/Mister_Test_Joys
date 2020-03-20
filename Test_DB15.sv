//============================================================================
//  Ultratank port to MiSTer
//  Copyright (c) 2020 Aitor Pelaez - NeuroRulez
//  EMU level .sv based on Alan Steremberg - alanswx work
//
//   
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        VGA_CLK,

	//Multiple resolutions are supported using different VGA_CE rates.
	//Must be based on CLK_VIDEO
	output        VGA_CE,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,

	//Base video clock. Usually equals to CLK_SYS.
	output        HDMI_CLK,

	//Multiple resolutions are supported using different HDMI_CE rates.
	//Must be based on CLK_VIDEO
	output        HDMI_CE,

	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_DE,   // = ~(VBlank | HBlank)
	output  [1:0] HDMI_SL,   // scanlines fx

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] HDMI_ARX,
	output  [7:0] HDMI_ARY,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,    // 1 - signed audio samples, 0 - unsigned

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	output        USER_OSD,	
	output  [1:0] USER_MODE,
	input   [7:0] USER_IN,
	output  [7:0] USER_OUT,
	output        OSD_STATUS
);

assign VGA_F1    = 0;

wire         CLK_JOY = CLK_50M;         //Assign clock between 40-50Mhz
wire   [2:0] JOY_FLAG  = status[31:29]; //Assign 3 bits of status (31:29) o (63:61)
wire         JOY_CLK, JOY_LOAD, JOY_SPLIT, JOY_MDSEL;
wire   [5:0] JOY_MDIN  = JOY_FLAG[2] ? {USER_IN[6],USER_IN[3],USER_IN[5],USER_IN[7],USER_IN[1],USER_IN[2]} : '1;
wire         JOY_DATA  = JOY_FLAG[1] ? USER_IN[5] : '1;
assign       USER_OUT  = JOY_FLAG[2] ? {3'b111,JOY_SPLIT,3'b111,JOY_MDSEL} : JOY_FLAG[1] ? {6'b111111,JOY_CLK,JOY_LOAD} : '1;
assign       USER_MODE = JOY_FLAG[2:1] ;
assign       USER_OSD  = joydb_1[10] & joydb_1[6];

assign LED_USER  = ioctl_download;
assign LED_DISK  = 2'b00;
assign LED_POWER = 2'b00;

assign HDMI_ARX = status[1] ? 8'd16 : 8'd4;
assign HDMI_ARY = status[1] ? 8'd9  : 8'd3;


`include "build_id.v"
localparam CONF_STR = {
	"A.TEST_DB;;",
	"O1,Aspect Ratio,Original,Wide;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",  
	"OUV,UserIO Joystick,Off,DB15,DB9;",
	"OT,UserIO Players,1 Player,2 Players;",
	"-;",
	"R0,Reset;",
	"V,v",`BUILD_DATE
};



wire [31:0] status;
wire  [1:0] buttons;
wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire [7:0] ioctl_data;

wire        forced_scandoubler;
wire [21:0] gamma_bus;
wire [10:0] ps2_key;

wire [15:0] joy1_USB, joy2_USB;

wire [31:0] joy1 = joydb_1ena ? joydb_1 : joy1_USB;
wire [31:0] joy2 = joydb_2ena ? joydb_2 : joydb_1ena ? joy1_USB : joy2_USB;

wire [15:0] joydb_1 = JOY_FLAG[2] ? {JOYDB9MD_1[11],JOYDB9MD_1[10] | (JOYDB9MD_1[11] & JOYDB9MD_1[5]),JOYDB9MD_1[9:0]} : JOY_FLAG[1] ? JOYDB15_1 : '0;
wire [15:0] joydb_2 = JOY_FLAG[2] ? {JOYDB9MD_2[11],JOYDB9MD_2[10] | (JOYDB9MD_2[11] & JOYDB9MD_2[5]),JOYDB9MD_2[9:0]} : JOY_FLAG[1] ? JOYDB15_2 : '0;
wire        joydb_1ena = |JOY_FLAG[2:1]               & ~OSD_STATUS;
wire        joydb_2ena = |JOY_FLAG[2:1] & JOY_FLAG[0] & ~OSD_STATUS;

//----BA 9876543210
//----LS FEDCBAUDLR
reg [15:0] JOYDB9MD_1,JOYDB9MD_2;
joy_db9md joy_db9md
(
  .clk       ( CLK_JOY    ), //40-50MHz
  .joy_split ( JOY_SPLIT  ),
  .joy_mdsel ( JOY_MDSEL  ),
  .joy_in    ( JOY_MDIN   ),
  .joystick1 ( JOYDB9MD_1 ),
  .joystick2 ( JOYDB9MD_2 )	  
);

reg [15:0] JOYDB15_1,JOYDB15_2;
joy_db15 joy_db15
(
  .clk       ( CLK_JOY   ), //48MHz
  .JOY_CLK   ( JOY_CLK   ),
  .JOY_DATA  ( JOY_DATA  ),
  .JOY_LOAD  ( JOY_LOAD  ),
  .joystick1 ( JOYDB15_1 ),
  .joystick2 ( JOYDB15_2 )	  
);


hps_io #(.STRLEN(($size(CONF_STR)>>3) )) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),
	
	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),


	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_data),
	
	.joy_raw(joydb_1[5:0]),
	.joystick_0(joy1_USB),
	.joystick_1(joy2_USB),
	.ps2_key(ps2_key)
);



wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(code)
			'hX75: btn_up          <= pressed; // up
			'hX72: btn_down        <= pressed; // down
			'hX6B: btn_left        <= pressed; // left
			'hX74: btn_right       <= pressed; // right
			'h014: btn_fire        <= pressed; // ctrl			

			'h005: btn_one_player  <= pressed; // F1
			'h006: btn_two_players <= pressed; // F2
			'h004: btn_coin        <= pressed; // F3
			
			// JPAC/IPAC/MAME Style Codes
			'h016: btn_start_1     <= pressed; // 1
			'h01E: btn_start_2     <= pressed; // 2
			'h02E: btn_coin_1      <= pressed; // 5
			'h036: btn_coin_2      <= pressed; // 6

			'h02D: btn_up_2        <= pressed; // R
			'h02B: btn_down_2      <= pressed; // F
			'h023: btn_left_2      <= pressed; // D
			'h034: btn_right_2     <= pressed; // G
			'h01C: btn_fire_2      <= pressed; // A
		endcase
	end
end

reg btn_up    = 0;
reg btn_down  = 0;
reg btn_right = 0;
reg btn_left  = 0;
reg btn_fire  = 0;

reg btn_one_player  = 0;
reg btn_two_players = 0;

reg btn_start_1=0;
reg btn_start_2=0;
reg btn_coin  = 0;
reg btn_coin_1=0;
reg btn_coin_2=0;
reg btn_up_2=0;
reg btn_down_2=0;
reg btn_left_2=0;
reg btn_right_2=0;
reg btn_fire_2=0;

wire m_fire     = btn_fire    | joy1[4];
wire m_fire_2   = btn_fire_2  | joy2[4];
wire m_start    = btn_start_1 | joy1[5] | joy2[5];
wire m_start_2  = btn_start_2 | joy1[6] | joy2[6];
wire m_coin     = btn_coin    | joy1[7] | joy2[7] | btn_coin_1 | btn_coin_2;

wire m_up      = btn_up      | joy1[3];
wire m_down    = btn_down    | joy1[2];
wire m_left    = btn_left    | joy1[1];
wire m_right   = btn_right   | joy1[0];
wire m_up_2    = btn_up_2    | joy2[3];
wire m_down_2  = btn_down_2  | joy2[2];
wire m_left_2  = btn_left_2  | joy2[1];
wire m_right_2 = btn_right_2 | joy2[0];


wire compositesync;
wire [5:0] video_r,video_g,video_b;

tld_test_placa_mister tld_test_placa_mister(
	.clk7(clk_7),
	//.Reset_n(~(RESET | status[0]  | buttons[1] | ioctl_download)),
	.BTN_USER(~btn_one_player),

	.r_to_vga(r),
	.g_to_vga(g),
	.b_to_vga(b),

	.hsync_to_vga(hs),
	.vsync_to_vga(vs),
	.hblank_to_vga(hblank),
	.vblank_to_vga(vblank),
	.csync_to_vga(compositesync),
	
	.joy1(joy1),
	.joy2(joy2),
	
	.CLK_VIDEO(CLK_VIDEO_2)
	);
			
wire [6:0] audio1;
wire [6:0] audio2;
wire [1:0] video;
wire [3:0] videor;
///////////////////////////////////////////////////
wire clk_14,clk_7,CLK_VIDEO_2;
wire clk_sys,locked;

assign AUDIO_L={audio1,1'b0,8'b00000000};
assign AUDIO_R={audio2,1'b0,8'b00000000};
assign AUDIO_S = 0;

wire hblank, vblank;
wire hs, vs;
wire [5:0] r,g,b;

reg ce_pix;
always @(posedge clk_14) begin
        reg old_clk;

        old_clk <= CLK_VIDEO_2;
        ce_pix <= old_clk & ~CLK_VIDEO_2;
end

arcade_video #(320,9) arcade_video
(
        .*,

        .clk_video(clk_14),

        .RGB_in({r,g,b}),
        .HBlank(hblank),
        .VBlank(vblank),
        .HSync(hs),
        .VSync(vs),

        .fx(status[5:3]),
		  .rotate_ccw(0),
	     .no_rotate(1)		  
);

pll pll (
	.refclk ( CLK_50M   ),
	.rst(0),
	.locked 		( locked    ),        // PLL is running stable
	.outclk_0	( clk_14	),        // 24 MHz
	.outclk_1	( clk_7  	)        // 7 MHz
	 );

assign clk_sys=clk_14;

endmodule
