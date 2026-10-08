-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_master.vhd
--  Author: Dexter
--  Date: 2026-09-06
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmd_cfg.all;
use work.cmd_cmd_pkg.all;

entity cmd_master is
	port (
		clk			: in  std_logic;
		resetn		: in  std_logic;

		start		: in  std_logic;

		interrupts  : in std_logic_vector(7 downto 0);

		------------------------------------------------------------------
		-- Handshake verso arbiter / axi_full
		------------------------------------------------------------------
		cmd_valid	: out std_logic;
		cmd_ready	: in  std_logic;

		------------------------------------------------------------------
		-- Comando convertito (record)
		------------------------------------------------------------------
		cmd			: out t_cmd_out;

		rsp_out		: out t_rsp_out;

		------------------------------------------------------------------
		-- Risultato del comando (record)
		------------------------------------------------------------------
		rsp_in		: in  t_rsp_in
	);
end entity cmd_master;

architecture rtl of cmd_master is

	signal s_start		: std_logic;
	signal s_active		: std_logic;

begin

    --------------------------------------------------------------------
    -- START
    --------------------------------------------------------------------
    process(clk, resetn)
    begin
        if resetn = '0' then
            s_start <= '0';
        elsif rising_edge(clk) then
            s_start <= start;
        end if;
    end process;

    --------------------------------------------------------------------
    -- START
    --------------------------------------------------------------------
    process(clk, resetn)
    begin
        if resetn = '0' then
			s_active <= '0';
        elsif rising_edge(clk) then
			if s_start = '1' then
				s_active <= '1';
			else
				s_active <= '0';
			end if;
        end if;
    end process;


    --------------------------------------------------------------------
    -- Uscite inattive (safe defaults)
    --------------------------------------------------------------------

	cmd_valid				<= '1' when s_active = '1' else '0';

	cmd.cmd_write			<= '0';
	cmd.cmd_burst			<= '0';
	cmd.cmd_wrap			<= '0';
	cmd.cmd_fifo			<= '0';

	cmd.cmd_id				<= (others => '0');
	cmd.cmd_addr			<= (others => '0');
	cmd.cmd_len				<= 1;

	cmd.cmd_data			<= (others => (others => '0'));
	cmd.cmd_wstrb			<= (others => '0');

	cmd.cmd_prot		<= (others => '0');
	cmd.cmd_size		<= (others => '0');
	cmd.cmd_lock		<= '0';
	cmd.cmd_cache		<= (others => '0');
	cmd.cmd_qos			<= (others => '0');

	rsp_out.rsp_ready		<= '1';
    rsp_out.rsp_err_ready	<= '1';



end architecture rtl;
