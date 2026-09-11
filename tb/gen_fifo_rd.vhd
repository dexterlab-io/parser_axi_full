-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: gen_fifo_rd.vhd - tb
--  Author: Dexter
--  Date: 2026-06-25
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gen_fifo_rd is
  generic (
    gen_width : natural := 64;
    gen_depth : integer := 32;
    gen_bits  : integer := 5
  );
  port (
    clk          : in  std_logic;
    rstn         : in  std_logic;

    m_out_tdata  : out std_logic_vector(gen_width-1 downto 0);
    m_out_tvalid : out std_logic;
    m_out_tready : in  std_logic;

    wrbit        : in  std_logic_vector(gen_depth-1 downto 0);
    rdbit        : out std_logic_vector(gen_depth-1 downto 0);

    rdaddr       : out std_logic_vector(gen_bits-1 downto 0);
    data         : in  std_logic_vector(gen_width-1 downto 0)
  );
end entity;

architecture rtl of gen_fifo_rd is

  signal s_rdbit       : std_logic_vector(gen_depth-1 downto 0);
  signal s_rdaddr      : unsigned(gen_bits-1 downto 0);
  signal s_pend        : std_logic_vector(gen_depth-1 downto 0);

  signal s_valid       : std_logic;
  signal s_data        : std_logic_vector(gen_width-1 downto 0);

  constant ZERO_PEND : std_logic_vector(gen_depth-1 downto 0) := (others => '0');

begin

  rdbit  <= s_rdbit;
  rdaddr <= std_logic_vector(s_rdaddr);

  m_out_tdata  <= s_data;
  m_out_tvalid <= s_valid;

  --------------------------------------------------------------------
  -- PENDING LOGIC (identica all’originale)
  -- pending(i) = 1 when slot is "accepted" (rdbit=1) and not overwritten (wrbit=0)
  --------------------------------------------------------------------
  process(wrbit, s_rdbit)
  begin
    for i in 0 to gen_depth-1 loop
      if s_rdbit(i) = '1' and wrbit(i) = '0' then
        s_pend(i) <= '1';
      else
        s_pend(i) <= '0';
      end if;
    end loop;
  end process;

  --------------------------------------------------------------------
  -- OUTPUT VALID + DATA
  --------------------------------------------------------------------
  s_valid <= '1' when s_pend /= ZERO_PEND  else '0';
  s_data  <= data when s_valid = '1' else (others => '0');

  --------------------------------------------------------------------
  -- READ POINTER + RDBIT UPDATE
  --------------------------------------------------------------------
  process(clk, rstn)
  begin
    if rstn = '0' then
      s_rdaddr <= (others => '0');
      s_rdbit  <= (others => '0');
    elsif rising_edge(clk) then

      -- advance pointer when data consumed
      if s_valid = '1' and m_out_tready = '1' then
        s_rdaddr <= s_rdaddr + 1;
      end if;

      -- update rdbit
      for i in 0 to gen_depth-1 loop
        if s_valid = '1' and m_out_tready = '1' and i = to_integer(s_rdaddr) then
          s_rdbit(i) <= '0';
        elsif wrbit(i) = '1' then
          s_rdbit(i) <= '1';
        end if;
      end loop;

    end if;
  end process;

end architecture;
