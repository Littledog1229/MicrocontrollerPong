----------------------------------------------------------------------------------
-- Name: Zachary Q. Murdock
-- Description:
--    Vertical Counter for the VGA signal generator
--
-- Create Date: 11/12/2024 12:57:12 PM
-- Module Name: VGAVerticalCounter - Behavioral
-- Target Devices: Artix-7 Basys 3
----------------------------------------------------------------------------------

library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGAVerticalCounter is
    Port (
        in_line_clk : in STD_LOGIC;

        out_v_sync : out STD_LOGIC;

        out_display_active   : out STD_LOGIC;
        out_display_position : out integer range 1023 downto 0
    );
end VGAVerticalCounter;

architecture Behavioral of VGAVerticalCounter is
    constant VERTICAL_LINES : integer := 1066;
    constant VERTICAL_SIZE  : integer := 1024;

    constant FRONT_PORCH_WIDTH : integer := 1;
    constant V_SYNC_WIDTH      : integer := 3;
    constant BACK_PORCH_WIDTH  : integer := 38;

    constant V_SYNC_START : integer := VERTICAL_SIZE + FRONT_PORCH_WIDTH + 1;
    constant V_SYNC_END   : integer := VERTICAL_SIZE + FRONT_PORCH_WIDTH + V_SYNC_WIDTH + 1;

    signal current_line : integer range (VERTICAL_LINES - 1) downto 0;
begin
    counter : process(in_line_clk)
        variable in_display_area : STD_LOGIC;
    begin
        if (rising_edge(in_line_clk)) then
            if (current_line >= V_SYNC_START and current_line < V_SYNC_END) then
                out_v_sync <= '1';
            else
                out_v_sync <= '0';
            end if;

            if ((current_line >= 0) and (current_line < VERTICAL_SIZE)) then
                in_display_area := '1';
            else
                in_display_area := '0';
            end if;

            out_display_active <= in_display_area;

            if (in_display_area = '1') then
                out_display_position <= current_line;
            else
                out_display_position <= 0;
            end if;

            if (current_line = (VERTICAL_LINES - 1)) then
                current_line <= 0;
            else
                current_line <= current_line + 1;
            end if;

            --current_line <= (current_line + 1) mod VERTICAL_LINES;
        end if;
    end process counter;
end Behavioral;