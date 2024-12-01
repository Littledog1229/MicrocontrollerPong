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
    function isPixelInside (
            pixel_x : integer range 0 to 1279;
            pixel_y : integer range 0 to 1079;

            position : POSITION_REGISTER;

            width  : integer range 0 to 1279;
            height : integer range 0 to 1079
        )
    return STD_LOGIC is
        variable return_value : STD_LOGIC := '0';
    begin
        -- Check if the current pixel is inside of this object
        if (
            pixel_x >= position.X         and
            pixel_x <  position.X + width and

            pixel_y >= position.Y         and
            pixel_y <  position.Y + height
        ) then
            return_value := '1';
        else
            return_value := '0';
        end if;
        
        return return_value;
    end function isPixelInside;
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

            out_pixel_r <= r;
            out_pixel_g <= g;
            out_pixel_b <= b;
        end if;
    end process pixel_process;
end Behavioral;
