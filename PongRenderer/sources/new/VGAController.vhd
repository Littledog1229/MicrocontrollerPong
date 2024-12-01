----------------------------------------------------------------------------------
-- Name: Zachary Q. Murdock
-- Description:
--    VGA signal generator (1280 x 1024, 60Hz)
--
-- Create Date: 11/12/2024 11:35:13 AM
-- Module Name: VGAController - Behavioral
-- Target Devices: Artix-7 Basys 3
----------------------------------------------------------------------------------

library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.TYPES.ALL;

-- TODO: Update all of this information

-- 640 by 480 vga display controller
--   . MY MONITOR DOESNT SUPPORT THAT????
--   . Guess im using 1280 x 1024 at 60 Hz
-- Primary research was provided from here:
--     . https://digilent.com/reference/learn/programmable-logic/tutorials/vga-display-congroller/start
--
-- Research:
--  . In order to drive a 640x480 monitor using VGA you need:
--     : a 25(.125) MHz pixel clock, I will be using 25 MHz (allowed due to tolerances)
--  . Horizontal timing (in pixels) is 800 (which includes H-Sync, Front Porch, and Back Porch)
--  . Vertical   timing (in lines)  is 524 (which includes V-Sync, Front Porch, and Back Porch)
--  . When not purely in the visible range, RGB must be grounded (set to 0)
--     : The horizontal range is 144 <= x < 784 pixels
--     : The vertical   range is 35  <= y < 515 lines
--  . The H-sync and V-sync signals must be set for a specific amount of time
--     : H-sync must be set for the first 96 pixels
--     : V-sync must be set for the first 2  lines
--     : If these are outside of the values, then it must be unset
--
-- Math:
-- . The horizontal pixel counter must be 10 bits in size [viewable screen area x]
-- . The horizontal       counter must be 10 bits in size [total horizontal pixels]
-- . The vertical   pixel counter must be  9 bits in size [viewable screen area y]
-- . The vertical         counter must be 10 bits in size [total vertical lines]


entity VGAController is
    Port (
        -- System Clock
        in_sys_clk : in STD_LOGIC;

        -- Global Registers
        in_global_registers : in GLOBAL_REGISTERS;

        -- VGA Color Outputs
        out_vga_red   : out STD_LOGIC_VECTOR(3 downto 0);
        out_vga_green : out STD_LOGIC_VECTOR(3 downto 0);
        out_vga_blue  : out STD_LOGIC_VECTOR(3 downto 0);

        -- VGA Sync Outputs
        out_vga_h_sync : out STD_LOGIC;
        out_vga_v_sync : out STD_LOGIC
    );
end VGAController;

architecture Behavioral of VGAController is
    component VGAClockDivider
    port (
        in_sys_clk : in std_logic;

        out_pixel_clk : out STD_LOGIC
    );
    end component;

    component VGAHorizontalCounter is
        port(
            in_pixel_clk : in STD_LOGIC;

            out_h_sync   : out STD_LOGIC;
            out_line_clk : out STD_LOGIC;

            out_display_active   : out STD_LOGIC;
            out_display_position : out integer range 1279 downto 0
        );
    end component VGAHorizontalCounter;

    component VGAVerticalCounter is
        port(
            in_line_clk : in STD_LOGIC;

            out_v_sync : out STD_LOGIC;

            out_display_active   : out STD_LOGIC;
            out_display_position : out integer range 1023 downto 0
        );
    end component VGAVerticalCounter;

    component VGAPixelProcessor is
        port(
            in_pixel_clk : in STD_LOGIC;

            in_global_registers : GLOBAL_REGISTERS;

            in_pixel_x : in integer range 1279 downto 0;
            in_pixel_y : in integer range 1023 downto 0;

            out_pixel_r : out STD_LOGIC_VECTOR(3 downto 0);
            out_pixel_g : out STD_LOGIC_VECTOR(3 downto 0);
            out_pixel_b : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component VGAPixelProcessor;

    -- Clock signalss
    signal pixel_clk : STD_LOGIC;
    signal line_clk  : STD_LOGIC;

    -- Display Active signals
    signal horizontal_display_active : STD_LOGIC; -- Is the current pixel in the display area?
    signal vertical_display_active   : STD_LOGIC; -- Is the current line  in the display area?

    -- View Area Pixel Position signals
    signal pixel_x : integer range 1279 downto 0;
    signal pixel_y : integer range 1023 downto 0;

    -- Pixel Color signals
    signal r : STD_LOGIC_VECTOR(3 downto 0);
    signal g : STD_LOGIC_VECTOR(3 downto 0);
    signal b : STD_LOGIC_VECTOR(3 downto 0);

    signal active      : STD_LOGIC;
    signal active_mask : STD_LOGIC_VECTOR(3 downto 0);
begin
    -- Pixel Clock Divider
    clock_divider : VGAClockDivider
    port map ( 
        in_sys_clk => in_sys_clk,
        
        out_pixel_clk => pixel_clk
    );

    -- Horizontal Counter
    horizontal_counter_inst : component VGAHorizontalCounter
    port map(
        in_pixel_clk => pixel_clk,

        out_h_sync   => out_vga_h_sync,
        out_line_clk => line_clk,

        out_display_active   => horizontal_display_active,
        out_display_position => pixel_x
    );

    -- Vertical Counter
    vertical_counter_inst : component VGAVerticalCounter
    port map(
        in_line_clk => line_clk,

        out_v_sync => out_vga_v_sync,

        out_display_active   => vertical_display_active,
        out_display_position => pixel_y
    );

    -- In-display Pixel Mask
    active      <= horizontal_display_active and vertical_display_active;
    active_mask <= active & active & active & active;

    -- Pixel Processing / Selector
    pixel_processor_inst : component VGAPixelProcessor
    port map(
        in_pixel_clk => pixel_clk,

        in_global_registers => in_global_registers,

        in_pixel_x => pixel_x,
        in_pixel_y => pixel_y,

        out_pixel_r => r,
        out_pixel_g => g,
        out_pixel_b => b
    );

    -- Pixel Output
    out_vga_red   <= r and active_mask;
    out_vga_green <= g and active_mask;
    out_vga_blue  <= b and active_mask;
end Behavioral;
