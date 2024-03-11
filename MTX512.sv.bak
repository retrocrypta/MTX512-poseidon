//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================


module MTX512
(       
        output        LED,                                              
        output        VGA_HS,
        output        VGA_VS,
        output        AUDIO_L,
        output        AUDIO_R, 
		  output [15:0]  DAC_L, 
		  output [15:0]  DAC_R, 
        input         TAPE_IN,
        input         UART_RX,
        output        UART_TX,
        input         SPI_SCK,
        output        SPI_DO,
        input         SPI_DI,
        input         SPI_SS2,
        input         SPI_SS3,
        input         CONF_DATA0,
        input         CLOCK_27,
        output  [5:0] VGA_R,
        output  [5:0] VGA_G,
        output  [5:0] VGA_B,

		  output [12:0] SDRAM_A,
		  inout  [15:0] SDRAM_DQ,
		  output        SDRAM_DQML,
        output        SDRAM_DQMH,
        output        SDRAM_nWE,
        output        SDRAM_nCAS,
        output        SDRAM_nRAS,
        output        SDRAM_nCS,
        output  [1:0] SDRAM_BA,
        output        SDRAM_CLK,
        output        SDRAM_CKE
);


 


`include "build_id.v" 
localparam CONF_STR = {
        "MTX512;;",
		  "O4,Video Out,80Col,VDP;",
        "S0,IMGVHD,Load VHD;",
		  "F0,ROM,Load ROM;",
        "O2,PAL,Normal,Marat;",
        "O3,Hz,60,50;",
        "O57,Cpu Mhz,24,12,8,6,4.8,4,3.42,3;",
        "T0,Reset;",
        "V,v",`BUILD_DATE 
};

/////////////////  CLOCKS  ////////////////////////

wire clk_25Mhz,clk_ram,clk_ram_ph,locked,clk_50Mhz,clk_cpu;

pll pll
(
	.inclk0(CLOCK_27),
	.c0(clk_50Mhz),
	.c1(clk_25Mhz),
	.c2(clk_ram),
	.c3(clk_ram_ph),
	.locked(locked)
);

wire clk_sys=clk_25Mhz;


///////////////// SDRAM ///////////////////////////

wire [22:0] sramAddress;
wire [7:0]  sramData;
wire [7:0]  sramDataIn;
wire [7:0]  sramDataOut;


wire n_sRamWE;
wire n_sRamOE;
wire n_sRamCS;



wire ram_ready;
sram ram
(
	.*,
	.init(~locked),
	.clk(clk_ram),	
	.addr(ioctl_download ? ioctl_addr: sramAddress),
	.dout(sramDataOut),
	.din(ioctl_download ? ioctl_data : sramDataIn),
	.wtbt(2'b00),
	.we(ioctl_download  ? ioctl_wr   : ~n_sRamWE),
	.rd(ioctl_download ? 1'b0        : ~n_sRamOE),
	.ready(ram_ready)
);
assign SDRAM_CLK=clk_ram_ph;
/////////////////  HPS  ///////////////////////////


wire forced_scandoubler;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] status;

wire ps2_kbd_clk,ps2_kbd_data;
wire ps2_mouse_clk,ps2_mouse_data;

wire [10:0] ps2_key;
wire [24:0] ps2_mouse;

wire        key_pressed;
wire [7:0]  key_code;
wire        key_strobe;
wire        key_extended;


wire        ioctl_download;
wire        ioctl_wr;
wire [22:0] ioctl_addr;
wire  [7:0] ioctl_data;
wire  [7:0] ioctl_index;

wire [31:0] joy1, joy2;
wire [15:0] joystick_analog_0,joystick_analog_1;

wire ypbpr;

wire        img_readonly;
wire  [1:0] img_mounted;
wire [63:0] img_size;

wire [31:0] sd_lba;
wire        sd_rd;
wire        sd_wr;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din;
wire        sd_buff_wr;
wire        sd_ack_conf;
wire        sd_busy;
wire        sd_sdhc;
wire        sd_conf;

 
mist_io #(.STRLEN($size(CONF_STR)>>3),.PS2DIV(100)) mist_io
(
   .*,
	.SPI_SCK   (SPI_SCK),
   .CONF_DATA0(CONF_DATA0),
   .SPI_SS2   (SPI_SS2),
   .SPI_DO    (SPI_DO),
   .SPI_DI    (SPI_DI),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.scandoubler_disable(forced_scandoubler),
   .ypbpr     (ypbpr),
	
	.ioctl_ce(clk_cpu && ram_ready),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_data),
		
	 .sd_lba(sd_lba),
	 .sd_rd(sd_rd),
	 .sd_wr(sd_wr),
	 .sd_ack(sd_ack),
	 .sd_ack_conf(sd_ack_conf),
	 .sd_buff_addr(sd_buff_addr),
	 .sd_buff_dout(sd_buff_dout),
	 .sd_buff_din(sd_buff_din),
	 .sd_buff_wr(sd_buff_wr),
	 .img_mounted(img_mounted),
	 .img_size(img_size),

//	 .ps2_kbd_clk(),
//	 .ps2_kbd_data(),
    .ps2_key(ps2_key),
	 
	 .ps2_mouse_clk(),
	 .ps2_mouse_data(),
	 

	.joystick_0(joy1), // HPS joy [4:0] {Fire, Up, Down, Left, Right}
	.joystick_1(joy2)

);

/////////////////  RESET  /////////////////////////

wire reset = (!locked | status[0] | buttons[1] | ioctl_download );

//////////////// LED ///////////////////////////

////////////////  main  ////////////////////////


dac_dsm2v #(8) dac_l (
   .clock_i      (clk_sys),
   .reset_i      (0      ),
   .dac_i        (AudioOut),
   .dac_o        (AUDIO_L)
);

assign DAC_L=AudioOut;
assign DAC_R=AudioOut;
assign AUDIO_R=AUDIO_L;

wire HBlank;
wire HSync;
wire VBlank;
wire VSync;



wire [2:0] CpuSpeed = status[7:5] ;



rememotech rememotech
    (
    .CLOCK_50            (clk_50Mhz),//(clk),//(status[9]),//(clk_50MhzM),
    // SD card
    .SD_CLK              (sdclk),
    .SD_CMD              (sdmosi),
    .SD_DAT              (vsdmiso),
    .SD_DAT3             (sdss),
    // SDRAM
	 .SRAM_CE_N           (n_sRamCS),
    .SRAM_ADDR           (sramAddress),
    .SRAM_LB_N           (),
    .SRAM_UB_N           (),
    .SRAM_OE_N           (n_sRamOE),
    .SRAM_WE_N           (n_sRamWE),
    .SRAM_D              (sramDataIn),
	 .SRAM_Q              (sramDataOut),
	 .SRAM_RDY            (ram_ready),
    .LED                 (LED),
    // switches
    .SW                  ({CpuSpeed,status[4],status[2],~status[3],2'b0,2'b0}), //Forzamos monitor(6), Pal normal-60Hz(5:4), y sin externalrom(1:0)
    // key switches
    .KEY                 ({reset,3'b111}),
    // VGA output
    .VGA_R               (r),
    .VGA_G               (g),
    .VGA_B               (b),
    .VGA_HS              (HSync),
    .VGA_VS              (VSync),
 	 .VGA_HB              (HBlank),
	 .VGA_VB              (VBlank),

	 .clk_video_i         (clk_25Mhz),
    .clk_cpu_o           (clk_cpu),
	 
	 .PS2_CLK             (ps2_kbd_clk),
	 .PS2_DAT             (ps2_kbd_data),
	 
	 
	 .EKey                (key_extended),
    .key_ready           (key_strobe),
    .key_stroke          (key_pressed),
    .key_code            (key_code),
    .sound_out           (AudioOut)
);



wire [7:0] AudioOut;

//wire key_strobe = old_keystb ^ ps2_key[10];
//reg old_keystb = 0;
//always @(posedge clk_sys) old_keystb <= ps2_key[10];



/////////////////  VIDEO  /////////////////////////

wire [3:0] r,g,b;

	
video_mixer #(.LINE_LENGTH(380)) video_mixer
(
   .*,
   .ce_pix(clk_25Mhz),
   .ce_pix_actual(clk_25Mhz),
   .scandoubler_disable(1),
   .hq2x(0),
   .mono(0),
   .scanlines(0),
   .ypbpr_full(0),
   .line_start(0),
	.VGA_HS(),
	.VGA_VS(),
	.R({r,r[3:2]}),
	.G({g,g[3:2]}),
   .B({b,b[3:2]})
);

assign VGA_VS=~VSync;
assign VGA_HS=~HSync;

/////////////////  Tape In   /////////////////////////

wire tape_in;
assign tape_in = UART_RX;
//////////////////   SD   ///////////////////

wire sdclk;
wire sdmosi;
wire sdss;

wire vsdmiso;

//assign sd_sdhc = 1'b0;



sd_card sd_card
(
        .*,
		  .clk_sys(clk_ram_ph),
		  .img_mounted(img_mounted[0]),
		  .allow_sdhc(sd_sdhc),
        .sd_sck(sdclk),
        .sd_cs(sdss),
        .sd_sdi(sdmosi),
        .sd_sdo(vsdmiso)
);
endmodule
