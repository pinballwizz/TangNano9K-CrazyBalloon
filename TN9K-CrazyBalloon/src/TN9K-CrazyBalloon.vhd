---------------------------------------------------------------------------------
--                       Crazy Balloon - Tang Nano 9k
--                          Code from Mike Coates
--
--                        Modified for Tang Nano 9k 
--                            by pinballwiz.org 
--                               06/12/2025
---------------------------------------------------------------------------------
-- Keyboard inputs :
--   5 : Add coin
--   2 : Start 2 players
--   1 : Start 1 player
--   RIGHT arrow : Move Right
--   LEFT arrow  : Move Left
--   UP arrow : Move Up
--   DOWN arrow  : Move Down
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;
---------------------------------------------------------------------------------
entity crazyballoon_tn9k is
port(
	Clock_27    : in std_logic;
   	I_RESET     : in std_logic;
	O_VIDEO_R	: out std_logic_vector(2 downto 0); 
	O_VIDEO_G	: out std_logic_vector(2 downto 0);
	O_VIDEO_B	: out std_logic_vector(1 downto 0);
	O_HSYNC		: out std_logic;
	O_VSYNC		: out std_logic;
	O_AUDIO_L 	: out std_logic;
	O_AUDIO_R 	: out std_logic;
   	ps2_clk     : in std_logic;
	ps2_dat     : inout std_logic;
 	led         : out std_logic_vector(5 downto 0) 
 );
end crazyballoon_tn9k;
------------------------------------------------------------------------------
architecture struct of crazyballoon_tn9k is

 signal clock_20  : std_logic;
 signal clock_10  : std_logic;
 signal clock_5   : std_logic;
 signal clock_2p5 : std_logic;
 --
 signal video_r   : std_logic_vector(1 downto 0);
 signal video_g   : std_logic_vector(1 downto 0);
 signal video_b   : std_logic_vector(1 downto 0);
 signal video_ri   : std_logic_vector(3 downto 0);
 signal video_gi   : std_logic_vector(3 downto 0);
 signal video_bi   : std_logic_vector(3 downto 0);
 signal video_r_x2 : std_logic_vector(2 downto 0);
 signal video_g_x2 : std_logic_vector(2 downto 0);
 signal video_b_x2 : std_logic_vector(2 downto 0);
 signal hsync_x2   : std_logic;
 signal vsync_x2   : std_logic;
 signal h_sync     : std_logic;
 signal v_sync	   : std_logic;
 signal h_blank    : std_logic;
 signal v_blank	   : std_logic;
 --
 signal reset      : std_logic;
 --
 signal kbd_intr        : std_logic;
 signal kbd_scancode    : std_logic_vector(7 downto 0);
 signal joy_BBBBFRLDU   : std_logic_vector(8 downto 0);
 --
 constant CLOCK_FREQ    : integer := 27E6;
 signal counter_clk     : std_logic_vector(25 downto 0);
 signal clock_4hz       : std_logic;
 signal AD              : std_logic_vector(15 downto 0);
---------------------------------------------------------------------------
begin

    reset <= not I_RESET;
---------------------------------------------------------------------------
-- Clocks
Clock: entity work.Gowin_rPLL
    port map (
        clkout  => clock_20,
        clkoutd => clock_10,
        clkin   => Clock_27
    );
---------------------------------------------------------------------------
-- Divide
process (clock_10)
begin
 if rising_edge(clock_10) then
  clock_5  <= not clock_5;
 end if;
end process;
--
process (clock_5)
begin
 if rising_edge(clock_5) then
  clock_2p5  <= not clock_2p5;
 end if;
end process;
---------------------------------------------------------------------------
crazyballoon : entity work.CRAZYBALLOON
  port map (
 CLK        => clock_10,
 PIX_CLK    => clock_5,
 CPU_CLK    => clock_2p5,
 RESET      => reset,
 O_VIDEO_R 	=> video_r,
 O_VIDEO_G 	=> video_g,
 O_VIDEO_B 	=> video_b,
 O_HSYNC    => h_sync,
 O_VSYNC   	=> v_sync,
 O_HBLANK   => h_blank,
 O_VBLANK   => v_blank,
 O_AUDIO_L  => O_AUDIO_L,
 O_AUDIO_R  => O_AUDIO_R,
 in0        => not joy_BBBBFRLDU(3) & not joy_BBBBFRLDU(2) & not joy_BBBBFRLDU(1) & not joy_BBBBFRLDU(0) & not joy_BBBBFRLDU(3) & not joy_BBBBFRLDU(2) & not joy_BBBBFRLDU(1) & not joy_BBBBFRLDU(0),
 in1        => '0' & joy_BBBBFRLDU(7) & not joy_BBBBFRLDU(6) & not joy_BBBBFRLDU(5) & "1111",
 AD         => AD
   );
-------------------------------------------------------------------------
  video_ri <= video_r & video_r when h_blank = '0' and v_blank = '0' else "0000";
  video_gi <= video_g & video_g when h_blank = '0' and v_blank = '0' else "0000";
  video_bi <= video_b & video_b when h_blank = '0' and v_blank = '0' else "0000";
-------------------------------------------------------------------------
scandoubler_inst : entity work.scandoubler
  port map (
    clk_sys     => clock_20,
    scanlines   => '0',
    hs_in       => h_sync,
    vs_in       => v_sync,
    r_in        => video_ri,
    g_in        => video_gi,
    b_in        => video_bi, 
    hs_out      => hsync_x2,
    vs_out      => vsync_x2,
    r_out       => video_r_x2,
    g_out       => video_g_x2,
    b_out       => video_b_x2
  );
-------------------------------------------------------------------------
-- to output

	O_VIDEO_R <= video_r_x2;
	O_VIDEO_G <= video_g_x2;
	O_VIDEO_B <= video_b_x2(2 downto 1);
	O_HSYNC   <= hsync_x2;
	O_VSYNC   <= vsync_x2;
------------------------------------------------------------------------------
-- get scancode from keyboard

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_10,
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);
------------------------------------------------------------------------------
-- translate scancode to joystick

joystick : entity work.kbd_joystick
port map (
  clk               => clock_10,
  kbdint            => kbd_intr,
  kbdscancode       => std_logic_vector(kbd_scancode), 
  joy_BBBBFRLDU     => joy_BBBBFRLDU 
);
------------------------------------------------------------------------------
-- debug

process(reset, clock_27)
begin
  if reset = '1' then
    clock_4hz <= '0';
    counter_clk <= (others => '0');
  else
    if rising_edge(clock_27) then
      if counter_clk = CLOCK_FREQ/8 then
        counter_clk <= (others => '0');
        clock_4hz <= not clock_4hz;
        led(5 downto 0) <= not AD(9 downto 4);
      else
        counter_clk <= counter_clk + 1;
      end if;
    end if;
  end if;
end process;
------------------------------------------------------------------------
end struct;