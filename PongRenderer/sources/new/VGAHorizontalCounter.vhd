----------------------------------------------------------------------------------
-- Name: Zachary Q. Murdock
-- Description:
--    Horizontal Counter for the VGA signal generator
--
-- Create Date: 11/12/2024 12:57:12 PM
-- Module Name: VGAHorizontalCounter - Behavioral
-- Target Devices: Artix-7 Basys 3
----------------------------------------------------------------------------------

library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.NUMERIC_STD.ALL;

entity VGAHorizontalCounter is
    Port (
        in_pixel_clk : in STD_LOGIC;

        out_h_sync   : out STD_LOGIC;
        out_line_clk : out STD_LOGIC;

        out_display_active   : out STD_LOGIC;
        out_display_position : out integer range 1279 downto 0
    );
end VGAHorizontalCounter;

architecture Behavioral of VGAHorizontalCounter is
    constant HORIZONTAL_PIXELS : integer := 1688;
    constant HORIZONTAL_SIZE   : integer := 1280;

    constant FRONT_PORCH_WIDTH : integer := 48;
    constant H_SYNC_WIDTH      : integer := 112;
    constant BACK_PORCH_WIDTH  : integer := 248;

    constant H_SYNC_START : integer := HORIZONTAL_SIZE + FRONT_PORCH_WIDTH + 1;
    constant H_SYNC_END   : integer := HORIZONTAL_SIZE + FRONT_PORCH_WIDTH + H_SYNC_WIDTH + 1;

    signal current_pixel : integer range (HORIZONTAL_PIXELS - 1) downto 0;
begin
    counter : process(in_pixel_clk)
        variable in_display_area : STD_LOGIC;
    begin
        if (rising_edge(in_pixel_clk)) then
            if (current_pixel >= H_SYNC_START and current_pixel < H_SYNC_END) then
                out_h_sync <= '1';
            else
                out_h_sync <= '0';
            end if;

            if (current_pixel = (HORIZONTAL_PIXELS - 1)) then
                out_line_clk <= '1';
            else
                out_line_clk <= '0';
            end if;

            if ((current_pixel >= 0) and (current_pixel < HORIZONTAL_SIZE)) then
                in_display_area := '1';
            else
                in_display_area := '0';
            end if;

            out_display_active   <= in_display_area;

            if (in_display_area = '1') then
                out_display_position <= current_pixel;
            else
                out_display_position <= 0;
            end if;

            if (current_pixel = (HORIZONTAL_PIXELS - 1)) then
                current_pixel <= 0;
            else
                current_pixel <= current_pixel + 1;
            end if;
        end if;
    end process counter;
end Behavioral;