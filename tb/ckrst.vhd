-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: ckrst.vhd
--  Author: Dexter
--  Date: 2026-05-13
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;

entity ckrst is
    port (
        clk    : out std_logic;
        resetn : out std_logic;
        start  : out std_logic
    );
end entity;

architecture beh of ckrst is

    constant clk_period : time := 10 ns;  -- 100 MHz

    signal s_clk    : std_logic := '0';
    signal s_resetn : std_logic := '0';
    signal s_start  : std_logic := '0';

begin

    --------------------------------------------------------------------
    -- Clock generator
    --------------------------------------------------------------------
    s_clk <= not s_clk after clk_period/2;
    clk   <= s_clk;

    --------------------------------------------------------------------
    -- Reset generator (active low)
    --------------------------------------------------------------------
    s_resetn <= '0', '1' after 200 ns;
    resetn   <= s_resetn;

    --------------------------------------------------------------------
    -- Start pulse generation
    -- start = 0 during reset
    -- start = 1 for 20 ns after reset
    --------------------------------------------------------------------
    s_start <= '0',
               '1' after 240 ns;

    start <= s_start;


end architecture;
