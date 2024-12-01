----------------------------------------------------------------------------------
-- Name: Zachary Q. Murdock
-- Description: 
--    Command processor that updates the global registers according to USART input commands
-- 
-- Create Date: 11/20/2024 09:58:06 PM
-- Module Name: CommandParser - Behavioral
-- Target Devices: Artix-7 Basys 3
----------------------------------------------------------------------------------

library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Types.ALL;

entity CommandProcessor is
    Port (
        in_sys_clk : in STD_LOGIC;

        in_uart_receive      : in STD_LOGIC;
        in_uart_receive_data : in STD_LOGIC_VECTOR(7 downto 0);

        led : out STD_LOGIC_VECTOR(1 downto 0);

        out_global_registers : out GLOBAL_REGISTERS := (
            background_color=> ("0000", "0000", "0000"),

            ball_position => ((1280/2)-(25/2)-1, (1024/2)-(25/2)-1),
            ball_color    => ("1111", "1111", "1111"),

            player_1_position => (100, 0),
            player_1_color    => ("1111", "0000", "0000"),

            player_2_position => (1279-25-100, 0),
            player_2_color    => ("0000", "0000", "1100"),
            
            player_1_segments => (
                ((((1280 / 2) - 25 - (48 * 3 + 40)) + 144, 25), "0111111"),
                ((((1280 / 2) - 25 - (48 * 3 + 40)) + 96,  25), "0111111"),
                ((((1280 / 2) - 25 - (48 * 3 + 40)) + 48,  25), "0111111"),
                ((((1280 / 2) - 25 - (48 * 3 + 40)) + 0,   25), "0111111")
            ),
            
            player_2_segments => (
                (((1280 / 2) + 25 + 144, 25), "0111111"),
                (((1280 / 2) + 25 + 96,  25), "0111111"),
                (((1280 / 2) + 25 + 48,  25), "0111111"),
                (((1280 / 2) + 25 + 0,   25), "0111111")
            )
        )
    );
end CommandProcessor;

architecture Behavioral of CommandProcessor is
    signal buffered_uart_receive : STD_LOGIC_VECTOR(7 downto 0);
    signal uart_receive_event    : STD_LOGIC;
    signal uart_event_processed  : STD_LOGIC;

    signal constructed_command : STD_LOGIC_VECTOR(31 downto 0);
    signal command_received    : STD_LOGIC;
    signal command_byte        : integer range 0 to 3;

    signal command_decay_count        : integer range 0 to 100000000;
    signal command_decay_signal       : STD_LOGIC;
begin
    led <= STD_LOGIC_VECTOR(to_unsigned(command_byte, led'length));

    command_data_receiver : process(in_uart_receive)
    begin
        if (rising_edge(in_uart_receive)) then
            buffered_uart_receive <= in_uart_receive_data;
            uart_receive_event    <= not uart_receive_event;
        end if;
    end process command_data_receiver;

    command_decay_counter : process(in_sys_clk)
    begin
        if (rising_edge(in_sys_clk)) then
            if ((command_decay_count = 99999999) and (uart_receive_event = uart_event_processed)) then
                command_decay_signal <= '1';
            else
                command_decay_signal <= '0';
            end if;

            if (in_uart_receive = '1') then
                command_decay_count <= 0;
            else
                command_decay_count <= (command_decay_count + 1) mod 100000000;
            end if;
        end if;
    end process command_decay_counter;

    command_constructor : process(in_sys_clk, in_uart_receive)
        variable new_uart_data : STD_LOGIC := '0';
    begin
        if (rising_edge(in_sys_clk)) then
            if (uart_receive_event /= uart_event_processed) then
                new_uart_data := '1';
                uart_event_processed <= uart_receive_event;
            else
                new_uart_data := '0';
            end if;

            if ((command_decay_signal = '1') and (new_uart_data = '0')) then
                command_byte <= 0;
            end if;

            if (new_uart_data = '1') then
                constructed_command(((command_byte * 8) + 7) downto ((command_byte * 8))) <= buffered_uart_receive;

                if (command_byte = 3) then
                    command_received <= '1';
                else
                    command_received <= '0';
                end if;

                command_byte <= (command_byte + 1) mod 4;
            end if;
        end if;
    end process command_constructor;

    command_processor : process(command_received)
        variable command_id : STD_LOGIC_VECTOR(5 downto 0);
    begin
        if (rising_edge(command_received)) then
            command_id := constructed_command(31 downto 26);
            if (command_id = "000000") then
                -- Background Color Command
                out_global_registers.background_color.R <= constructed_command(11 downto 8);
                out_global_registers.background_color.G <= constructed_command(7  downto 4);
                out_global_registers.background_color.B <= constructed_command(3  downto 0);
            elsif (command_id = "000001") then
                -- Ball Position Command
                out_global_registers.ball_position.X <= to_integer(unsigned(constructed_command(21 downto 11)));
                out_global_registers.ball_position.Y <= to_integer(unsigned(constructed_command(10 downto  0)));
            elsif (command_id = "000010") then
                -- Ball Color Command
                out_global_registers.ball_color.R <= constructed_command(11 downto 8);
                out_global_registers.ball_color.G <= constructed_command(7  downto 4);
                out_global_registers.ball_color.B <= constructed_command(3  downto 0);
            --elsif (command_id = "00011") then
                -- Player X Position Command
                --   . Reserved, not in use right now
            elsif (command_id = "000100") then
                -- Player Y Position Command
                if (constructed_command(11) = '0') then
                    -- Player 1 (left side)
                    out_global_registers.player_1_position.Y <= to_integer(unsigned(constructed_command(10 downto 0)));
                else
                    -- Player 2 (right side)
                    out_global_registers.player_2_position.Y <= to_integer(unsigned(constructed_command(10 downto 0)));
                end if;
            elsif (command_id = "000101") then
                -- Player Color Command
                if (constructed_Command(12) = '0') then 
                    -- Player 1 (left side)
                    out_global_registers.player_1_color.R <= constructed_command(11 downto 8);
                    out_global_registers.player_1_color.G <= constructed_command(7  downto 4);
                    out_global_registers.player_1_color.B <= constructed_command(3  downto 0);
                else
                    -- Player 2 (right side)
                    out_global_registers.player_2_color.R <= constructed_command(11 downto 8);
                    out_global_registers.player_2_color.G <= constructed_command(7  downto 4);
                    out_global_registers.player_2_color.B <= constructed_command(3  downto 0);
                end if;
            elsif (command_id = "000110") then
                if (constructed_command(9) = '0') then
                    out_global_registers.player_1_segments(to_integer(unsigned(constructed_command(8 downto 7)))).Segments <= constructed_command(6 downto 0);
                else
                    out_global_registers.player_2_segments(to_integer(unsigned(constructed_command(8 downto 7)))).Segments <= constructed_command(6 downto 0);
                end if;
            end if;
        end if;
    end process command_processor;
end Behavioral;