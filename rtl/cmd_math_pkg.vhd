-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_math_pkg.vhd
--  Author: Dexter
--  Date: 2026-09-06
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmd_cfg.all;

package cmd_math_pkg is

    --------------------------------------------------------------------
    -- ADDR arithmetic
    --------------------------------------------------------------------
    function addr_add(
        a_addr : t_addr;
        b_addr : t_addr
    ) return t_addr;

    function addr_add_offset(
        a_addr  : t_addr;
        b_offset : natural
    ) return t_addr;

    function addr_add_n(
        a_addr : t_addr;
        n      : natural
    ) return t_addr;

    function addr_shift_left(
        a_addr : t_addr;
        n      : natural
    ) return t_addr;

    --------------------------------------------------------------------
    -- DATA arithmetic
    --------------------------------------------------------------------
    function data_add(
        a_data : t_data;
        b_data : t_data
    ) return t_data;

    function data_add_offset(
        a_data  : t_data;
        b_offset : natural
    ) return t_data;

    function data_add_n(
        a_data : t_data;
        n      : natural
    ) return t_data;

    function data_shift_left(
        a_data : t_data;
        n      : natural
    ) return t_data;

    --------------------------------------------------------------------
    -- Unsigned difference
    --------------------------------------------------------------------
    function unsigned_diff(
        a : unsigned;
        b : unsigned
    ) return natural;

    --------------------------------------------------------------------
    -- Next 4K boundary
    --------------------------------------------------------------------
    function next_4k_boundary(
        addr : t_addr
    ) return unsigned;

end package cmd_math_pkg;

package body cmd_math_pkg is

    --------------------------------------------------------------------
    -- ADDR arithmetic
    --------------------------------------------------------------------
    function addr_add(
        a_addr : t_addr;
        b_addr : t_addr
    ) return t_addr is
        variable ua : unsigned(a_addr'range);
        variable ub : unsigned(b_addr'range);
        variable c_sum : unsigned(a_addr'range);
    begin
        ua := unsigned(a_addr);
        ub := unsigned(b_addr);
        c_sum := ua + ub;
        return std_logic_vector(c_sum);
    end function;

    function addr_add_offset(
        a_addr   : t_addr;
        b_offset : natural
    ) return t_addr is
        variable ua : unsigned(a_addr'range);
        variable c_sum : unsigned(a_addr'range);
    begin
        ua := unsigned(a_addr);
        c_sum := ua + to_unsigned(b_offset, a_addr'length);
        return std_logic_vector(c_sum);
    end function;

    function addr_add_n(
        a_addr : t_addr;
        n      : natural
    ) return t_addr is
        variable ua : unsigned(a_addr'range);
        variable c_sum : unsigned(a_addr'range);
    begin
        ua := unsigned(a_addr);
        c_sum := ua + to_unsigned(n, a_addr'length);
        return std_logic_vector(c_sum);
    end function;

    --------------------------------------------------------------------
    -- SHIFT LEFT sicuro (senza shift_left di numeric_std)
    --------------------------------------------------------------------
    function addr_shift_left(a_addr : t_addr; n : natural) return t_addr is
        variable res : t_addr := (others => '0');
    begin
        if n < a_addr'length then
            res(a_addr'length-1 downto n) := a_addr(a_addr'length-1-n downto 0);
        end if;
        return res;
    end function;

    --------------------------------------------------------------------
    -- DATA arithmetic
    --------------------------------------------------------------------
    function data_add(a_data : t_data; b_data : t_data) return t_data is
        variable ua : unsigned(C_DATA_WIDTH-1 downto 0);
        variable ub : unsigned(C_DATA_WIDTH-1 downto 0);
        variable ur : unsigned(C_DATA_WIDTH-1 downto 0);
    begin
        ua := unsigned(a_data);
        ub := unsigned(b_data);
        ur := ua + ub;
        return std_logic_vector(ur);
    end function;

    function data_add_offset(a_data : t_data; b_offset : natural) return t_data is
        variable ua : unsigned(C_DATA_WIDTH-1 downto 0);
        variable ur : unsigned(C_DATA_WIDTH-1 downto 0);
    begin
        ua := unsigned(a_data);
        ur := ua + to_unsigned(b_offset, C_DATA_WIDTH);
        return std_logic_vector(ur);
    end function;

    function data_add_n(a_data : t_data; n : natural) return t_data is
        variable ua : unsigned(C_DATA_WIDTH-1 downto 0);
        variable ur : unsigned(C_DATA_WIDTH-1 downto 0);
    begin
        ua := unsigned(a_data);
        ur := ua + to_unsigned(n, C_DATA_WIDTH);
        return std_logic_vector(ur);
    end function;

    --------------------------------------------------------------------
    -- SHIFT LEFT sicuro per DATA
    --------------------------------------------------------------------
    function data_shift_left(a_data : t_data; n : natural) return t_data is
        variable res : t_data := (others => '0');
    begin
        if n < C_DATA_WIDTH then
            res(C_DATA_WIDTH-1 downto n) := a_data(C_DATA_WIDTH-1-n downto 0);
        end if;
        return res;
    end function;

    --------------------------------------------------------------------
    -- Unsigned difference (corretto)
    --------------------------------------------------------------------
    function unsigned_diff(
        a : unsigned;
        b : unsigned
    ) return natural is
    begin
        return to_integer(a) - to_integer(b);
    end function;

    --------------------------------------------------------------------
    -- Next 4K boundary (corretto per qualsiasi C_ADDR_WIDTH >= 12)
    --------------------------------------------------------------------
    function next_4k_boundary(addr : t_addr) return unsigned is
        variable a : unsigned(C_ADDR_WIDTH-1 downto 0) := unsigned(addr);
        variable mask : unsigned(C_ADDR_WIDTH-1 downto 0) := (others => '0');
        variable add4k : unsigned(C_ADDR_WIDTH-1 downto 0) := (others => '0');
    begin
        -- genera maschera FFFF_F000 dinamica
        for i in C_ADDR_WIDTH-1 downto 12 loop
            mask(i) := '1';
        end loop;

        -- genera valore 0x1000 dinamico
        add4k(12) := '1';

        return (a and mask) + add4k;
    end function;

end package body cmd_math_pkg;
