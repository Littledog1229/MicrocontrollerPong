----------------------------------------------------------------------------------
-- Name: Zachary Q. Murdock
-- Description: 
--    asd
-- 
-- Create Date: 11/18/2024 04:38:08 PM
-- Module Name: UARTController - Behavioral
-- Target Devices: Artix-7 Basys 3
----------------------------------------------------------------------------------

library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UARTController is
    Port (
        in_sys_clk : in STD_LOGIC;
        
        led : out STD_LOGIC_VECTOR(7 downto 0);

        --out_uart_tx : out STD_LOGIC;
        in_uart_rx  : in  STD_LOGIC;

        out_uart_receive : out STD_LOGIC;

        --in_data  : in STD_LOGIC;
        out_data : out STD_LOGIC_VECTOR(7 downto 0)
    );
end UARTController;

architecture Behavioral of UARTController is
    component BaudClock
        port (
            out_baud_clk : out STD_LOGIC;

            in_sys_clk   : in  STD_LOGIC
        );
    end component;

    type RECEIVER_STATE is (Waiting, Data, Stop);

    signal receive_state : RECEIVER_STATE := Waiting;
    signal data_packet   : STD_LOGIC_VECTOR(7 downto 0);

    signal baud_counter_clk : STD_LOGIC;
    signal baud_clk         : STD_LOGIC;

    signal current_receive_bit      : integer range 0 to 8 := 0;
    signal receive_constructed_data : STD_LOGIC_VECTOR(7 downto 0);
    
    constant INVERT_POLARITY : STD_LOGIC := '0';
    
    constant H_POL : STD_LOGIC := '1';--'1' when (INVERT_POLARITY = '0') else '0';
    constant L_POL : STD_LOGIC := '0';--'0' when (INVERT_POLARITY = '0') else '1';
    
begin
    baud_clock_inst : BaudClock
    port map (
        out_baud_clk => baud_counter_clk,

        in_sys_clk => in_sys_clk
    );

-- Reset comment
    baud_counter : process(baud_counter_clk)
        variable receive_baud_counter : integer range 0 to 9999;
    begin
        if (rising_edge(baud_counter_clk)) then
            if (receive_baud_counter = 0) then
                baud_clk <= '1';
            else
                baud_clk <= '0';
            end if;

            receive_baud_counter := (receive_baud_counter + 1) mod 10000;
        end if;
    end process baud_counter;

    receiver_state_handler : process(baud_clk)
    begin
        if (rising_edge(baud_clk)) then
            if ((receive_state = Waiting) and (in_uart_rx = L_POL)) then
                -- The start bit has been sent, update the state
                receive_state <= Data;
            elsif ((receive_state = Data) and (current_receive_bit >= 8)) then
                receive_state <= Stop;
            elsif ((receive_state = Stop) and (in_uart_rx = L_POL)) then
                receive_state <= Data;
            elsif ((receive_state = Stop) and (in_uart_rx = H_POL)) then
                receive_state <= Waiting;
            end if;
        end if;
    end process receiver_state_handler;

    receiver_process : process(baud_clk)
    begin
        if (rising_edge(baud_clk)) then
            if (receive_state = Data) then
                if (INVERT_POLARITY = '0') then
                    receive_constructed_data(current_receive_bit) <= in_uart_rx;
                else
                    receive_constructed_data(current_receive_bit) <= not in_uart_rx;
                end if;
                
                current_receive_bit <= current_receive_bit + 1;
                out_uart_receive    <= '0';
            elsif (receive_state = Stop) then
                current_receive_bit <= 0;
                out_data            <= receive_constructed_data;
                out_uart_receive    <= '1';
            else
                out_uart_receive <= '0';
            end if;
            
            led <= receive_constructed_data;
        end if;
    end process receiver_process;
end Behavioral;
