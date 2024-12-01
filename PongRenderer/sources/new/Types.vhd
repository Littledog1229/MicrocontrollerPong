----------------------------------------------------------------------------------
-- Name: Zachary Q. Murdock
-- Description:
--    A collection of various GLOBAL types used (primarily registers) throughout the design.
--
-- Create Date: 11/18/2024 3:30:19 PM
-- Module Name: Types - Package
-- Target Devices: Artix-7 Basys 3
----------------------------------------------------------------------------------

library IEEE;

use IEEE.STD_LOGIC_1164.ALL;

package Types is
    type position_register is record
        X : integer range 0 to 2**11 - 1;
        Y : integer range 0 to 2**11 - 1;
    end record position_register;

    type color_register is record
        R : STD_LOGIC_VECTOR(3 downto 0);
        G : STD_LOGIC_VECTOR(3 downto 0);
        B : STD_LOGIC_VECTOR(3 downto 0);
    end record color_register;

    type segment_register is record
        Position : POSITION_REGISTER;
        Segments : std_logic_vector(6 downto 0);
    end record segment_register;

    type player_segment_array is array (3 downto 0) of SEGMENT_REGISTER;

    type global_registers is record
        -- Miscelleneous Registers
        background_color : COLOR_REGISTER;

        -- Ball Registers
        ball_color       : COLOR_REGISTER;
        ball_position    : POSITION_REGISTER;

        -- Players Registers
        player_1_position : POSITION_REGISTER;
        player_1_color    : COLOR_REGISTER;

        player_2_position : POSITION_REGISTER;
        player_2_color    : COLOR_REGISTER;

        -- Segment Registers
        player_1_segments : PLAYER_SEGMENT_ARRAY;
        player_2_segments : PLAYER_SEGMENT_ARRAY;
    end record global_registers;
end package Types;