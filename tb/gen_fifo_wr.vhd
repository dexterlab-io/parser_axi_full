-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: gen_fifo_wr.vhd
--  Author: Dexter
--  Date: 2026-06-25
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gen_fifo_wr is
  generic (
    gen_width : natural := 64;
    gen_depth : integer := 32;
    gen_bits  : integer := 5
  );
  port (
    clk         : in  std_logic;
    rstn        : in  std_logic;

    s_in_tdata  : in  std_logic_vector(gen_width-1 downto 0);
    s_in_tvalid : in  std_logic;
    s_in_tready : out std_logic;

    wrbit       : out std_logic_vector(gen_depth-1 downto 0);
    rdbit       : in  std_logic_vector(gen_depth-1 downto 0);

    rdaddr      : in  std_logic_vector(gen_bits-1 downto 0);
    data        : out std_logic_vector(gen_width-1 downto 0)
  );
end entity;

architecture rtl of gen_fifo_wr is

  type fifo_t is array (0 to gen_depth-1) of std_logic_vector(gen_width-1 downto 0);

  signal s_entry  : fifo_t;
  signal s_wrbit  : std_logic_vector(gen_depth-1 downto 0);
  signal s_wraddr : unsigned(gen_bits-1 downto 0);
  signal s_avail  : std_logic;

begin

  wrbit       <= s_wrbit;
  s_in_tready <= s_avail;

  --------------------------------------------------------------------
  -- WRITE DATA + WRITE POINTER
  --------------------------------------------------------------------
  process(clk, rstn)
  begin
    if rstn = '0' then
      for i in 0 to gen_depth-1 loop
        s_entry(i) <= (others => '0');
      end loop;
      s_wraddr <= (others => '0');
    elsif rising_edge(clk) then
      if s_in_tvalid = '1' and s_avail = '1' then
        s_entry(to_integer(s_wraddr)) <= s_in_tdata;
        s_wraddr <= s_wraddr + 1;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------
  -- WRBIT UPDATE
  --------------------------------------------------------------------
  process(clk, rstn)
  begin
    if rstn = '0' then
      s_wrbit <= (others => '0');
    elsif rising_edge(clk) then
      for i in 0 to gen_depth-1 loop
        if s_in_tvalid = '1' and s_avail = '1' and i = to_integer(s_wraddr) then
          s_wrbit(i) <= '1';
        elsif rdbit(i) = '1' then
          s_wrbit(i) <= '0';
        end if;
      end loop;
    end if;
  end process;

  --------------------------------------------------------------------
  -- SLOT AVAILABLE (identico all’originale)
  --------------------------------------------------------------------
  process(s_wraddr, s_wrbit, rdbit)
  begin
    -- logica originale: un solo slot controllato
    if s_wrbit(to_integer(s_wraddr)) = '0' and
       rdbit (to_integer(s_wraddr)) = '0' then
      s_avail <= '1';
    else
      s_avail <= '0';
    end if;
  end process;

  --------------------------------------------------------------------
  -- READ DATA (combinatorio)
  --------------------------------------------------------------------
  data <= s_entry(to_integer(unsigned(rdaddr)));

end architecture;
