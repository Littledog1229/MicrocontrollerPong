----------------------------------------------------------------------------------
-- Name: Zachary Q. Murdock
-- Description:
--    Pixel processor that decides the R, G, and B output for the VGA signal
--
-- Create Date: 11/13/2024 09:39:10 PM
-- Module Name: VGAPixelProcessor - Behavioral
-- Target Devices: Artix-7 Basys 3
----------------------------------------------------------------------------------

library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Types.ALL;
use work.Functions.ALL;

entity VGAPixelProcessor is
    Port (
        -- System Clock
        in_pixel_clk : in STD_LOGIC;

        -- Global Registers
        in_global_registers : in GLOBAL_REGISTERS;

        -- Pixel Position Data
        in_pixel_x : in integer range 1279 downto 0;
        in_pixel_y : in integer range 1023 downto 0;

        -- Output Pixel Color
        out_pixel_r : out STD_LOGIC_VECTOR(3 downto 0);
        out_pixel_g : out STD_LOGIC_VECTOR(3 downto 0);
        out_pixel_b : out STD_LOGIC_VECTOR(3 downto 0)
    );
end VGAPixelProcessor;

architecture Behavioral of VGAPixelProcessor is
begin
    pixel_process : process(in_pixel_clk)
        variable r : STD_LOGIC_VECTOR(3 downto 0) := "0000";
        variable g : STD_LOGIC_VECTOR(3 downto 0) := "0000";
        variable b : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    begin
        if (rising_edge(in_pixel_clk)) then
            -- Set pixel color to background color (used as default)
            r := in_global_registers.background_color.R;
            g := in_global_registers.background_color.G;
            b := in_global_registers.background_color.B;

            -- Center dotted lines
            if ((in_pixel_y / (2**4)) mod 2 = 1 and
                in_pixel_x >= (1280 / 2) - 2 and
                in_pixel_x <= (1280 / 2) + 2
            ) then
                r := "0010";
                g := "0010";
                b := "0010";
            end if;

            -- Player 1 Paddle Pixel
            if (isPixelInside(
                in_pixel_x,
                in_pixel_y,
                in_global_registers.player_1_position,
                25,
                200
            ) = '1') then
                r := in_global_registers.player_1_color.R;
                g := in_global_registers.player_1_color.G;
                b := in_global_registers.player_1_color.B;
            end if;

            -- Player 2 Paddle Pixel
            if (isPixelInside(
                in_pixel_x,
                in_pixel_y,
                in_global_registers.player_2_position,
                25,
                200
            ) = '1') then
                r := in_global_registers.player_2_color.R;
                g := in_global_registers.player_2_color.G;
                b := in_global_registers.player_2_color.B;
            end if;

            -- Ball Pixel
            if (isPixelInside(
                in_pixel_x,
                in_pixel_y,
                in_global_registers.ball_position,
                25,
                25
            ) = '1') then
                r := in_global_registers.ball_color.R;
                g := in_global_registers.ball_color.G;
                b := in_global_registers.ball_color.B;
            end if;

            -- Player 1 Segments
            player_1_segment_loop : for i in 0 to 3 loop
                if (isInsideActiveSegment(
                    in_pixel_x,
                    in_pixel_y,

                    in_global_registers.player_1_segments(i)
                ) = '1') then
                    r := "1111";
                    g := "0111";
                    b := "0000";
                end if;
            end loop player_1_segment_loop;
            
            -- Player 1 Segments
            player_2_segment_loop : for i in 0 to 3 loop
                if (isInsideActiveSegment(
                    in_pixel_x,
                    in_pixel_y,

                    in_global_registers.player_2_segments(i)
                ) = '1') then
                    r := "0000";
                    g := "1110";
                    b := "1111";
                end if;
            end loop player_2_segment_loop;
            

            out_pixel_r <= r;
            out_pixel_g <= g;
            out_pixel_b <= b;
        end if;
    end process pixel_process;
end Behavioral;
