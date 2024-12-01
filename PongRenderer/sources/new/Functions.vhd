----------------------------------------------------------------------------------
-- Name: Zachary Q. Murdock
-- Description:
--    todo
--
-- Create Date: 12/01/2024 02:05:47 AM
-- Module Name: Functions
-- Target Devices:
--
----------------------------------------------------------------------------------


library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Types.ALL;

package Functions is
    function isPixelInside (
        pixel_x : integer range 0 to 1279;
        pixel_y : integer range 0 to 1079;

        position : POSITION_REGISTER;

        width  : integer range 0 to 1279;
        height : integer range 0 to 1079
    )
    return STD_LOGIC;

    function isInsideActiveSegment (
        pixel_x : integer range 0 to 1279;
        pixel_y : integer range 0 to 1079;

        segment_register : in SEGMENT_REGISTER
    )
    return STD_LOGIC;
end package Functions;

package body Functions is
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

    function isInsideActiveSegment (
        pixel_x : integer range 0 to 1279;
        pixel_y : integer range 0 to 1079;

        segment_register : in SEGMENT_REGISTER
    )
    return STD_LOGIC is
        constant segment_separation : integer := 4;
        constant segment_length     : integer := 32;
        constant segment_width      : integer := 4;
        
        constant right_segment_x         : integer := segment_separation + segment_length;
        constant bottom_segment_y        : integer := (segment_separation * 2) + segment_length;
        constant center_segment_y        : integer := (segment_length + segment_separation);
        constant bottom_bottom_segment_y : integer := (segment_length * 2) + (segment_separation * 2);
    
        variable inside_segment : STD_LOGIC := '0';
    begin
        inside_segment := '0';

        -- segment 0 (Top)
        if (segment_register.Segments(0) = '1' and isPixelInside(
            pixel_x,
            pixel_y,

            (segment_register.Position.X + segment_separation, segment_register.Position.Y),

            segment_length,
            segment_width
        ) = '1') then
            inside_segment := '1';
        end if;

        -- segment 1 (Top-Right)
        if (segment_register.Segments(1) = '1' and isPixelInside(
            pixel_x,
            pixel_y,

            (segment_register.Position.X + right_segment_x, segment_register.Position.Y + segment_separation),

            segment_width,
            segment_length
        ) = '1') then
            inside_segment := '1';
        end if;

        -- segment 2 (Bottom-Right)
        if (segment_register.Segments(2) = '1' and isPixelInside(
            pixel_x,
            pixel_y,

            (segment_register.Position.X + right_segment_x, segment_register.Position.Y + bottom_segment_y),

            segment_width,
            segment_length
        ) = '1') then
            inside_segment := '1';
        end if;

        -- segment 3 (Bottom)
        if (segment_register.Segments(3) = '1' and isPixelInside(
            pixel_x,
            pixel_y,

            (segment_register.Position.X + segment_separation, segment_register.Position.Y + bottom_bottom_segment_y),

            segment_length,
            segment_width
        ) = '1') then
            inside_segment := '1';
        end if;

        -- segment 4 (Bottom-Left)
        if (segment_register.Segments(4) = '1' and isPixelInside(
            pixel_x,
            pixel_y,

            (segment_register.Position.X, segment_register.Position.Y + bottom_segment_y),

            segment_width,
            segment_length
        ) = '1') then
            inside_segment := '1';
        end if;

        -- segment 5 (Top-Left)
        if (segment_register.Segments(5) = '1' and isPixelInside(
            pixel_x,
            pixel_y,

            (segment_register.Position.X, segment_register.Position.Y + segment_separation),

            segment_width,
            segment_length
        ) = '1') then
            inside_segment := '1';
        end if;

        -- segment 6 (Center)
        if (segment_register.Segments(6) = '1' and isPixelInside(
            pixel_x,
            pixel_y,

            (segment_register.Position.X + segment_separation, segment_register.Position.Y + center_segment_y),

            segment_length,
            segment_width
        ) = '1') then
            inside_segment := '1';
        end if;

        return inside_segment;
    end function isInsideActiveSegment;
end package body Functions;