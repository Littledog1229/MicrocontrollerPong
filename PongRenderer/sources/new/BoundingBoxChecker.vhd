----------------------------------------------------------------------------------
-- Name: Zachary Q. Murdock
-- Description:
--    Checks if a screen pixel is inside of the bounds of the box
--
-- Create Date: 11/14/2024 10:31:09 AM
-- Module Name: BoundingBoxChecker - Behavioral
-- Target Devices: Artix-7 Basys 3
----------------------------------------------------------------------------------

-- TODO: Convert this to be a procedure instead?

library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Types.ALL;

entity BoundingBoxChecker is
    generic(
        WIDTH  : natural;
        HEIGHT : natural
    );
    Port (
        in_pixel_clk : in STD_LOGIC;

        in_pixel_x : in integer range 1279 downto 0;
        in_pixel_y : in integer range 1079 downto 0;

        in_position_register : in POSITION_REGISTER;

        out_pixel_active : out STD_LOGIC
    );
end BoundingBoxChecker;

architecture Behavioral of BoundingBoxChecker is
begin
    pixel_selector : process(in_pixel_clk)
    begin
        -- Check if the current pixel is inside of this object
        if (
            in_pixel_x >= in_position_register.X         and
            in_pixel_x <  in_position_register.X + WIDTH and

            in_pixel_y >= in_position_register.Y         and
            in_pixel_y <  in_position_register.Y + HEIGHT
        ) then
            out_pixel_active <= '1';
        else
            out_pixel_active <= '0';
        end if;
    end process pixel_selector;
end Behavioral;
