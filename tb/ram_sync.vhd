-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: ram_sync.vhd
--  Author: Dexter
--  Date: 2026-09-10
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity ram_sync is
    generic (
        g_depth    : integer := 1024;              -- numero di word
        g_aw       : integer := 10;                -- log2(g_depth)
        g_cde_file : string  := "ram_init.cde"     -- file di init
    );
    port (
        clk   : in  std_logic;
        cs    : in  std_logic;
        we    : in  std_logic;
        addr  : in  std_logic_vector(g_aw-1 downto 0);
        wstrb : in  std_logic_vector(3 downto 0);
        din   : in  std_logic_vector(31 downto 0);
        dout  : out std_logic_vector(31 downto 0)
    );
end entity;


architecture rtl of ram_sync is

    --------------------------------------------------------------------
    -- Tipo RAM
    --------------------------------------------------------------------
    type t_ram is array(0 to g_depth-1) of std_logic_vector(31 downto 0);

    --------------------------------------------------------------------
    -- Inizializzazione da file .cde
    --------------------------------------------------------------------
    impure function init_ram_from_cde return t_ram is
        variable mem : t_ram := (others => (others => '0'));
        file f      : text;
        variable l  : line;
        variable c  : character;

        variable v_addr_str : string(1 to 3);
        variable v_addr_int : integer;

        variable v_hex : string(1 to 8);
        variable v_slv : std_logic_vector(31 downto 0);
    begin
        file_open(f, g_cde_file, read_mode);

        while not endfile(f) loop
            readline(f, l);

            -- Leggi indirizzo (3 hex)
            for i in 1 to 3 loop
                read(l, c);
                v_addr_str(i) := c;
            end loop;

            -- Converti indirizzo
            v_addr_int := 0;
            for i in 1 to 3 loop
                v_addr_int := v_addr_int * 16;
                case v_addr_str(i) is
                    when '0' => null;
                    when '1' => v_addr_int := v_addr_int + 1;
                    when '2' => v_addr_int := v_addr_int + 2;
                    when '3' => v_addr_int := v_addr_int + 3;
                    when '4' => v_addr_int := v_addr_int + 4;
                    when '5' => v_addr_int := v_addr_int + 5;
                    when '6' => v_addr_int := v_addr_int + 6;
                    when '7' => v_addr_int := v_addr_int + 7;
                    when '8' => v_addr_int := v_addr_int + 8;
                    when '9' => v_addr_int := v_addr_int + 9;
                    when 'A' | 'a' => v_addr_int := v_addr_int + 10;
                    when 'B' | 'b' => v_addr_int := v_addr_int + 11;
                    when 'C' | 'c' => v_addr_int := v_addr_int + 12;
                    when 'D' | 'd' => v_addr_int := v_addr_int + 13;
                    when 'E' | 'e' => v_addr_int := v_addr_int + 14;
                    when 'F' | 'f' => v_addr_int := v_addr_int + 15;
                    when others =>
                        report "Indirizzo HEX non valido nel CDE" severity error;
                end case;
            end loop;

            -- Salta spazio
            read(l, c);

            -- Leggi dato (8 hex)
            for i in 1 to 8 loop
                read(l, c);
                v_hex(i) := c;
            end loop;

            -- Converti dato
            v_slv := (others => '0');
            for i in 0 to 7 loop
                case v_hex(i+1) is
                    when '0' => v_slv(31 - 4*i downto 28 - 4*i) := "0000";
                    when '1' => v_slv(31 - 4*i downto 28 - 4*i) := "0001";
                    when '2' => v_slv(31 - 4*i downto 28 - 4*i) := "0010";
                    when '3' => v_slv(31 - 4*i downto 28 - 4*i) := "0011";
                    when '4' => v_slv(31 - 4*i downto 28 - 4*i) := "0100";
                    when '5' => v_slv(31 - 4*i downto 28 - 4*i) := "0101";
                    when '6' => v_slv(31 - 4*i downto 28 - 4*i) := "0110";
                    when '7' => v_slv(31 - 4*i downto 28 - 4*i) := "0111";
                    when '8' => v_slv(31 - 4*i downto 28 - 4*i) := "1000";
                    when '9' => v_slv(31 - 4*i downto 28 - 4*i) := "1001";
                    when 'A' | 'a' => v_slv(31 - 4*i downto 28 - 4*i) := "1010";
                    when 'B' | 'b' => v_slv(31 - 4*i downto 28 - 4*i) := "1011";
                    when 'C' | 'c' => v_slv(31 - 4*i downto 28 - 4*i) := "1100";
                    when 'D' | 'd' => v_slv(31 - 4*i downto 28 - 4*i) := "1101";
                    when 'E' | 'e' => v_slv(31 - 4*i downto 28 - 4*i) := "1110";
                    when 'F' | 'f' => v_slv(31 - 4*i downto 28 - 4*i) := "1111";
                    when others =>
                        report "Dato HEX non valido nel CDE" severity error;
                end case;
            end loop;

            -- Scrivi nella RAM iniziale
            if v_addr_int >= 0 and v_addr_int < g_depth then
                mem(v_addr_int) := v_slv;
            end if;
        end loop;

        file_close(f);
        return mem;
    end function;

    --------------------------------------------------------------------
    -- RAM vera e propria
    --------------------------------------------------------------------
    signal s_ram  : t_ram := init_ram_from_cde;
    signal s_dout : std_logic_vector(31 downto 0) := (others => '0');

begin

    --------------------------------------------------------------------
    -- Processo sincrono RAM con WSTRB
    --------------------------------------------------------------------
    process(clk)
        variable idx : integer;
    begin
        if rising_edge(clk) then
            idx := to_integer(unsigned(addr));

            if cs = '1' then

                -- WRITE con WSTRB
                if we = '1' then
                    if idx >= 0 and idx < g_depth then
                        for i in 0 to 3 loop
                            if wstrb(i) = '1' then
                                s_ram(idx)((i*8)+7 downto (i*8)) <= din((i*8)+7 downto (i*8));
                            end if;
                        end loop;
                    end if;
                end if;

                -- READ
                if idx >= 0 and idx < g_depth then
                    s_dout <= s_ram(idx);
                else
                    s_dout <= (others => '0');
                end if;

            end if;
        end if;
    end process;

    dout <= s_dout;

end architecture;
