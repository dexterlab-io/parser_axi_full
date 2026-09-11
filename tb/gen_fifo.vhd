-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: gen_fifo.vhd
--  Author: Dexter
--  Date: 2026-06-25
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity gen_fifo is
  generic (
    gen_width : natural := 64;
    gen_depth : integer := 32
  );
  port (
    clk           : in  std_logic;
    rstn          : in  std_logic;

    -- AXI-Stream IN
    s_in_tdata    : in  std_logic_vector(gen_width-1 downto 0);
    s_in_tvalid   : in  std_logic;
    s_in_tready   : out std_logic;

    -- AXI-Stream OUT
    m_out_tdata   : out std_logic_vector(gen_width-1 downto 0);
    m_out_tvalid  : out std_logic;
    m_out_tready  : in  std_logic
  );
end gen_fifo;

architecture rtl of gen_fifo is

  --------------------------------------------------------------------
  -- Calcolo bit necessari per indirizzare gen_depth elementi
  --------------------------------------------------------------------
  constant nbits : natural := integer(ceil(log2(real(gen_depth))));

  --------------------------------------------------------------------
  -- Segnali interni
  --------------------------------------------------------------------
  signal s_wrbit  : std_logic_vector(gen_depth-1 downto 0);
  signal s_rdbit  : std_logic_vector(gen_depth-1 downto 0);
  signal s_rdaddr : std_logic_vector(nbits-1 downto 0);
  signal s_data   : std_logic_vector(gen_width-1 downto 0);

begin

  --------------------------------------------------------------------
  -- WRITER (istanza diretta VHDL‑2008)
  --------------------------------------------------------------------
  fifo_wr_inst : entity work.gen_fifo_wr
    generic map(
      gen_width => gen_width,
      gen_depth => gen_depth,
      gen_bits  => nbits
    )
    port map(
      clk         => clk,
      rstn        => rstn,
      s_in_tdata  => s_in_tdata,
      s_in_tvalid => s_in_tvalid,
      s_in_tready => s_in_tready,
      wrbit       => s_wrbit,
      rdbit       => s_rdbit,
      rdaddr      => s_rdaddr,
      data        => s_data
    );

  --------------------------------------------------------------------
  -- READER (istanza diretta VHDL‑2008)
  --------------------------------------------------------------------
  fifo_rd_inst : entity work.gen_fifo_rd
    generic map(
      gen_width => gen_width,
      gen_depth => gen_depth,
      gen_bits  => nbits
    )
    port map(
      clk          => clk,
      rstn         => rstn,
      m_out_tdata  => m_out_tdata,
      m_out_tvalid => m_out_tvalid,
      m_out_tready => m_out_tready,
      wrbit        => s_wrbit,
      rdbit        => s_rdbit,
      rdaddr       => s_rdaddr,
      data         => s_data
    );

end rtl;
