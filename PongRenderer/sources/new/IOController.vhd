----------------------------------------------------------------------------------
-- Name: Zachary Q. Murdock
-- Description: 
--    asd
--
-- Create Date: 11/18/2024 04:38:08 PM
-- Module Name: CommandHandler - Behavioral
-- Target Devices: Artix-7 Basys 3
----------------------------------------------------------------------------------

-- It may be best to take a LIFO approach to this design, but for now im just going to
-- assume I can process the commands faster than they get sent (which is almost
-- definitely the case)

library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Types.ALL;

entity IOController is
    Port (
        in_sys_clk : in STD_LOGIC;

        led : out STD_LOGIC_VECTOR(9 downto 0);

        out_global_registers : out GLOBAL_REGISTERS;

        --out_uart_tx : out STD_LOGIC;
        in_uart_rx  : in STD_LOGIC;

        out_temp_input : out STD_LOGIC_VECTOR(7 downto 0)
    );
end IOController;

architecture Behavioral of IOController is
    component UARTController is
        port(
            in_sys_clk : in STD_LOGIC;
            
            led : out STD_LOGIC_VECTOR(7 downto 0);

            --out_uart_tx : out STD_LOGIC;
            in_uart_rx  : in  STD_LOGIC;

            out_uart_receive : out STD_LOGIC;

            --in_data  : in STD_LOGIC;
            out_data : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component UARTController;

    component CommandProcessor is
        port(
            in_sys_clk : in STD_LOGIC;

            in_uart_receive      : in STD_LOGIC;
            in_uart_receive_data : in STD_LOGIC_VECTOR(7 downto 0);

            led : out STD_LOGIC_VECTOR(1 downto 0);

            out_global_registers : out GLOBAL_REGISTERS
        );
    end component CommandProcessor;

    signal uart_data          : STD_LOGIC_VECTOR(7 downto 0);
    signal uart_received_data : STD_LOGIC;
begin
    uart_controller_inst : UARTController
    port map(
        in_sys_clk => in_sys_clk,
        
        led => led(7 downto 0),

        --out_uart_tx => out_uart_tx,
        in_uart_rx  => in_uart_rx,

        out_uart_receive => uart_received_data,

        out_data => uart_data
    );

    command_processor_inst : CommandProcessor
    port map(
        in_sys_clk => in_sys_clk,

        in_uart_receive      => uart_received_data,
        in_uart_receive_data => uart_data,

        led => led(9 downto 8),

        out_global_registers => out_global_registers
    );

    out_temp_input <= uart_data;
end Behavioral;