----------------------------------------------------------------------------------
-- Name: Zachary Q. Murdock
-- Description:
--    Main file that combines all sub-elements for this pong-rendering video card
--
-- Create Date: 11/12/2024 10:58:26 AM
-- Module Name: Main - Behavioral
-- Target Devices: Artix-7 Basys 3
----------------------------------------------------------------------------------

library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Types.ALL;

entity Main is
    Port (
        -- Clock
        in_clk : in STD_LOGIC;

        -- Switches [Temporary]
        in_sw : in STD_LOGIC_VECTOR(15 downto 0);

        -- LEDs [Temporary]
        led : out STD_LOGIC_VECTOR(15 downto 0);

        -- 7-Segment [Temporary?]
        out_seg : out STD_LOGIC_VECTOR(6 downto 0);
        out_an  : out STD_LOGIC_VECTOR(3 downto 0);

        -- VGA
        out_vga_red   : out STD_LOGIC_VECTOR(3 downto 0);
        out_vga_green : out STD_LOGIC_VECTOR(3 downto 0);
        out_vga_blue  : out STD_LOGIC_VECTOR(3 downto 0);

        out_vga_h_sync : out STD_LOGIC;
        out_vga_v_sync : out STD_LOGIC;

        
        -- USB Interface
        --out_uart_tx : out STD_LOGIC--;
        in_uart_rx  : in  STD_LOGIC
    );
end Main;

architecture Behavioral of Main is
    component IOController is
        port(
            in_sys_clk : in STD_LOGIC;

            led : out STD_LOGIC_VECTOR(9 downto 0);

            out_global_registers : out GLOBAL_REGISTERS;

            --out_uart_tx : out STD_LOGIC;
            in_uart_rx  : in  STD_LOGIC;

            out_temp_input : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component IOController;

    component VGAController is
        port(
            in_sys_clk : in STD_LOGIC;

            in_global_registers : in GLOBAL_REGISTERS;

            out_vga_red   : out STD_LOGIC_VECTOR(3 downto 0);
            out_vga_green : out STD_LOGIC_VECTOR(3 downto 0);
            out_vga_blue  : out STD_LOGIC_VECTOR(3 downto 0);

            out_vga_h_sync : out STD_LOGIC;
            out_vga_v_sync : out STD_LOGIC
        );
    end component VGAController;

    -- Global Registers
    --    Most significant bit is on the left

    --    See RegisterSpecification.txt for more information
    --        . Note: Use of concatenation operator to make literal assignments easier to read

    -- Default values controlled in CommandProcesor
    signal global_registers : GLOBAL_REGISTERS;

    signal last_uart_receive : STD_LOGIC_VECTOR(7 downto 0) := "00000000"; -- TEMPORARY

    signal bcd_clk : STD_LOGIC;

    signal bcd_div_counter : integer range 0 to 499999;
    signal bcd_segment     : integer range 0 to 1;

    signal bcd_high : integer range 0 to 15;
    signal bcd_low  : integer range 0 to 15;
    
    function INT_TO_BCD(int_value : integer) return STD_LOGIC_VECTOR is
        variable output : STD_LOGIC_VECTOR(6 downto 0) := "0000000";
    begin
        if (int_value = 0) then
            output := "1000000";
        elsif(int_value = 1) then
            output := "1111001";
        elsif(int_value = 2) then
            output := "0100100";
        elsif(int_value = 3) then
            output := "0110000";
        elsif(int_value = 4) then
            output := "0011001";
        elsif(int_value = 5) then
            output := "0010010";
        elsif(int_value = 6) then
            output := "0000010";
        elsif(int_value = 7) then
            output := "1111000";
        elsif(int_value = 8) then
            output := "0000000";
        elsif(int_value = 9) then
            output := "0010000";
        elsif(int_value = 10) then
            output := "0001000";
        elsif(int_value = 11) then
            output := "0000011";
        elsif(int_value = 12) then
            output := "1000110";
        elsif(int_value = 13) then
            output := "0100001";
        elsif(int_value = 14) then
            output := "0000110";
        elsif(int_value = 15) then
            output := "0001110";
        else
            output := "1111111";
        end if;

        return output;
    end function INT_TO_BCD;
begin
    bcd_div : process(in_clk)
    begin
        if (rising_edge(in_clk)) then
            if (bcd_div_counter = 0) then
                bcd_clk <= '1';
            else
                bcd_clk <= '0';
            end if;

            bcd_div_counter <= (bcd_div_counter + 1) mod 500000;
        end if;
    end process bcd_div;

    bcd : process(bcd_clk)
    begin
        if (rising_edge(bcd_clk)) then
            if (bcd_segment = 0) then
                out_an  <= "1101";
                out_seg <= INT_TO_BCD(bcd_high);

                bcd_segment <= 1;
            else
                out_an  <= "1110";
                out_seg <= INT_TO_BCD(bcd_low);

                bcd_segment <= 0;
            end if;
        end if;
    end process bcd;

    -- Temporary
    bcd_high <= to_integer(unsigned(last_uart_receive)) /   16;
    bcd_low  <= to_integer(unsigned(last_uart_receive)) mod 16;

    -- Temporary
    --global_registers.ball_position.X <= to_integer(unsigned(in_sw(15 downto 8)));
    --global_registers.ball_position.Y <= to_integer(unsigned(in_sw(7 downto 0)));

    io_controller_inst : component IOController
    port map(
        in_sys_clk => in_clk,
        
        led(7 downto 0) => led(7 downto 0),
        led(9 downto 8) => led(15 downto 14),

        out_global_registers => global_registers,

        --out_uart_tx => out_uart_tx,
        in_uart_rx => in_uart_rx,

        out_temp_input => last_uart_receive
    );

    vga_controller_inst : component VGAController
    port map(
        in_sys_clk => in_clk,

        in_global_registers => global_registers,

        out_vga_red   => out_vga_red,
        out_vga_green => out_vga_green,
        out_vga_blue  => out_vga_blue,

        out_vga_h_sync => out_vga_h_sync,
        out_vga_v_sync => out_vga_v_sync
    );
end Behavioral;
