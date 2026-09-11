-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: arbiter_mux.vhd
--  Author: Dexter
--  Date: 2026-09-08
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmd_cfg.all;
use work.cmd_cmd_pkg.all;
use work.cmd_pkg.all;

entity arbiter_mux is
    port (
        clk    : in  std_logic;
        resetn : in  std_logic;

        ----------------------------------------------------------------
        -- Parser → ingressi
        ----------------------------------------------------------------
        parser_valid   : in  std_logic;
        parser_ready   : out std_logic;
        parser_cmd     : in  t_cmd_out;
        parser_rsp_in  : in  t_rsp_out;
        parser_rsp_out : out t_rsp_in;

        ----------------------------------------------------------------
        -- Master → ingressi
        ----------------------------------------------------------------
        master_valid   : in  std_logic;
        master_ready   : out std_logic;
        master_cmd     : in  t_cmd_out;
        master_rsp_in  : in  t_rsp_out;
        master_rsp_out : out t_rsp_in;

        ----------------------------------------------------------------
        -- Verso AXI executor → uscite
        ----------------------------------------------------------------
        valid : out std_logic;
        ready : in  std_logic;

        cmd    : out t_cmd_out;
        rsp_out: out t_rsp_out;
        rsp_in : in  t_rsp_in
    );
end entity arbiter_mux;

architecture rtl of arbiter_mux is

    --------------------------------------------------------------------
    -- FSM
    --------------------------------------------------------------------
    type t_state is (
        IDLE,
        PARSER_ACTIVE,
        MASTER_ACTIVE
    );

    signal state_current, state_next : t_state;

    --------------------------------------------------------------------
    -- Registri dei comandi e risposte
    --------------------------------------------------------------------
    signal s_parser_cmd     : t_cmd_out;
    signal s_parser_rsp_in  : t_rsp_out;
    signal s_parser_pending : std_logic;
	signal s_parser_ready   : std_logic;

    signal s_master_cmd     : t_cmd_out;
    signal s_master_rsp_in  : t_rsp_out;
    signal s_master_pending : std_logic;
	signal s_master_ready   : std_logic;

    --------------------------------------------------------------------
    -- Clear values
    --------------------------------------------------------------------
    signal s_cmd_clear      : t_cmd_out;
    signal s_rsp_in_clear   : t_rsp_out;
    signal s_rsp_out_clear  : t_rsp_in;

    signal s_valid          : std_logic;

begin

    --------------------------------------------------------------------
    -- Clear values
    --------------------------------------------------------------------
    s_cmd_clear.cmd_write    <= '0';
    s_cmd_clear.cmd_burst    <= '0';
    s_cmd_clear.cmd_wrap     <= '0';
    s_cmd_clear.cmd_fifo     <= '0';
    s_cmd_clear.cmd_atomic     <= '0';
    s_cmd_clear.cmd_id       <= (others => '0');
    s_cmd_clear.cmd_len      <= 0;
    s_cmd_clear.cmd_addr     <= (others => '0');
    s_cmd_clear.cmd_data     <= (others => (others => '0'));
    s_cmd_clear.cmd_wstrb    <= (others => '0');

    s_rsp_in_clear.rsp_ready     <= '0';
    s_rsp_in_clear.rsp_err_ready <= '0';

    s_rsp_out_clear.rsp_valid     <= '0';
    s_rsp_out_clear.rsp_last      <= '0';
    s_rsp_out_clear.rsp_data      <= (others => '0');
    s_rsp_out_clear.rsp_id        <= (others => '0');
    s_rsp_out_clear.rsp_err_valid <= '0';
    s_rsp_out_clear.rsp_err_code  <= (others => '0');
    s_rsp_out_clear.rsp_err_info  <= (others => '0');
    s_rsp_out_clear.rsp_err_id    <= (others => '0');

    --------------------------------------------------------------------
    -- FSM stato corrente
    --------------------------------------------------------------------
    process(clk, resetn)
    begin
        if resetn = '0' then
            state_current <= IDLE;
        elsif rising_edge(clk) then
            state_current <= state_next;
        end if;
    end process;

	--------------------------------------------------------------------
	-- PARSER
	--------------------------------------------------------------------
	process(clk, resetn)
	begin
		if resetn = '0' then
			s_parser_cmd <=  s_cmd_clear;
			s_parser_rsp_in <= s_rsp_in_clear;
			s_parser_pending <= '0';
		elsif rising_edge(clk) then
			if parser_valid = '1' and ready = '1' then
				s_parser_cmd <=  parser_cmd;
				s_parser_rsp_in <= parser_rsp_in;
				s_parser_pending <= '1';
			elsif state_next = PARSER_ACTIVE and rsp_in.rsp_err_valid = '1' then
				s_parser_cmd <=  s_cmd_clear;
				s_parser_rsp_in <= s_rsp_in_clear;
				s_parser_pending <= '0';
			end if;
		end if;
	end process;

	--------------------------------------------------------------------
	-- MASTER
	--------------------------------------------------------------------
	process(clk, resetn)
	begin
		if resetn = '0' then
			s_master_cmd <=  s_cmd_clear;
			s_master_rsp_in <= s_rsp_in_clear;
			s_master_pending <= '0';
		elsif rising_edge(clk) then
			if master_valid = '1' and ready = '1' then
				s_master_cmd <=  master_cmd;
				s_master_rsp_in <= master_rsp_in;
				s_master_pending <= '1';
			elsif state_next = MASTER_ACTIVE and rsp_in.rsp_err_valid = '1' then
				s_master_cmd <=  s_cmd_clear;
				s_master_rsp_in <= s_rsp_in_clear;
				s_master_pending <= '0';
			end if;
		end if;
	end process;

    --------------------------------------------------------------------
    -- FSM next state
    --------------------------------------------------------------------
    process(state_current,
			parser_cmd, master_cmd,
			s_parser_pending, s_master_pending,
			ready,
            parser_valid, master_valid,
            rsp_in)
    begin

		case state_current is

            ----------------------------------------------------------------
            -- Nessuno attivo: scegli chi arbitrare
            ----------------------------------------------------------------
            when IDLE =>
				if parser_valid = '1' and ready = '1' then
                    state_next <= PARSER_ACTIVE;
                elsif master_valid = '1' and ready = '1' then
                    state_next <= MASTER_ACTIVE;
                else
                    state_next <= IDLE;
                end if;

            ----------------------------------------------------------------
            -- Parser attivo
            ----------------------------------------------------------------
            when PARSER_ACTIVE =>
				if s_parser_pending = '1' and rsp_in.rsp_err_valid = '0' then
                        state_next <= PARSER_ACTIVE;
				elsif s_parser_pending = '1' and rsp_in.rsp_err_valid = '1' then
                        state_next <= PARSER_ACTIVE;
				elsif parser_cmd.cmd_atomic = '1' then
                    state_next <= PARSER_ACTIVE;
                elsif master_valid = '1' and ready = '1' then
                    state_next <= MASTER_ACTIVE;
                elsif s_master_pending = '1' and ready = '1' then
                    state_next <= MASTER_ACTIVE;
				elsif parser_valid = '1' and ready = '1' then
                    state_next <= PARSER_ACTIVE;
				elsif s_parser_pending = '1' and ready = '1' then
                    state_next <= PARSER_ACTIVE;
                elsif ready = '1' then
                    state_next <= IDLE;
                else
                    state_next <= PARSER_ACTIVE;
                end if;

			-------------------------------------------------
            -- Master attivo
            ----------------------------------------------------------------
            when MASTER_ACTIVE =>
				if s_master_pending = '1' and rsp_in.rsp_err_valid = '0' then
                        state_next <= MASTER_ACTIVE;
				elsif s_master_pending = '1' and rsp_in.rsp_err_valid = '1' then
                        state_next <= MASTER_ACTIVE;
				elsif master_cmd.cmd_atomic = '1' then
                    state_next <= MASTER_ACTIVE;
                elsif parser_valid = '1' and ready = '1' then
                    state_next <= PARSER_ACTIVE;
                elsif s_parser_pending = '1' and ready = '1' then
                    state_next <= PARSER_ACTIVE;
				elsif master_valid = '1' and ready = '1' then
                    state_next <= MASTER_ACTIVE;
				elsif s_master_pending = '1' and ready = '1' then
                    state_next <= MASTER_ACTIVE;
                elsif ready = '1' then
                    state_next <= IDLE;
                else
                    state_next <= MASTER_ACTIVE;
                end if;
            when OTHERS =>
				state_next <= IDLE;

        end case;
    end process;


	valid <=	'1' when parser_valid = '1' and ready = '1' and state_current = IDLE and state_next = PARSER_ACTIVE else
				'1' when master_valid = '1' and ready = '1' and state_current = IDLE and state_next = MASTER_ACTIVE else
				'1' when parser_valid = '1' and ready = '1' and state_current = MASTER_ACTIVE and state_next = PARSER_ACTIVE else
				'1' when master_valid = '1' and ready = '1' and state_current = PARSER_ACTIVE and state_next = MASTER_ACTIVE else
				'1' when s_parser_pending = '1' and ready = '1' and state_current = MASTER_ACTIVE and state_next = PARSER_ACTIVE else
				'1' when s_master_pending = '1' and ready = '1' and state_current = PARSER_ACTIVE and state_next = MASTER_ACTIVE else
				'1' when parser_valid = '1' and ready = '1' and state_current = PARSER_ACTIVE and state_next = PARSER_ACTIVE else
				'1' when master_valid = '1' and ready = '1' and state_current = MASTER_ACTIVE and state_next = MASTER_ACTIVE else
				'1' when s_parser_pending = '1' and ready = '1' and state_current = PARSER_ACTIVE and state_next = PARSER_ACTIVE else
				'1' when s_master_pending = '1' and ready = '1' and state_current = MASTER_ACTIVE and state_next = MASTER_ACTIVE else
				'0';

    --------------------------------------------------------------------
    -- Mux comandi e risposte
    --------------------------------------------------------------------
	cmd 	<=	parser_cmd when parser_valid = '1' and ready = '1' and state_current = IDLE and state_next = PARSER_ACTIVE else
				master_cmd when master_valid = '1' and ready = '1' and state_current = IDLE and state_next = MASTER_ACTIVE else
				parser_cmd when parser_valid = '1' and ready = '1' and state_current = MASTER_ACTIVE and state_next = PARSER_ACTIVE else
				master_cmd when master_valid = '1' and ready = '1' and state_current = PARSER_ACTIVE and state_next = MASTER_ACTIVE else
				s_parser_cmd when s_parser_pending = '1' and ready = '1' and state_current = MASTER_ACTIVE and state_next = PARSER_ACTIVE else
				s_master_cmd when s_master_pending = '1' and ready = '1' and state_current = PARSER_ACTIVE and state_next = MASTER_ACTIVE else
				parser_cmd when parser_valid = '1' and ready = '1' and state_current = PARSER_ACTIVE and state_next = PARSER_ACTIVE else
				master_cmd when master_valid = '1' and ready = '1' and state_current = MASTER_ACTIVE and state_next = MASTER_ACTIVE else
				s_parser_cmd when s_parser_pending = '1' and ready = '1' and state_current = PARSER_ACTIVE and state_next = PARSER_ACTIVE else
				s_master_cmd when s_master_pending = '1' and ready = '1' and state_current = MASTER_ACTIVE and state_next = MASTER_ACTIVE else
				s_parser_cmd when state_current = PARSER_ACTIVE and state_next = PARSER_ACTIVE else
				s_master_cmd when state_current = MASTER_ACTIVE and state_next = MASTER_ACTIVE else
				s_cmd_clear;

	rsp_out <=	parser_rsp_in when parser_valid = '1' and ready = '1' and state_current = IDLE and state_next = PARSER_ACTIVE else
				master_rsp_in when master_valid = '1' and ready = '1' and state_current = IDLE and state_next = MASTER_ACTIVE else
				parser_rsp_in when parser_valid = '1' and ready = '1' and state_current = MASTER_ACTIVE and state_next = PARSER_ACTIVE else
				master_rsp_in when master_valid = '1' and ready = '1' and state_current = PARSER_ACTIVE and state_next = MASTER_ACTIVE else
				s_parser_rsp_in when s_parser_pending = '1' and ready = '1' and state_current = MASTER_ACTIVE and state_next = PARSER_ACTIVE else
				s_master_rsp_in when s_master_pending = '1' and ready = '1' and state_current = PARSER_ACTIVE and state_next = MASTER_ACTIVE else
				parser_rsp_in when parser_valid = '1' and ready = '1' and state_current = PARSER_ACTIVE and state_next = PARSER_ACTIVE else
				master_rsp_in when master_valid = '1' and ready = '1' and state_current = MASTER_ACTIVE and state_next = MASTER_ACTIVE else
				s_parser_rsp_in when s_parser_pending = '1' and ready = '1' and state_current = PARSER_ACTIVE and state_next = PARSER_ACTIVE else
				s_master_rsp_in when s_master_pending = '1' and ready = '1' and state_current = MASTER_ACTIVE and state_next = MASTER_ACTIVE else
				s_parser_rsp_in when state_current = PARSER_ACTIVE and state_next = PARSER_ACTIVE else
				s_master_rsp_in when state_current = MASTER_ACTIVE and state_next = MASTER_ACTIVE else
				s_rsp_in_clear;


    --------------------------------------------------------------------
    -- Rsp_in verso parser/master
    --------------------------------------------------------------------
	parser_rsp_out <=	rsp_in when state_next = PARSER_ACTIVE else
						s_rsp_out_clear;

	master_rsp_out <=	rsp_in when state_next = MASTER_ACTIVE else
						s_rsp_out_clear;

    --------------------------------------------------------------------
    -- Ready verso parser/master
    --------------------------------------------------------------------
	s_parser_ready <=	'1' when ready = '1' and state_next = IDLE and s_parser_pending = '0' else
						'1' when ready = '1' and state_next = PARSER_ACTIVE else
						'1' when ready = '1' and state_next = MASTER_ACTIVE and s_parser_pending = '0' else
						'0';

	s_master_ready <=	'1' when ready = '1' and state_next = IDLE  and s_master_pending = '0' else
						'1' when ready = '1' and state_next = MASTER_ACTIVE else
						'1' when ready = '1' and state_next = PARSER_ACTIVE and s_master_pending = '0' else
						'0';

	parser_ready <= s_parser_ready;

	master_ready <= s_master_ready;


end architecture rtl;
