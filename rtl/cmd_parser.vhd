-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_parser.vhd
--  Author: Dexter
--  Date: 2026-09-10
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmd_cfg.all;
use work.cmd_text_pkg.all;
use work.cmd_lex_pkg.all;
use work.cmd_parse_pkg.all;
use work.cmd_semantic_pkg.all;
use work.cmd_cmd_pkg.all;
use work.cmd_split_pkg.all;
use work.cmd_file_pkg.all;
use work.cmd_eval_pkg.all;
use work.cmd_log_pkg.all;
use work.cmd_map_pkg.all;

entity cmd_parser is
	generic (
		FILENAME	: string := "cmd.txt";
		DRY_RUN		: boolean := false
	);
	port (
		clk			: in  std_logic;
		resetn		: in  std_logic;
		start		: in  std_logic;
		cmd_valid	: out std_logic;
		cmd_ready	: in  std_logic;
		cmd			: out t_cmd_out;
		rsp_out		: out t_rsp_out;	-- NOT USED (RESERVED for future expansions)
		rsp_in		: in  t_rsp_in
	);
end entity;

architecture rtl of cmd_parser is

    --------------------------------------------------------------------
    -- Costanti
    --------------------------------------------------------------------
    constant LOG_INDENT   : string  := "                         ";  -- 25 spazi
    constant ADDR_STR_LEN : natural := 2 + (C_ADDR_WIDTH/4);
    constant DATA_STR_LEN : natural := 2 + (C_DATA_WIDTH/4);

    --------------------------------------------------------------------
    -- Microcomandi generati dal parsing
    --------------------------------------------------------------------
    signal s_mc_list    : t_mc_list;
    signal s_mc_count   : natural := 0;
    signal s_mc_index   : natural := 0;
    signal s_mc_cur     : t_mc_cmd := mc_clear;
	signal s_mc_next    : t_mc_cmd := mc_clear;

    --------------------------------------------------------------------
    -- Stato del parser
    --------------------------------------------------------------------
    signal s_end_sim : boolean := false;
    signal s_eof     : boolean := false;

    --------------------------------------------------------------------
    -- Include stack
    --------------------------------------------------------------------
    signal s_include_stack : include_stack_t :=
        (others => (
            tag         => 0,
            filename    => (others => ' '),
            line_number => 0
        ));
    signal s_include_depth : natural := 0;

    --------------------------------------------------------------------
    -- Interfaccia AXI verso arbiter/wrapper (nuova)
    --------------------------------------------------------------------
    signal s_cmd_valid : std_logic := '0';

    signal s_cmd_out : t_cmd_out := (
        cmd_write  => '0',
        cmd_burst  => '0',
        cmd_wrap   => '0',
        cmd_fifo   => '0',
        cmd_atomic => '0',
        cmd_id     => (others => '0'),
        cmd_addr   => (others => '0'),
        cmd_len    => 0,
        cmd_data   => (others => (others => '0')),
		cmd_wstrb  => (others => '0')
    );

    signal s_rsp_out : t_rsp_out := (
        rsp_ready     => '0',
        rsp_err_ready => '0'
    );

    signal s_atomic : std_logic := '0';

    --------------------------------------------------------------------
    -- FSM del parser
    --------------------------------------------------------------------
    type t_state is (
        idle,
        parse_file,
        parse_file_done,
        exec_print,
        exec_atomic,
        exec_wait,
        exec_base,
        exec_fifo,
        exec_burst,
        exec_wrap,
        exec_fill,
        exec_poll,
        exec_poll_wait,
        exec_dump,
        next_cmd,
        exec_stop,
        finished
    );

    signal state_current : t_state := idle;
    signal state_next    : t_state := idle;

    signal s_start : std_logic := '0';

    --------------------------------------------------------------------
    -- WAIT / POLL / ATOMIC
    --------------------------------------------------------------------
    signal s_wait_active  : std_logic := '0';
    signal s_wait_done    : std_logic := '0';
    signal s_wait_timeout : std_logic := '0';
    signal s_wait_count   : unsigned(31 downto 0) := (others => '0');

    signal s_poll_timeout      : std_logic := '0';
    signal s_poll_value        : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal s_poll_masked_value : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal s_poll_last_value   : std_logic_vector(C_DATA_WIDTH-1 downto 0);

    signal s_poll_retry_next  : std_logic := '0';
    signal s_poll_delay_count : integer := 0;
    signal s_poll_retry_count : integer := 0;

    signal s_data_index : integer := 0;

    --------------------------------------------------------------------
    -- Logging
    --------------------------------------------------------------------
    signal s_dry_run  : boolean := false;
    signal s_log_open : std_logic := '0';
    signal s_log_tag  : natural := 0;

    signal s_dump_open : std_logic := '0';
    signal s_dump_tag  : natural := 0;

    --------------------------------------------------------------------
    -- ERRORI DI PARSING
    --------------------------------------------------------------------
    signal s_parse_error       : boolean := false;
    signal s_parse_error_count : natural := 0;

    --------------------------------------------------------------------
    -- ERRORI DI EXECUTION (GLOBALI)
    --------------------------------------------------------------------
    signal s_exec_error       : boolean := false;
    signal s_exec_error_count : natural := 0;

    --------------------------------------------------------------------
    -- ERRORI PER CATEGORIA (EXECUTION)
    --------------------------------------------------------------------
    signal s_base_error        : boolean := false;
    signal s_base_error_count  : natural := 0;

    signal s_fifo_error        : boolean := false;
    signal s_fifo_error_count  : natural := 0;

    signal s_burst_error       : boolean := false;
    signal s_burst_error_count : natural := 0;

    signal s_wrap_error        : boolean := false;
    signal s_wrap_error_count  : natural := 0;

    signal s_fill_error        : boolean := false;
    signal s_fill_error_count  : natural := 0;

    signal s_poll_error        : boolean := false;
    signal s_poll_error_count  : natural := 0;

    signal s_dump_error        : boolean := false;
    signal s_dump_error_count  : natural := 0;

    signal s_axi_error        : boolean := false;
    signal s_axi_error_count  : natural := 0;

    --------------------------------------------------------------------
    -- ERRORI TOTALI (PARSE + EXEC)
    --------------------------------------------------------------------
    signal s_error       : boolean := false;
    signal s_error_count : natural := 0;

    signal s_ack_data      : std_logic := '0';
    signal s_ack_data_last : std_logic := '0';
    signal s_ack_err       : std_logic := '0';
    signal s_ack_end       : std_logic := '0';

begin

	s_dry_run <= DRY_RUN;

	s_rsp_out.rsp_ready     <= '1';
	s_rsp_out.rsp_err_ready <= '1';


	--------------------------------------------------------------------
	-- Collegamenti verso l'esterno (nuova interfaccia AXI-like)
	--------------------------------------------------------------------
	cmd_valid <= s_cmd_valid;
	cmd       <= s_cmd_out;
	rsp_out   <= s_rsp_out;

	-- cmd_ready è un input: lo usi direttamente nei processi
	-- rsp_in è un input: lo usi direttamente nei processi

	--------------------------------------------------------------------
	-- PROCESSO: PROCESS_FILE
	-- Gestisce parsing di UNA sola riga + caricamento microcomandi
	--------------------------------------------------------------------
	process(clk, resetn)
		variable v_mc_list    : t_mc_list;
		variable v_mc_count   : natural;
		variable v_end_sim    : boolean;
		variable v_parse_error  : boolean;
		variable v_parse_error_count  : natural;

		variable v_inc_stack  : include_stack_t :=
			(others => (
				tag         => 0,
				filename    => (others => ' '),
				line_number => 0
			));

		variable v_inc_depth  : natural;

		variable tmp_line : t_line;
		variable tmp_str  : string(1 to C_MAX_STRING);

		variable v_fname_line : t_line := (others => ' ');

	begin
		if resetn = '0' then
			s_mc_list       <= (others => mc_clear);
			s_mc_count      <= 0;
			s_end_sim       <= false;
			s_eof           <= false;

			s_parse_error        <= false;
			s_parse_error_count  <= 0;   -- ⭐ reset contatore parsing

			s_include_stack <= (others => (
				tag         => 0,
				filename    => (others => ' '),
				line_number => 0
			));
			s_include_depth <= 0;

			s_mc_cur        <= mc_clear;
			s_mc_index      <= 0;
            s_mc_next       <= mc_clear;  -- reset pipeline

		elsif rising_edge(clk) then

			----------------------------------------------------------------
			-- PARSE_FILE → parsing di UNA sola riga
			----------------------------------------------------------------
			if state_current = parse_file then

				-- reset locale
				v_mc_list    := (others => mc_clear);
				v_mc_count   := 0;
				v_end_sim    := false;
				v_parse_error  := false;
				v_parse_error_count  := s_parse_error_count;

				-- copia dello stack include
				v_inc_stack := s_include_stack;
				v_inc_depth := s_include_depth;

				----------------------------------------------------------------
				-- Apertura file principale SOLO la prima volta
				----------------------------------------------------------------
				if v_inc_depth = 0 then
					if not s_end_sim then

						-- Converti FILENAME (string) → t_line
						for i in FILENAME'range loop
							v_fname_line(i) := FILENAME(i);
						end loop;

						-- Apri file principale
						log_open_read(trim_string(v_fname_line), v_inc_stack(1).tag);

						v_inc_depth := 1;

						v_inc_stack(1).filename    := v_fname_line;
						v_inc_stack(1).line_number := 0;
					end if;
				end if;

				----------------------------------------------------------------
				-- Chiamata alla process_file (streaming)
				----------------------------------------------------------------
				process_file(
					v_mc_list,
					v_mc_count,
					v_inc_stack,
					v_inc_depth,
					v_end_sim,
					v_parse_error,
					v_parse_error_count,
					s_dry_run
				);

				----------------------------------------------------------------
				-- ⭐ STOP IMMEDIATO SE ERRORE DI PARSING E dry_run = false
				----------------------------------------------------------------
				if (not s_dry_run) and v_parse_error then
					report "ERROR: parsing failed. Run with dry_run = true to see all errors."
						severity error;

					-- aggiorna contatori globali
					s_parse_error        <= true;
					s_parse_error_count  <= v_parse_error_count;

					-- forza fine simulazione
					s_end_sim <= true;

					-- ⭐ NON tocchiamo state_next (FSM asincrona)
					-- ⭐ NON usiamo return
					-- ⭐ NON eseguiamo il resto del ramo parse_file
				else

					----------------------------------------------------------------
					-- Gestione EOF e aggiornamento s_eof / include_stack
					----------------------------------------------------------------
					if v_inc_depth > 0 then
						if log_eof(v_inc_stack(v_inc_depth).tag) then

							log_close(v_inc_stack(v_inc_depth).tag);

							v_inc_stack(v_inc_depth).tag         := 0;
							v_inc_stack(v_inc_depth).filename    := (others => ' ');
							v_inc_stack(v_inc_depth).line_number := 0;

							v_inc_depth := v_inc_depth - 1;
							s_eof <= true;

						else
							s_eof <= false;
						end if;
					else
						s_eof <= true;
					end if;

					----------------------------------------------------------------
					-- Aggiorna registri del parser
					----------------------------------------------------------------
					s_mc_list       <= v_mc_list;
					s_mc_count      <= v_mc_count;
					s_end_sim       <= v_end_sim;

					s_parse_error        <= v_parse_error;
					s_parse_error_count  <= v_parse_error_count;

					s_include_stack <= v_inc_stack;
					s_include_depth <= v_inc_depth;

					----------------------------------------------------------------
					-- Controlli END_SIM
					----------------------------------------------------------------
					if s_end_sim = true and v_end_sim = true then
						report "ERROR: multiple END_SIM commands" severity error;

						-- ⭐ incrementa contatore parsing
						s_parse_error        <= true;
						s_parse_error_count  <= s_parse_error_count + 1;
					end if;

					if s_end_sim = true then
						if v_mc_count > 0 then
							report "ERROR: command found after END_SIM" severity error;

							-- ⭐ incrementa contatore parsing
							s_parse_error        <= true;
							s_parse_error_count  <= s_parse_error_count + 1;
						end if;
					end if;

				end if; -- ⭐ fine ramo STOP immediato

			end if;

            ----------------------------------------------------------------
            -- CARICAMENTO PRIMO MICROCOMANDO + PRE-CARICA NEXT
            ----------------------------------------------------------------
            if state_current = parse_file_done then
                if s_mc_count > 0 then
                    s_mc_index <= 0;
                    s_mc_cur   <= s_mc_list(0);

                    if s_mc_count > 1 then
                        s_mc_next <= s_mc_list(1);  -- prossimo microcomando
                    else
                        s_mc_next <= mc_clear;
                    end if;
                else
                    s_mc_cur  <= mc_clear;
                    s_mc_next <= mc_clear;
                end if;

            ----------------------------------------------------------------
            -- AVANZAMENTO INDICE QUANDO UN MICROCOMANDO È FINITO
            -- (tutti gli stati exec_* convergono qui)
            ----------------------------------------------------------------
            elsif (
                (state_current = exec_wait      and state_next = next_cmd) or
                (state_current = exec_atomic    and state_next = next_cmd) or
                (state_current = exec_print     and state_next = next_cmd) or
                (state_current = exec_base      and state_next = next_cmd) or
                (state_current = exec_fifo      and state_next = next_cmd) or
                (state_current = exec_burst     and state_next = next_cmd) or
                (state_current = exec_wrap      and state_next = next_cmd) or
                (state_current = exec_fill      and state_next = next_cmd) or
                (state_current = exec_poll      and state_next = next_cmd) or
                (state_current = exec_dump      and state_next = next_cmd) or
                (state_current = exec_stop      and state_next = next_cmd)
            ) then

                if s_mc_index + 1 < s_mc_count then
                    -- avanzamento: usa il microcomando già pre-caricato
                    s_mc_index <= s_mc_index + 1;
                    s_mc_cur   <= s_mc_next;

                    -- pre-carica il prossimo (pipeline)
                    if s_mc_index + 2 < s_mc_count then
                        s_mc_next <= s_mc_list(s_mc_index + 2);
                    else
                        s_mc_next <= mc_clear;
                    end if;

                elsif s_mc_index + 1 = s_mc_count then
                    -- ultimo microcomando: nessun next
                    s_mc_index <= s_mc_index + 1;
                    s_mc_cur   <= s_mc_next;
                    s_mc_next  <= mc_clear;

                else
                    -- nessun microcomando successivo
                    s_mc_cur  <= mc_clear;
                    s_mc_next <= mc_clear;
                end if;


			end if;

		end if;
	end process;

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
    -- FSM sincrona
    --------------------------------------------------------------------
    process(clk, resetn)
    begin
        if resetn = '0' then
            state_current <= idle;
        elsif rising_edge(clk) then
            state_current <= state_next;
        end if;
    end process;

	process(rsp_in)
		variable err_msg  : t_err_string;
		variable err_flag : boolean;
	begin
		-- ACK dati (READ/WRITE)
		if rsp_in.rsp_valid = '1' then
			s_ack_data <= '1';
		else
			s_ack_data <= '0';
		end if;
		-- ACK dati last (READ/WRITE)
		if rsp_in.rsp_valid = '1' and rsp_in.rsp_last = '1' then
			s_ack_data_last <= '1';
		else
			s_ack_data_last <= '0';
		end if;

		-- ACK errore (READ/WRITE)
		if rsp_in.rsp_err_valid = '1' then
			-- decodifica errore tramite tabella
			decode_err(rsp_in.rsp_err_code, err_msg, err_flag);
			if err_flag then
				s_ack_err <= '1';
			else
				s_ack_err <= '0';
			end if;
		else
			-- nessun errore in questo ciclo
			s_ack_err <= '0';
		end if;

		-- ACK end
		if rsp_in.rsp_err_valid = '1' then
			s_ack_end <= '1';
		else
			s_ack_end <= '0';
		end if;
	end process;

	--------------------------------------------------------------------
	-- PROCESSO: FSM_COMBINATORIA — calcolo di state_next (versione AXI-like)
	--------------------------------------------------------------------
	process(
		start,
		s_start,
		state_current,
		s_parse_error,
		s_dry_run,
		s_mc_count,
		s_mc_index,
		s_mc_cur,
		s_wait_done,
		s_poll_delay_count,
		s_poll_retry_next,
		cmd_ready,          -- ⭐ accettazione comando
		rsp_in,             -- ⭐ completamento comando (solo per rsp_valid)
		s_include_depth,
		s_end_sim,
		s_eof,
		s_ack_data,
		s_ack_data_last,
		s_ack_err,
		s_ack_end
	)
	begin
		-- default
		state_next <= state_current;

		case state_current is

			----------------------------------------------------------------
			-- IDLE → aspetta start
			----------------------------------------------------------------
			when idle =>
				if start = '1' and s_start = '0' then
					state_next <= parse_file;
				end if;

			----------------------------------------------------------------
			-- PARSE_FILE → parsing completo (sincrono)
			----------------------------------------------------------------
			when parse_file =>
				state_next <= parse_file_done;

			----------------------------------------------------------------
			-- PARSE_FILE_DONE → decide se terminare o iniziare
			----------------------------------------------------------------
			when parse_file_done =>

				if s_include_depth = 0 then
					state_next <= finished;

				elsif s_parse_error then
					state_next <= finished;

				elsif s_end_sim = true then
					if s_eof = true then
						state_next <= finished;
					else
						state_next <= parse_file;
					end if;

				elsif s_dry_run then
					state_next <= finished;

				elsif s_mc_count = 0 then
					state_next <= parse_file;

				elsif s_mc_count = 1 then

					case s_mc_list(0).cmd_type is

						when CMD_PRINT        => state_next <= exec_print;
						when CMD_SET_ATOMIC   => state_next <= exec_atomic;

						when CMD_WAIT_TIME |
							CMD_WAIT_CLOCKS |
							CMD_WAIT_SIM_TIME =>
							state_next <= exec_wait;

						when CMD_READ |
							CMD_WRITE |
							CMD_CHECK |
							CMD_WSTRB_WRITE =>
							state_next <= exec_base;

						when CMD_STOP =>
							state_next <= exec_stop;

						when CMD_FIFO_WRITE |
							CMD_FIFO_READ |
							CMD_FIFO_CHECK   =>
							state_next <= exec_fifo;

						when CMD_BURST_WRITE |
							CMD_BURST_READ |
							CMD_BURST_CHECK  =>
							state_next <= exec_burst;

						when CMD_WRAP_WRITE |
							CMD_WRAP_READ |
							CMD_WRAP_CHECK   =>
							state_next <= exec_wrap;

						when CMD_FILL_LEN |
							CMD_FILL_RANGE |
							CMD_FILL_CHECK   =>
							state_next <= exec_fill;

						when CMD_DUMP_LEN |
							CMD_DUMP_RANGE |
							CMD_DUMP_FILE_LEN |
							CMD_DUMP_FILE_RANGE |
							CMD_DUMP_FILE_CHECK_LEN |
							CMD_DUMP_FILE_CHECK_RANGE =>
							state_next <= exec_dump;

						when CMD_POLL_READ |
							CMD_POLL_TOGGLE |
							CMD_POLL_PING    =>
							state_next <= exec_poll;

						when CMD_END_SIM      =>
							state_next <= parse_file;

						when others           =>
							state_next <= idle;

					end case;

				else
					state_next <= next_cmd;
				end if;

			----------------------------------------------------------------
			-- PRINT → comando locale, 1 ciclo
			----------------------------------------------------------------
			when exec_print =>
				state_next <= next_cmd;

			----------------------------------------------------------------
			-- ATOMIC → comando locale, 1 ciclo
			----------------------------------------------------------------
			when exec_atomic =>
				state_next <= next_cmd;

			----------------------------------------------------------------
			-- WAIT → multi‑ciclo
			----------------------------------------------------------------
			when exec_wait =>
				if s_wait_done = '1' then
					state_next <= next_cmd;
				else
					state_next <= exec_wait;
				end if;

			----------------------------------------------------------------
			-- BASE → READ / WRITE / CHECK (single beat)
			----------------------------------------------------------------
			when exec_base =>
				if s_ack_end = '1' then
					state_next <= next_cmd;
				else
					state_next <= exec_base;
				end if;

			----------------------------------------------------------------
			-- FIFO
			----------------------------------------------------------------
			when exec_fifo =>
				if s_ack_end = '1' then
					state_next <= next_cmd;
				else
					state_next <= exec_fifo;
				end if;

			----------------------------------------------------------------
			-- BURST
			----------------------------------------------------------------
			when exec_burst =>
				if s_ack_end = '1' then
					state_next <= next_cmd;
				else
					state_next <= exec_burst;
				end if;

			----------------------------------------------------------------
			-- WRAP
			----------------------------------------------------------------
			when exec_wrap =>
				if s_ack_end = '1' then
					state_next <= next_cmd;
				else
					state_next <= exec_wrap;
				end if;

			----------------------------------------------------------------
			-- FILL
			----------------------------------------------------------------
			when exec_fill =>
				if s_ack_end = '1' then
					state_next <= next_cmd;
				else
					state_next <= exec_fill;
				end if;

			----------------------------------------------------------------
			-- POLL → accettazione + risposta + completamento
			----------------------------------------------------------------
			when exec_poll =>

				-- 1) AXI_FULL ha prodotto la risposta dati
				if rsp_in.rsp_valid = '1' then

					-- 2) risposta completa (OKAY o errore)
					if s_ack_end = '1' then

						if s_poll_retry_next = '0' then
							state_next <= next_cmd;
						else
							state_next <= exec_poll_wait;
						end if;

					else
						state_next <= exec_poll;   -- aspetta fine comando
					end if;

				else
					state_next <= exec_poll;       -- aspetta rsp_valid
				end if;

			----------------------------------------------------------------
			-- POLL_WAIT → delay tra una req e l'altra
			----------------------------------------------------------------
			when exec_poll_wait =>
				if s_poll_delay_count >= s_mc_cur.wait_value then
					state_next <= exec_poll;
				else
					state_next <= exec_poll_wait;
				end if;

			----------------------------------------------------------------
			-- DUMP
			----------------------------------------------------------------
			when exec_dump =>
				if s_ack_end = '1' then
					state_next <= next_cmd;
				else
					state_next <= exec_dump;
				end if;

			----------------------------------------------------------------
			-- NEXT_CMD → esegui il microcomando corrente
			----------------------------------------------------------------
			when next_cmd =>

				if s_mc_index < s_mc_count then

					case s_mc_list(s_mc_index).cmd_type is

						when CMD_PRINT =>
							state_next <= exec_print;

						when CMD_SET_ATOMIC =>
							state_next <= exec_atomic;

						when CMD_WAIT_TIME |
							CMD_WAIT_CLOCKS |
							CMD_WAIT_SIM_TIME =>
							state_next <= exec_wait;

						when CMD_READ |
							CMD_WRITE |
							CMD_CHECK |
							CMD_WSTRB_WRITE =>
							state_next <= exec_base;

						when CMD_STOP =>
							state_next <= exec_stop;

						when CMD_FIFO_WRITE |
							CMD_FIFO_READ |
							CMD_FIFO_CHECK   =>
							state_next <= exec_fifo;

						when CMD_BURST_WRITE |
							CMD_BURST_READ |
							CMD_BURST_CHECK  =>
							state_next <= exec_burst;

						when CMD_WRAP_WRITE |
							CMD_WRAP_READ |
							CMD_WRAP_CHECK   =>
							state_next <= exec_wrap;

						when CMD_FILL_LEN |
							CMD_FILL_RANGE |
							CMD_FILL_CHECK   =>
							state_next <= exec_fill;

						when CMD_POLL_READ |
							CMD_POLL_TOGGLE |
							CMD_POLL_PING    =>
							state_next <= exec_poll;

						when CMD_DUMP_LEN |
							CMD_DUMP_RANGE |
							CMD_DUMP_FILE_LEN |
							CMD_DUMP_FILE_RANGE |
							CMD_DUMP_FILE_CHECK_LEN |
							CMD_DUMP_FILE_CHECK_RANGE =>
							state_next <= exec_dump;

						when CMD_END_SIM      =>
							state_next <= parse_file;

						when others           =>
							state_next <= idle;

					end case;

				else
					state_next <= parse_file;
				end if;

			----------------------------------------------------------------
			-- FINISHED
			----------------------------------------------------------------
			when finished =>
				state_next <= idle;

			----------------------------------------------------------------
			-- DEFAULT
			----------------------------------------------------------------
			when others =>
				state_next <= idle;

		end case;
	end process;



	--------------------------------------------------------------------
	-- GENERAZIONE CMD_VALID (richiesta comando AXI-like)
	--------------------------------------------------------------------
	process(clk, resetn)
	begin
		if resetn = '0' then
			s_cmd_valid <= '0';

		elsif rising_edge(clk) then

			----------------------------------------------------------------
			-- 1) Se AXI_FULL accetta il comando → cmd_valid = 0
			----------------------------------------------------------------
			if (s_cmd_valid = '1' and cmd_ready = '1') then
				s_cmd_valid <= '0';

			----------------------------------------------------------------
			-- 2) Se stiamo entrando in uno stato exec_* che richiede AXI
			--    → cmd_valid = 1 (impulso di richiesta comando)
			----------------------------------------------------------------
			elsif (state_current /= state_next) and
				(not s_dry_run) and
				(state_next = exec_base or
				state_next = exec_fifo or
				state_next = exec_burst or
				state_next = exec_wrap or
				state_next = exec_fill or
				state_next = exec_poll or
				state_next = exec_dump) then

				s_cmd_valid <= '1';

			end if;

		end if;
	end process;

	--------------------------------------------------------------------
	-- PROCESSO: LOGICA_COMBINATORIA_DI_USCITA (versione AXI-like)
	-- Genera solo i segnali verso AXI_FULL, nessuna logica di stato.
	--------------------------------------------------------------------
	process(
		state_current,
		s_mc_cur,
		s_data_index
	)
	begin
		----------------------------------------------------------------
		-- Default (parcheggio)
		----------------------------------------------------------------

		s_cmd_out.cmd_write      <= '0';
		s_cmd_out.cmd_burst      <= '0';
		s_cmd_out.cmd_wrap       <= '0';
		s_cmd_out.cmd_fifo       <= '0';
		s_cmd_out.cmd_atomic     <= s_atomic;

		s_cmd_out.cmd_id         <= s_mc_cur.cmd_id;
		s_cmd_out.cmd_addr       <= s_mc_cur.addr;
		s_cmd_out.cmd_len        <= s_mc_cur.len;
		s_cmd_out.cmd_data       <= s_mc_cur.data_array;

		s_cmd_out.cmd_wstrb      <= (others => '1');

		----------------------------------------------------------------
		-- Decodifica del comando corrente
		----------------------------------------------------------------
		case state_current is

			----------------------------------------------------------------
			-- PRINT / ATOMIC / WAIT → nessun accesso AXI
			----------------------------------------------------------------
			when exec_print | exec_atomic | exec_wait | exec_stop=>
				null;

			----------------------------------------------------------------
			-- BASE → READ / WRITE / CHECK / WSTRB_WRITE (single beat)
			----------------------------------------------------------------
			when exec_base =>

				-- WRITE / WSTRB_WRITE
				if s_mc_cur.cmd_type = CMD_WRITE or
				s_mc_cur.cmd_type = CMD_WSTRB_WRITE then
					s_cmd_out.cmd_write <= '1';
				else
					s_cmd_out.cmd_write <= '0';
				end if;

				-- ⭐ WSTRB
				if s_mc_cur.cmd_type = CMD_WSTRB_WRITE then
					s_cmd_out.cmd_wstrb <= std_logic_vector(
						to_unsigned(s_mc_cur.byte_enable, C_DATA_WIDTH/8)
					);
				else
					s_cmd_out.cmd_wstrb <= (others => '1');
				end if;

			----------------------------------------------------------------
			-- FIFO → multi-beat lineare
			----------------------------------------------------------------
			when exec_fifo =>

				if s_mc_cur.cmd_type = CMD_FIFO_WRITE then
					s_cmd_out.cmd_write <= '1';
				else
					s_cmd_out.cmd_write <= '0';
				end if;

				s_cmd_out.cmd_burst <= '1';
				s_cmd_out.cmd_wrap  <= '0';
				s_cmd_out.cmd_fifo  <= '1';

			----------------------------------------------------------------
			-- BURST → multi-beat lineare
			----------------------------------------------------------------
			when exec_burst =>

				if s_mc_cur.cmd_type = CMD_BURST_WRITE then
					s_cmd_out.cmd_write <= '1';
				else
					s_cmd_out.cmd_write <= '0';
				end if;

				s_cmd_out.cmd_burst <= '1';
				s_cmd_out.cmd_wrap  <= '0';

			----------------------------------------------------------------
			-- WRAP → multi-beat con indirizzi non lineari
			----------------------------------------------------------------
			when exec_wrap =>

				if s_mc_cur.cmd_type = CMD_WRAP_WRITE then
					s_cmd_out.cmd_write <= '1';
				else
					s_cmd_out.cmd_write <= '0';
				end if;

				s_cmd_out.cmd_burst <= '1';
				s_cmd_out.cmd_wrap  <= '1';

			----------------------------------------------------------------
			-- FILL → multi-beat con stesso dato
			----------------------------------------------------------------
			when exec_fill =>

				s_cmd_out.cmd_write <= '1';
				s_cmd_out.cmd_burst <= '1';
				s_cmd_out.cmd_wrap  <= '0';

			----------------------------------------------------------------
			-- POLL → read ripetuto
			----------------------------------------------------------------
			when exec_poll | exec_poll_wait =>

				s_cmd_out.cmd_write <= '0';
				s_cmd_out.cmd_burst <= '0';
				s_cmd_out.cmd_wrap  <= '0';

			----------------------------------------------------------------
			-- DUMP → read multi-beat
			----------------------------------------------------------------
			when exec_dump =>

				s_cmd_out.cmd_write <= '0';
				s_cmd_out.cmd_burst <= '1';
				s_cmd_out.cmd_wrap  <= '0';

			when others =>
				null;

		end case;
	end process;


	--------------------------------------------------------------------
	-- PROCESSO: LOGICA_SINCRONA_ATOMIC
	--------------------------------------------------------------------
	process(clk, resetn)
	begin
		if resetn = '0' then
			s_atomic <= '0';

		elsif rising_edge(clk) then

			if state_current = exec_atomic then
				s_atomic <= s_mc_cur.atomic;
			end if;

			-- NOTA: atomic NON si resetta negli altri stati
		end if;
	end process;


	--------------------------------------------------------------------
	-- PROCESSO: LOGICA_SINCRONA_WAIT
	--------------------------------------------------------------------
	process(clk, resetn)
	begin
		if resetn = '0' then
			s_wait_active  <= '0';
			s_wait_done    <= '0';
			s_wait_timeout <= '0';
			s_wait_count   <= (others => '0');

		elsif rising_edge(clk) then

			if state_current = exec_wait then

				if s_wait_active = '0' then
					-- avvio WAIT
					s_wait_active  <= '1';
					s_wait_done    <= '0';
					s_wait_timeout <= '0';
					s_wait_count   <= to_unsigned(s_mc_cur.wait_value, s_wait_count'length);

				else
					-- avanzamento WAIT
					if s_wait_count > 0 then
						s_wait_count <= s_wait_count - 1;
					else
						s_wait_done <= '1';
					end if;
				end if;

			else
				-- reset quando non siamo in exec_wait
				s_wait_active  <= '0';
				s_wait_done    <= '0';
				s_wait_timeout <= '0';
			end if;

		end if;
	end process;

	--------------------------------------------------------------------
	-- COMBINATORIO: s_poll_retry_next (versione AXI-like pulita)
	--------------------------------------------------------------------
	process(rsp_in, s_mc_cur, s_poll_last_value, s_poll_retry_count,
			s_ack_data, s_ack_data_last, s_ack_err, s_ack_end)
		variable mask_v          : std_logic_vector(C_DATA_WIDTH-1 downto 0);
		variable masked_v        : std_logic_vector(C_DATA_WIDTH-1 downto 0);
		variable expected_v      : std_logic_vector(C_DATA_WIDTH-1 downto 0);
		variable timeout_v       : natural;
		variable retry_next_v    : std_logic := '0';
		variable do_normal_logic : boolean := true;
	begin
		----------------------------------------------------------------
		-- Calcolo limite timeout
		----------------------------------------------------------------
		if s_mc_cur.timeout = 0 then
			timeout_v := C_MAX_TIMEOUT;
		else
			timeout_v := s_mc_cur.timeout;
		end if;

		retry_next_v    := '0';
		do_normal_logic := true;

		----------------------------------------------------------------
		-- 1) TIMEOUT (priorità assoluta)
		----------------------------------------------------------------
		if s_mc_cur.cmd_type = CMD_POLL_TOGGLE then
			-- TOGGLE: timeout = retry_count > timeout_v
			if s_poll_retry_count > timeout_v then
				retry_next_v    := '0';
				do_normal_logic := false;
			end if;
		else
			-- READ / PING: timeout = retry_count >= timeout_v
			if s_poll_retry_count >= timeout_v then
				retry_next_v    := '0';
				do_normal_logic := false;
			end if;
		end if;

		----------------------------------------------------------------
		-- 2) ERRORE AXI (seconda priorità)
		-- NON richiede rsp_valid
		----------------------------------------------------------------
		if do_normal_logic = true then
			if s_ack_err = '1' then   -- ⭐ usa segnale centralizzato

				if s_mc_cur.cmd_type = CMD_POLL_PING then
					retry_next_v := '1';   -- periferica non pronta → retry
				else
					retry_next_v := '0';   -- READ / TOGGLE → STOP immediato
				end if;

				do_normal_logic := false;
			end if;
		end if;

		----------------------------------------------------------------
		-- 3) NORMAL LOGIC (solo se non timeout e non errore)
		----------------------------------------------------------------
		if do_normal_logic = true then
			-- ⭐ AXI-like: ack = risposta completa (data OR err)
			-- ma per POLL serve anche rsp_valid (dati)
			if s_ack_end = '1' and rsp_in.rsp_valid = '1' then

				mask_v   := s_mc_cur.data_array(0);
				masked_v := rsp_in.rsp_data AND mask_v;

				----------------------------------------------------------------
				-- POLL_READ
				----------------------------------------------------------------
				if s_mc_cur.cmd_type = CMD_POLL_READ then
					expected_v := s_mc_cur.data AND mask_v;

					if masked_v /= expected_v then
						retry_next_v := '1';
					else
						retry_next_v := '0';
					end if;

				----------------------------------------------------------------
				-- POLL_TOGGLE
				----------------------------------------------------------------
				elsif s_mc_cur.cmd_type = CMD_POLL_TOGGLE then

					-- Prima lettura: cattura valore, retry forzato
					if s_poll_retry_count = 0 then
						retry_next_v := '1';

					-- Dalla seconda lettura in poi: verifica toggle
					elsif masked_v = s_poll_last_value then
						retry_next_v := '1';   -- NON ha togglato
					else
						retry_next_v := '0';   -- ha togglato → DONE
					end if;

				----------------------------------------------------------------
				-- POLL_PING
				----------------------------------------------------------------
				elsif s_mc_cur.cmd_type = CMD_POLL_PING then
					retry_next_v := '0';       -- risposta OK → DONE
				end if;
			end if;
		end if;

		----------------------------------------------------------------
		-- Uscita
		----------------------------------------------------------------
		s_poll_retry_next <= retry_next_v;
	end process;


	--------------------------------------------------------------------
	-- SINCRONO: registri POLL (versione AXI-like, con ACK centralizzato)
	--------------------------------------------------------------------
	process(clk, resetn)
		variable mask_v     : std_logic_vector(C_DATA_WIDTH-1 downto 0);
		variable expected_v : std_logic_vector(C_DATA_WIDTH-1 downto 0);
		variable masked_v   : std_logic_vector(C_DATA_WIDTH-1 downto 0);
		variable timeout_v  : natural;
	begin
		if resetn = '0' then

			s_poll_timeout      <= '0';
			s_poll_value        <= (others => '0');
			s_poll_masked_value <= (others => '0');
			s_poll_last_value   <= (others => '0');
			s_poll_retry_count  <= 0;
			s_poll_delay_count  <= 0;

		elsif rising_edge(clk) then

			----------------------------------------------------------------
			-- EXEC_POLL: gestione risposta
			----------------------------------------------------------------
			if state_current = exec_poll then

				-- Calcolo timeout
				if s_mc_cur.timeout = 0 then
					timeout_v := C_MAX_TIMEOUT;
				else
					timeout_v := s_mc_cur.timeout;
				end if;

				----------------------------------------------------------------
				-- Gestione risposta AXI valida/completa (solo dati)
				-- ⭐ usa s_ack_data al posto di ack ricostruito localmente
				----------------------------------------------------------------
				if s_ack_data = '1' then

					-- Valore letto grezzo
					s_poll_value <= rsp_in.rsp_data;

					-- Mask / expected / masked (READ/TOGGLE)
					mask_v     := s_mc_cur.data_array(0);
					expected_v := s_mc_cur.data AND mask_v;
					masked_v   := rsp_in.rsp_data AND mask_v;

					s_poll_masked_value <= masked_v;

					------------------------------------------------------------
					-- POLL_TOGGLE: gestione last_value
					------------------------------------------------------------
					if s_mc_cur.cmd_type = CMD_POLL_TOGGLE then
						-- Prima lettura: cattura valore di riferimento
						if s_poll_retry_count = 0 then
							s_poll_last_value <= masked_v;

						-- Dalla seconda lettura in poi:
						-- aggiorno last_value solo quando esco (toggle rilevato)
						elsif s_poll_retry_next = '0' then
							s_poll_last_value <= masked_v;
						end if;
					end if;

					----------------------------------------------------------------
					-- Incremento retry_count (READ / TOGGLE / PING)
					-- *** CORRETTO: incrementiamo SOLO quando retry_next = 1 ***
					----------------------------------------------------------------
					if s_mc_cur.cmd_type = CMD_POLL_TOGGLE then

						-- Prima lettura: retry_count = 0 → incrementa
						if s_poll_retry_count = 0 then
							s_poll_retry_count <= s_poll_retry_count + 1;
							s_poll_delay_count <= 0;

						-- Dalla seconda lettura in poi: incrementa se retry_next = 1
						elsif s_poll_retry_next = '1' then
							s_poll_retry_count <= s_poll_retry_count + 1;
							s_poll_delay_count <= 0;
						end if;

					else
						-- READ / PING: incrementiamo sempre quando retry_next=1
						if s_poll_retry_next = '1' then
							s_poll_retry_count <= s_poll_retry_count + 1;
							s_poll_delay_count <= 0;
						end if;
					end if;

				end if; -- fine gestione risposta completa (dati)

				----------------------------------------------------------------
				-- Timeout (diverso per TOGGLE) + errore di execution
				----------------------------------------------------------------
				if s_mc_cur.cmd_type = CMD_POLL_TOGGLE then
					-- timeout = retry_count > timeout_v → letture = timeout+1
					if s_poll_retry_count > timeout_v then
						-- segnala timeout solo la prima volta
						if s_poll_timeout = '0' then
							s_poll_timeout     <= '1';
							s_poll_error       <= true;
							s_poll_error_count <= s_poll_error_count + 1;
						end if;
					end if;
				else
					-- READ / PING: timeout = retry_count >= timeout_v → letture = timeout
					if s_poll_retry_count >= timeout_v then
						if s_poll_timeout = '0' then
							s_poll_timeout     <= '1';
							s_poll_error       <= true;
							s_poll_error_count <= s_poll_error_count + 1;
						end if;
					end if;
				end if;

			end if; -- exec_poll

			----------------------------------------------------------------
			-- EXEC_POLL_WAIT: gestione wait
			----------------------------------------------------------------
			if state_current = exec_poll_wait then
				if s_poll_delay_count < s_mc_cur.wait_value then
					s_poll_delay_count <= s_poll_delay_count + 1;
				end if;
			end if;

			----------------------------------------------------------------
			-- USCITA DAL POLL: reset registri
			----------------------------------------------------------------
			if state_current /= exec_poll and
			state_current /= exec_poll_wait then

				s_poll_timeout      <= '0';
				s_poll_value        <= (others => '0');
				s_poll_masked_value <= (others => '0');
				s_poll_last_value   <= (others => '0');
				s_poll_retry_count  <= 0;
				s_poll_delay_count  <= 0;

			end if;

		end if;
	end process;


	--------------------------------------------------------------------
	-- PROCESSO: LOGICA_SINCRONA_DATA_INDEX
	-- Gestisce l'indice del beat per comandi multi‑beat (FIFO/BURST/WRAP)
	--------------------------------------------------------------------
	process(clk, resetn)
	begin
		if resetn = '0' then
			s_data_index <= 0;

		elsif rising_edge(clk) then

			----------------------------------------------------------------
			-- Comandi multi‑beat: FIFO / BURST / WRAP / FILL / DUMP
			----------------------------------------------------------------
			if state_current = exec_fifo or
			state_current = exec_burst or
			state_current = exec_wrap or
			state_current = exec_fill or
			state_current = exec_dump then

				----------------------------------------------------------------
				-- Beat di dato consumato (risposta normale)
				-- ⭐ usa s_ack_data invece di rsp_valid/rsp_last
				----------------------------------------------------------------
				if s_ack_data = '1' then
					if rsp_in.rsp_last = '0' then
						s_data_index <= s_data_index + 1;
					else
						s_data_index <= 0;
					end if;
				end if;

				----------------------------------------------------------------
				-- Beat di errore consumato (sempre last)
				-- ⭐ usa s_ack_err invece di rsp_err_valid
				----------------------------------------------------------------
				if s_ack_err = '1' then
					s_data_index <= 0;
				end if;

			----------------------------------------------------------------
			-- Altri stati → reset dell’indice
			----------------------------------------------------------------
			else
				s_data_index <= 0;
			end if;

		end if;
	end process;

	--------------------------------------------------------------------
	-- PROCESSO: EXEC_DUMP_LOGIC
	-- Sequenziale, con reset asincrono attivo basso
	--------------------------------------------------------------------
	process(clk, resetn)
		-- Variabili locali
		variable v_dump_tag        : natural := 0;
		variable v_line            : t_line;
		variable line_str          : string(1 to C_MAX_STRING);
		variable file_addr_str     : string(1 to ADDR_STR_LEN);
		variable file_data_str     : string(1 to DATA_STR_LEN);
		variable expected_addr_str : string(1 to ADDR_STR_LEN);
		variable expected_data_str : string(1 to DATA_STR_LEN);
		variable addr_u            : unsigned(C_ADDR_WIDTH-1 downto 0);
		variable cur_addr_slv      : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
	begin
		----------------------------------------------------------------
		-- RESET ASINCRONO
		----------------------------------------------------------------
		if resetn = '0' then
			s_dump_open        <= '0';
			s_dump_tag         <= 0;

			-- ⭐ reset errori dump
			s_dump_error       <= false;
			s_dump_error_count <= 0;

		----------------------------------------------------------------
		-- LOGICA SINCRONA
		----------------------------------------------------------------
		elsif rising_edge(clk) then

			----------------------------------------------------------------
			-- Apertura file DUMP al primo beat
			----------------------------------------------------------------
			if state_current = exec_dump then

				if s_data_index = 0 and s_dump_open = '0' then

					-- DUMP_FILE → scrittura
					if s_mc_cur.cmd_type = CMD_DUMP_FILE_LEN or
					s_mc_cur.cmd_type = CMD_DUMP_FILE_RANGE then

						log_open_write(trim_string(s_mc_cur.filename), v_dump_tag);
						s_dump_tag  <= v_dump_tag;
						s_dump_open <= '1';

						if ENABLE_DEBUG_LOG then
							report "DUMP FILE OPENED (WRITE):" & trim_string(s_mc_cur.filename) &
								" (tag=" & integer'image(v_dump_tag) & ")" severity note;
						end if;

						log_write(
							s_log_tag,
							"DUMP FILE OPENED (WRITE):" & trim_string(s_mc_cur.filename) &
							" (tag=" & integer'image(v_dump_tag) & ")"
						);

					-- DUMP_FILE_CHECK → lettura
					elsif s_mc_cur.cmd_type = CMD_DUMP_FILE_CHECK_LEN or
						s_mc_cur.cmd_type = CMD_DUMP_FILE_CHECK_RANGE then

						log_open_read(trim_string(s_mc_cur.filename), v_dump_tag);
						s_dump_tag  <= v_dump_tag;
						s_dump_open <= '1';

						if ENABLE_DEBUG_LOG then
							report "DUMP FILE OPENED (READ):" & trim_string(s_mc_cur.filename) &
								" (tag=" & integer'image(v_dump_tag) & ")" severity note;
						end if;

						log_write(
							s_log_tag,
							"DUMP FILE OPENED (READ): " & trim_string(s_mc_cur.filename) &
							" (tag=" & integer'image(v_dump_tag) & ")"
						);

					end if;
				end if;

			end if;

			----------------------------------------------------------------
			-- HEADER stampato una sola volta
			----------------------------------------------------------------
			if state_current = exec_dump then
				-- ⭐ header solo quando il primo beat è completo
				if s_data_index = 0 and s_ack_data = '1' then

					if s_mc_cur.cmd_type = CMD_DUMP_LEN or
					s_mc_cur.cmd_type = CMD_DUMP_RANGE then

						log_write(
							s_log_tag,
							"DUMP: addr=0x" & slv_to_hex(s_mc_cur.addr) &
							" len=" & integer'image(s_mc_cur.len)
						);

					elsif s_mc_cur.cmd_type = CMD_DUMP_FILE_LEN or
						s_mc_cur.cmd_type = CMD_DUMP_FILE_RANGE then

						log_write(
							s_log_tag,
							"DUMP_FILE: addr=0x" & slv_to_hex(s_mc_cur.addr) &
							" len=" & integer'image(s_mc_cur.len)
						);

					elsif s_mc_cur.cmd_type = CMD_DUMP_FILE_CHECK_LEN or
						s_mc_cur.cmd_type = CMD_DUMP_FILE_CHECK_RANGE then

						log_write(
							s_log_tag,
							"DUMP_FILE_CHECK: addr=0x" & slv_to_hex(s_mc_cur.addr) &
							" len=" & integer'image(s_mc_cur.len)
						);

					end if;
				end if;
			end if;

			----------------------------------------------------------------
			-- BEAT-BY-BEAT
			----------------------------------------------------------------
			if state_current = exec_dump then
				-- ⭐ tutta la logica beat-by-beat è gated da s_ack_data
				if s_ack_data = '1' then

					----------------------------------------------------------------
					-- DUMP normale (solo LOG)
					----------------------------------------------------------------
					if s_mc_cur.cmd_type = CMD_DUMP_LEN or
					s_mc_cur.cmd_type = CMD_DUMP_RANGE then

						log_write(
							s_log_tag,
							LOG_INDENT &
							"beat=" & integer'image(s_data_index) &
							" data=0x" & slv_to_hex(rsp_in.rsp_data)
						);

					----------------------------------------------------------------
					-- DUMP_FILE → scrittura nel file + LOG
					----------------------------------------------------------------
					elsif s_mc_cur.cmd_type = CMD_DUMP_FILE_LEN or
						s_mc_cur.cmd_type = CMD_DUMP_FILE_RANGE then

						-- LOG
						log_write(
							s_log_tag,
							LOG_INDENT &
							"beat=" & integer'image(s_data_index) &
							" data=0x" & slv_to_hex(rsp_in.rsp_data)
						);

						-- FILE DUMP
						addr_u := unsigned(s_mc_cur.addr) + (s_data_index * (C_DATA_WIDTH/8));

						log_write(
							s_dump_tag,
							"0x" & slv_to_hex(std_logic_vector(addr_u)) &
							" 0x" & slv_to_hex(rsp_in.rsp_data)
						);

					----------------------------------------------------------------
					-- DUMP_FILE_CHECK → lettura + confronto + LOG
					----------------------------------------------------------------
					elsif s_mc_cur.cmd_type = CMD_DUMP_FILE_CHECK_LEN or
						s_mc_cur.cmd_type = CMD_DUMP_FILE_CHECK_RANGE then

						-- 1. Calcolo indirizzo corrente del beat
						addr_u       := unsigned(s_mc_cur.addr) + (s_data_index * (C_DATA_WIDTH/8));
						cur_addr_slv := std_logic_vector(addr_u);

						-- 2. Leggi una linea dal file
						log_read(s_dump_tag, v_line);

						-- Copia in stringa
						for i in 1 to C_MAX_STRING loop
							line_str(i) := v_line(i);
						end loop;

						-- 3. Parsing "0xADDR 0xDATA"
						file_addr_str := line_str(1 to ADDR_STR_LEN);
						file_data_str := line_str(ADDR_STR_LEN + 2 to ADDR_STR_LEN + 1 + DATA_STR_LEN);

						-- 4. Stringhe attese
						expected_addr_str := "0x" & slv_to_hex(cur_addr_slv);
						expected_data_str := "0x" & slv_to_hex(rsp_in.rsp_data);

						-- 5. Confronto
						if file_addr_str /= expected_addr_str then
							log_write(
								s_log_tag,
								LOG_INDENT &
								"beat=" & integer'image(s_data_index) &
								" addr=" & expected_addr_str &
								" data=" & expected_data_str &
								" RESULT=ADDR_ERROR exp_addr=" & file_addr_str &
								" exp_data=" & file_data_str
							);

							-- ⭐ errore di execution: indirizzo diverso
							s_dump_error       <= true;
							s_dump_error_count <= s_dump_error_count + 1;

						elsif file_data_str /= expected_data_str then
							log_write(
								s_log_tag,
								LOG_INDENT &
								"beat=" & integer'image(s_data_index) &
								" addr=" & expected_addr_str &
								" data=" & expected_data_str &
								" RESULT=DATA_ERROR exp_addr=" & file_addr_str &
								" exp_data=" & file_data_str
							);

							-- ⭐ errore di execution: dato diverso
							s_dump_error       <= true;
							s_dump_error_count <= s_dump_error_count + 1;

						else
							log_write(
								s_log_tag,
								LOG_INDENT &
								"beat=" & integer'image(s_data_index) &
								" addr=" & expected_addr_str &
								" data=" & expected_data_str &
								" RESULT=OK"
							);
						end if;

					end if;

				end if; -- s_ack_data = '1'
			end if;

			----------------------------------------------------------------
			-- Chiusura file DUMP
			----------------------------------------------------------------
			if state_current = exec_dump then
				-- ⭐ chiusura solo quando ultimo beat dati è completo
				if s_dump_open = '1' and s_ack_data = '1' and rsp_in.rsp_last = '1' then
					log_close(s_dump_tag);
					s_dump_open <= '0';

					if ENABLE_DEBUG_LOG then
						report "DUMP FILE CLOSED:" & trim_string(s_mc_cur.filename) &
							" (tag=" & integer'image(s_dump_tag) & ")" severity note;
					end if;

					log_write(
						s_log_tag,
						"DUMP FILE CLOSED: " & trim_string(s_mc_cur.filename) &
						" (tag=" & integer'image(s_dump_tag) & ")"
					);

				end if;
			end if;

		end if;
	end process;


	--------------------------------------------------------------------
	-- PROCESSO: LOGGING  (PRIMA PARTE)
	--------------------------------------------------------------------
	process(clk, resetn)
		variable v_log_tag     : natural := 0;
		variable read_val      : std_logic_vector(C_DATA_WIDTH-1 downto 0);
		variable expected_data : std_logic_vector(C_DATA_WIDTH-1 downto 0);
		variable v_line        : t_line;
		variable addr_u        : unsigned(C_ADDR_WIDTH-1 downto 0);

		variable line_str : string(1 to C_MAX_STRING);
		variable file_addr_str : string(1 to ADDR_STR_LEN);
		variable file_data_str : string(1 to DATA_STR_LEN);

		variable expected_addr_str : string(1 to ADDR_STR_LEN);
		variable expected_data_str : string(1 to DATA_STR_LEN);

		variable cur_addr_slv : std_logic_vector(C_ADDR_WIDTH-1 downto 0);

		variable timeout_v : integer;

		variable masked_v   : t_data;
		variable expected_v : t_data;

		variable v_exec_errors : natural;
		variable v_total_errors : natural;

		variable err_msg  : t_err_string;
		variable err_flag : boolean;

	begin
		if resetn = '0' then
			s_log_open <= '0';

		elsif rising_edge(clk) then

			----------------------------------------------------------------
			-- Apertura file LOG
			----------------------------------------------------------------
			if start = '1' and s_start = '0' then
				log_open("cmd.log", v_log_tag);
				s_log_tag  <= v_log_tag;
				s_log_open <= '1';

				if ENABLE_DEBUG_LOG then
					report "LOG: file cmd.log aperto correttamente (tag=" &
						integer'image(v_log_tag) & ")" severity note;
				end if;

				log_write(s_log_tag, "LOGGER STARTED");
			end if;

			----------------------------------------------------------------
			-- LOGGING NORMALE
			----------------------------------------------------------------
			case state_current is

				----------------------------------------------------------------
				-- PRINT
				----------------------------------------------------------------
				when exec_print =>
					log_write(s_log_tag, line_to_string(s_mc_cur.print_text));

				----------------------------------------------------------------
				-- WAIT
				----------------------------------------------------------------
				when exec_wait =>
					if s_wait_active = '1' and s_wait_done = '0' and
					s_wait_count = to_unsigned(s_mc_cur.wait_value, s_wait_count'length) then
						log_write(
							s_log_tag,
							"WAIT: value=" &
							integer'image(s_mc_cur.wait_value) &
							" unit=" & t_time_unit'image(s_mc_cur.wait_unit)
						);
					end if;

				----------------------------------------------------------------
				-- ATOMIC
				----------------------------------------------------------------
				when exec_atomic =>
					if s_mc_cur.atomic = s_atomic then
						log_write(
							s_log_tag,
							"SET_ATOMIC ERROR: new=" &
							std_logic'image(s_mc_cur.atomic) &
							" old=" & std_logic'image(s_atomic)
						);
					else
						if s_mc_cur.atomic = '1' then
							log_write(s_log_tag, "SET_ATOMIC ON");
						else
							log_write(s_log_tag, "SET_ATOMIC OFF");
						end if;
					end if;

				----------------------------------------------------------------
				-- BASE (READ / WRITE / CHECK) — versione AXI-like
				----------------------------------------------------------------
				when exec_base =>

					----------------------------------------------------------------
					-- RISPOSTA NORMALE (solo quando il beat è completo)
					-- ⭐ usa s_ack_data — log sempre
					----------------------------------------------------------------
					if s_ack_data = '1' then

						----------------------------------------------------------------
						-- READ
						----------------------------------------------------------------
						if s_mc_cur.cmd_type = CMD_READ then
							log_write(
								s_log_tag,
								"READ: addr=0x" & slv_to_hex(s_mc_cur.addr) &
								" data=0x" & slv_to_hex(rsp_in.rsp_data)
							);
						end if;

						----------------------------------------------------------------
						-- WRITE
						----------------------------------------------------------------
						if s_mc_cur.cmd_type = CMD_WRITE then

							if rsp_in.rsp_data = s_mc_cur.data_array(0) then
								log_write(
									s_log_tag,
									"WRITE: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" data=0x" & slv_to_hex(rsp_in.rsp_data) &
									" RESULT=OK"
								);
							else
								log_write(
									s_log_tag,
									"WRITE: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" data=0x" & slv_to_hex(rsp_in.rsp_data) &
									" RESULT=ERROR expected=0x" &
									slv_to_hex(s_mc_cur.data_array(0))
								);

								s_base_error       <= true;
								s_base_error_count <= s_base_error_count + 1;
							end if;

						end if;

						----------------------------------------------------------------
						-- WSTRB_WRITE
						----------------------------------------------------------------
						if s_mc_cur.cmd_type = CMD_WSTRB_WRITE then

							if rsp_in.rsp_data = s_mc_cur.data_array(0) then
								log_write(
									s_log_tag,
									"WSTRB_WRITE: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" data=0x" & slv_to_hex(rsp_in.rsp_data) &
									" wstrb=0x" & slv_to_hex(std_logic_vector(
										to_unsigned(s_mc_cur.byte_enable, C_DATA_WIDTH/8)
									)) &
									" RESULT=OK"
								);
							else
								log_write(
									s_log_tag,
									"WSTRB_WRITE: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" data=0x" & slv_to_hex(rsp_in.rsp_data) &
									" wstrb=0x" & slv_to_hex(std_logic_vector(
										to_unsigned(s_mc_cur.byte_enable, C_DATA_WIDTH/8)
									)) &
									" RESULT=ERROR expected=0x" &
									slv_to_hex(s_mc_cur.data_array(0))
								);

								s_base_error       <= true;
								s_base_error_count <= s_base_error_count + 1;
							end if;

						end if;
						----------------------------------------------------------------
						-- CHECK
						----------------------------------------------------------------
						if s_mc_cur.cmd_type = CMD_CHECK then

							read_val := rsp_in.rsp_data;

							if read_val = s_mc_cur.data_array(0) then
								log_write(
									s_log_tag,
									"CHECK: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" expected=0x" & slv_to_hex(s_mc_cur.data_array(0)) &
									" read=0x" & slv_to_hex(read_val) &
									" RESULT=OK"
								);
							else
								log_write(
									s_log_tag,
									"CHECK: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" expected=0x" & slv_to_hex(s_mc_cur.data_array(0)) &
									" read=0x" & slv_to_hex(read_val) &
									" RESULT=ERROR"
								);

								s_base_error       <= true;
								s_base_error_count <= s_base_error_count + 1;
							end if;
						end if;

					end if;  -- fine gestione s_ack_data


					----------------------------------------------------------------
					-- ERRORE AXI: SOLO se s_ack_err = '1'
					-- ⭐ usa decode_err() per msg + flag
					----------------------------------------------------------------
					if s_ack_err = '1' then

						-- decodifica errore tramite tabella
						decode_err(rsp_in.rsp_err_code, err_msg, err_flag);

						-- stampa errore AXI
						log_write(
							s_log_tag,
							"AXI ERROR: addr=0x" & slv_to_hex(s_mc_cur.addr) &
							" code=0x" & slv_to_hex(rsp_in.rsp_err_code) &
							" msg=" & err_msg
						);

						s_base_error       <= true;
						s_base_error_count <= s_base_error_count + 1;

					end if;

				when exec_stop =>
					log_write(s_log_tag, "STOP: simulazione terminata su comando STOP");
					report "STOP: simulazione terminata su comando STOP" severity note;

				----------------------------------------------------------------
				-- FIFO — versione AXI-like corretta
				----------------------------------------------------------------
				when exec_fifo =>

					----------------------------------------------------------------
					-- 1. RISPOSTA NORMALE (solo quando il beat è completo)
					--    ⭐ usa s_ack_data: logga SEMPRE il comando FIFO
					----------------------------------------------------------------
					if s_ack_data = '1' then

						----------------------------------------------------------------
						-- FIFO WRITE
						----------------------------------------------------------------
						if s_mc_cur.cmd_type = CMD_FIFO_WRITE then

							-- Header al primo beat
							if s_data_index = 0 then
								log_write(
									s_log_tag,
									"FIFO_WRITE: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" len=" & integer'image(s_mc_cur.len)
								);
							end if;

							expected_data := s_mc_cur.data_array(s_data_index);

							if rsp_in.rsp_data = expected_data then
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" wr_data=0x" & slv_to_hex(rsp_in.rsp_data) &
									" expected=0x" & slv_to_hex(expected_data) &
									" RESULT=OK"
								);
							else
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" wr_data=0x" & slv_to_hex(rsp_in.rsp_data) &
									" expected=0x" & slv_to_hex(expected_data) &
									" RESULT=ERROR"
								);

								s_fifo_error       <= true;
								s_fifo_error_count <= s_fifo_error_count + 1;
							end if;

						----------------------------------------------------------------
						-- FIFO READ
						----------------------------------------------------------------
						elsif s_mc_cur.cmd_type = CMD_FIFO_READ then

							if s_data_index = 0 then
								log_write(
									s_log_tag,
									"FIFO_READ: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" len=" & integer'image(s_mc_cur.len)
								);
							end if;

							log_write(
								s_log_tag,
								LOG_INDENT &
								"beat=" & integer'image(s_data_index) &
								" data=0x" & slv_to_hex(rsp_in.rsp_data)
							);

						----------------------------------------------------------------
						-- FIFO CHECK
						----------------------------------------------------------------
						elsif s_mc_cur.cmd_type = CMD_FIFO_CHECK then

							if s_data_index = 0 then
								log_write(
									s_log_tag,
									"FIFO_CHECK: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" len=" & integer'image(s_mc_cur.len)
								);
							end if;

							read_val      := rsp_in.rsp_data;
							expected_data := s_mc_cur.data_array(s_data_index);

							if read_val = expected_data then
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" expected=0x" & slv_to_hex(expected_data) &
									" read=0x" & slv_to_hex(read_val) &
									" RESULT=OK"
								);
							else
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" expected=0x" & slv_to_hex(expected_data) &
									" read=0x" & slv_to_hex(read_val) &
									" RESULT=ERROR"
								);

								s_fifo_error       <= true;
								s_fifo_error_count <= s_fifo_error_count + 1;
							end if;

						end if; -- fine tipo comando FIFO

					end if; -- fine gestione s_ack_data


					----------------------------------------------------------------
					-- 2. ERRORE AXI: SOLO se s_ack_err = '1'
					--    ⭐ usa decode_err() per msg + flag
					----------------------------------------------------------------
					if s_ack_err = '1' then

						-- decodifica errore tramite tabella
						decode_err(rsp_in.rsp_err_code, err_msg, err_flag);

						-- stampa errore AXI
						log_write(
							s_log_tag,
							"FIFO AXI ERROR: addr=0x" & slv_to_hex(s_mc_cur.addr) &
							" beat=" & integer'image(s_data_index) &
							" code=0x" & slv_to_hex(rsp_in.rsp_err_code) &
							" msg=" & err_msg
						);

						s_fifo_error       <= true;
						s_fifo_error_count <= s_fifo_error_count + 1;

					end if;



				----------------------------------------------------------------
				-- BURST — versione AXI-like corretta
				----------------------------------------------------------------
				when exec_burst =>

					----------------------------------------------------------------
					-- 1. RISPOSTA NORMALE (solo quando il beat è completo)
					--    ⭐ usa s_ack_data: logga SEMPRE il comando BURST
					----------------------------------------------------------------
					if s_ack_data = '1' then

						----------------------------------------------------------------
						-- BURST WRITE
						----------------------------------------------------------------
						if s_mc_cur.cmd_type = CMD_BURST_WRITE then

							-- Header al primo beat
							if s_data_index = 0 then
								log_write(
									s_log_tag,
									"BURST_WRITE: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" len=" & integer'image(s_mc_cur.len)
								);
							end if;

							expected_data := s_mc_cur.data_array(s_data_index);

							if rsp_in.rsp_data = expected_data then
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" data=0x" & slv_to_hex(rsp_in.rsp_data) &
									" expected=0x" & slv_to_hex(expected_data) &
									" RESULT=OK"
								);
							else
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" data=0x" & slv_to_hex(rsp_in.rsp_data) &
									" expected=0x" & slv_to_hex(expected_data) &
									" RESULT=ERROR"
								);

								s_burst_error       <= true;
								s_burst_error_count <= s_burst_error_count + 1;
							end if;

						----------------------------------------------------------------
						-- BURST READ
						----------------------------------------------------------------
						elsif s_mc_cur.cmd_type = CMD_BURST_READ then

							if s_data_index = 0 then
								log_write(
									s_log_tag,
									"BURST_READ: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" len=" & integer'image(s_mc_cur.len)
								);
							end if;

							log_write(
								s_log_tag,
								LOG_INDENT &
								"beat=" & integer'image(s_data_index) &
								" data=0x" & slv_to_hex(rsp_in.rsp_data)
							);

						----------------------------------------------------------------
						-- BURST CHECK
						----------------------------------------------------------------
						elsif s_mc_cur.cmd_type = CMD_BURST_CHECK then

							if s_data_index = 0 then
								log_write(
									s_log_tag,
									"BURST_CHECK: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" len=" & integer'image(s_mc_cur.len)
								);
							end if;

							read_val      := rsp_in.rsp_data;
							expected_data := s_mc_cur.data_array(s_data_index);

							if read_val = expected_data then
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" expected=0x" & slv_to_hex(expected_data) &
									" read=0x" & slv_to_hex(read_val) &
									" RESULT=OK"
								);
							else
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" expected=0x" & slv_to_hex(expected_data) &
									" read=0x" & slv_to_hex(read_val) &
									" RESULT=ERROR"
								);

								s_burst_error       <= true;
								s_burst_error_count <= s_burst_error_count + 1;
							end if;

						end if; -- fine tipo comando BURST

					end if; -- fine gestione s_ack_data


					----------------------------------------------------------------
					-- 2. ERRORE AXI: SOLO se s_ack_err = '1'
					--    ⭐ usa decode_err() per msg + flag
					----------------------------------------------------------------
					if s_ack_err = '1' then

						-- decodifica errore tramite tabella
						decode_err(rsp_in.rsp_err_code, err_msg, err_flag);

						-- stampa errore AXI
						log_write(
							s_log_tag,
							"BURST AXI ERROR: addr=0x" & slv_to_hex(s_mc_cur.addr) &
							" beat=" & integer'image(s_data_index) &
							" code=0x" & slv_to_hex(rsp_in.rsp_err_code) &
							" msg=" & err_msg
						);

						s_burst_error       <= true;
						s_burst_error_count <= s_burst_error_count + 1;

					end if;




				----------------------------------------------------------------
				-- WRAP — versione AXI-like corretta
				----------------------------------------------------------------
				when exec_wrap =>

					----------------------------------------------------------------
					-- 1. RISPOSTA NORMALE (solo quando il beat è completo)
					--    ⭐ usa s_ack_data: logga SEMPRE il comando WRAP
					----------------------------------------------------------------
					if s_ack_data = '1' then

						----------------------------------------------------------------
						-- WRAP WRITE
						----------------------------------------------------------------
						if s_mc_cur.cmd_type = CMD_WRAP_WRITE then

							-- Header al primo beat
							if s_data_index = 0 then
								log_write(
									s_log_tag,
									"WRAP_WRITE: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" len=" & integer'image(s_mc_cur.len)
								);
							end if;

							expected_data := s_mc_cur.data_array(s_data_index);

							if rsp_in.rsp_data = expected_data then
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" data=0x" & slv_to_hex(rsp_in.rsp_data) &
									" expected=0x" & slv_to_hex(expected_data) &
									" RESULT=OK"
								);
							else
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" data=0x" & slv_to_hex(rsp_in.rsp_data) &
									" expected=0x" & slv_to_hex(expected_data) &
									" RESULT=ERROR"
								);

								s_wrap_error       <= true;
								s_wrap_error_count <= s_wrap_error_count + 1;
							end if;

						----------------------------------------------------------------
						-- WRAP READ
						----------------------------------------------------------------
						elsif s_mc_cur.cmd_type = CMD_WRAP_READ then

							if s_data_index = 0 then
								log_write(
									s_log_tag,
									"WRAP_READ: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" len=" & integer'image(s_mc_cur.len)
								);
							end if;

							log_write(
								s_log_tag,
								LOG_INDENT &
								"beat=" & integer'image(s_data_index) &
								" data=0x" & slv_to_hex(rsp_in.rsp_data)
							);

						----------------------------------------------------------------
						-- WRAP CHECK
						----------------------------------------------------------------
						elsif s_mc_cur.cmd_type = CMD_WRAP_CHECK then

							if s_data_index = 0 then
								log_write(
									s_log_tag,
									"WRAP_CHECK: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" len=" & integer'image(s_mc_cur.len)
								);
							end if;

							read_val      := rsp_in.rsp_data;
							expected_data := s_mc_cur.data_array(s_data_index);

							if read_val = expected_data then
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" expected=0x" & slv_to_hex(expected_data) &
									" read=0x" & slv_to_hex(read_val) &
									" RESULT=OK"
								);
							else
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" expected=0x" & slv_to_hex(expected_data) &
									" read=0x" & slv_to_hex(read_val) &
									" RESULT=ERROR"
								);

								s_wrap_error       <= true;
								s_wrap_error_count <= s_wrap_error_count + 1;
							end if;

						end if; -- fine tipo comando WRAP

					end if; -- fine gestione s_ack_data


					----------------------------------------------------------------
					-- 2. ERRORE AXI: SOLO se s_ack_err = '1'
					--    ⭐ usa decode_err() per msg + flag
					----------------------------------------------------------------
					if s_ack_err = '1' then

						-- decodifica errore tramite tabella
						decode_err(rsp_in.rsp_err_code, err_msg, err_flag);

						-- stampa errore AXI
						log_write(
							s_log_tag,
							"WRAP AXI ERROR: addr=0x" & slv_to_hex(s_mc_cur.addr) &
							" beat=" & integer'image(s_data_index) &
							" code=0x" & slv_to_hex(rsp_in.rsp_err_code) &
							" msg=" & err_msg
						);

						s_wrap_error       <= true;
						s_wrap_error_count <= s_wrap_error_count + 1;

					end if;




				----------------------------------------------------------------
				-- FILL — versione AXI-like corretta
				----------------------------------------------------------------
				when exec_fill =>

					----------------------------------------------------------------
					-- 1. RISPOSTA NORMALE (solo quando il beat è completo)
					--    ⭐ usa s_ack_data: logga SEMPRE il comando FILL
					----------------------------------------------------------------
					if s_ack_data = '1' then

						----------------------------------------------------------------
						-- FILL WRITE (LEN / RANGE)
						----------------------------------------------------------------
						if s_mc_cur.cmd_type = CMD_FILL_LEN or
						s_mc_cur.cmd_type = CMD_FILL_RANGE then

							-- Header al primo beat
							if s_data_index = 0 then
								log_write(
									s_log_tag,
									"FILL_WRITE: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" len=" & integer'image(s_mc_cur.len)
								);
							end if;

							expected_data := s_mc_cur.data_array(0);

							if rsp_in.rsp_data = expected_data then
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" data=0x" & slv_to_hex(rsp_in.rsp_data) &
									" RESULT=OK"
								);
							else
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" data=0x" & slv_to_hex(rsp_in.rsp_data) &
									" expected=0x" & slv_to_hex(expected_data) &
									" RESULT=ERROR"
								);

								s_fill_error       <= true;
								s_fill_error_count <= s_fill_error_count + 1;
							end if;

						----------------------------------------------------------------
						-- FILL CHECK
						----------------------------------------------------------------
						elsif s_mc_cur.cmd_type = CMD_FILL_CHECK then

							-- Header al primo beat
							if s_data_index = 0 then
								log_write(
									s_log_tag,
									"FILL_CHECK: addr=0x" & slv_to_hex(s_mc_cur.addr) &
									" len=" & integer'image(s_mc_cur.len)
								);
							end if;

							read_val      := rsp_in.rsp_data;
							expected_data := s_mc_cur.data_array(0);

							if read_val = expected_data then
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" expected=0x" & slv_to_hex(expected_data) &
									" read=0x" & slv_to_hex(read_val) &
									" RESULT=OK"
								);
							else
								log_write(
									s_log_tag,
									LOG_INDENT &
									"beat=" & integer'image(s_data_index) &
									" expected=0x" & slv_to_hex(expected_data) &
									" read=0x" & slv_to_hex(read_val) &
									" RESULT=ERROR"
								);

								s_fill_error       <= true;
								s_fill_error_count <= s_fill_error_count + 1;
							end if;

						end if; -- fine tipo comando FILL

					end if; -- fine gestione s_ack_data


					----------------------------------------------------------------
					-- 2. ERRORE AXI: SOLO se s_ack_err = '1'
					--    ⭐ usa decode_err() per msg + flag
					----------------------------------------------------------------
					if s_ack_err = '1' then

						-- decodifica errore tramite tabella
						decode_err(rsp_in.rsp_err_code, err_msg, err_flag);

						log_write(
							s_log_tag,
							"FILL AXI ERROR: addr=0x" & slv_to_hex(s_mc_cur.addr) &
							" beat=" & integer'image(s_data_index) &
							" code=0x" & slv_to_hex(rsp_in.rsp_err_code) &
							" msg=" & err_msg
						);

						s_fill_error       <= true;
						s_fill_error_count <= s_fill_error_count + 1;

					end if;




				----------------------------------------------------------------
				-- POLL (LOGGING) — versione AXI-like corretta
				----------------------------------------------------------------
				when exec_poll =>

					----------------------------------------------------------------
					-- Calcolo timeout (solo per header)
					----------------------------------------------------------------
					if s_mc_cur.timeout = 0 then
						timeout_v := C_MAX_TIMEOUT;
					else
						timeout_v := s_mc_cur.timeout;
					end if;

					----------------------------------------------------------------
					-- HEADER COMANDO POLL (una sola volta, al primo beat)
					-- ⭐ usa s_ack_data invece di ack ricostruito
					----------------------------------------------------------------
					if s_ack_data = '1' and s_poll_retry_count = 0 then

						if s_mc_cur.cmd_type = CMD_POLL_READ then
							log_write(
								s_log_tag,
								"POLL_READ: addr=0x" & slv_to_hex(s_mc_cur.addr) &
								" data=0x" & slv_to_hex(s_mc_cur.data) &
								" mask=0x" & slv_to_hex(s_mc_cur.data_array(0)) &
								" wait=" & integer'image(s_mc_cur.wait_value) &
								" timeout=" & integer'image(timeout_v)
							);

						elsif s_mc_cur.cmd_type = CMD_POLL_TOGGLE then
							log_write(
								s_log_tag,
								"POLL_TOGGLE: addr=0x" & slv_to_hex(s_mc_cur.addr) &
								" mask=0x" & slv_to_hex(s_mc_cur.data_array(0)) &
								" wait=" & integer'image(s_mc_cur.wait_value) &
								" timeout=" & integer'image(timeout_v)
							);

						elsif s_mc_cur.cmd_type = CMD_POLL_PING then
							log_write(
								s_log_tag,
								"POLL_PING: addr=0x" & slv_to_hex(s_mc_cur.addr) &
								" wait=" & integer'image(s_mc_cur.wait_value) &
								" timeout=" & integer'image(timeout_v)
							);
						end if;
					end if;

					----------------------------------------------------------------
					-- AXI ERROR (READ / TOGGLE) → solo log
					-- ⭐ usa decode_err()
					----------------------------------------------------------------
					if s_ack_err = '1' and s_mc_cur.cmd_type /= CMD_POLL_PING then

						-- decodifica errore
						decode_err(rsp_in.rsp_err_code, err_msg, err_flag);

						log_write(
							s_log_tag,
							LOG_INDENT &
							"AXI_ERROR: code=0x" & slv_to_hex(rsp_in.rsp_err_code) &
							" msg=" & err_msg
						);
					end if;

					----------------------------------------------------------------
					-- POLL_READ: stampa RSP
					-- ⭐ usa s_ack_data
					----------------------------------------------------------------
					if s_ack_data = '1' and s_mc_cur.cmd_type = CMD_POLL_READ then

						masked_v   := rsp_in.rsp_data AND s_mc_cur.data_array(0);
						expected_v := s_mc_cur.data AND s_mc_cur.data_array(0);

						if s_poll_timeout = '1' then
							log_write(
								s_log_tag,
								LOG_INDENT &
								"RSP: value=0x" & slv_to_hex(rsp_in.rsp_data) &
								" masked=0x" & slv_to_hex(masked_v) &
								" expected=0x" & slv_to_hex(expected_v) &
								" TIMEOUT"
							);
						elsif s_poll_retry_next = '1' then
							log_write(
								s_log_tag,
								LOG_INDENT &
								"RSP: value=0x" & slv_to_hex(rsp_in.rsp_data) &
								" masked=0x" & slv_to_hex(masked_v) &
								" expected=0x" & slv_to_hex(expected_v) &
								" RETRY"
							);
						else
							log_write(
								s_log_tag,
								LOG_INDENT &
								"RSP: value=0x" & slv_to_hex(rsp_in.rsp_data) &
								" masked=0x" & slv_to_hex(masked_v) &
								" expected=0x" & slv_to_hex(expected_v) &
								" DONE"
							);
						end if;
					end if;

					----------------------------------------------------------------
					-- POLL_TOGGLE: stampa RSP
					-- ⭐ usa s_ack_data
					----------------------------------------------------------------
					if s_ack_data = '1' and s_mc_cur.cmd_type = CMD_POLL_TOGGLE then

						masked_v   := rsp_in.rsp_data AND s_mc_cur.data_array(0);
						expected_v := s_poll_last_value AND s_mc_cur.data_array(0);

						if s_poll_timeout = '1' then
							log_write(
								s_log_tag,
								LOG_INDENT &
								"RSP: value=0x" & slv_to_hex(rsp_in.rsp_data) &
								" masked=0x" & slv_to_hex(masked_v) &
								" TIMEOUT"
							);
						elsif s_poll_retry_next = '1' then
							log_write(
								s_log_tag,
								LOG_INDENT &
								"RSP: value=0x" & slv_to_hex(rsp_in.rsp_data) &
								" masked=0x" & slv_to_hex(masked_v) &
								" RETRY"
							);
						else
							log_write(
								s_log_tag,
								LOG_INDENT &
								"RSP: value=0x" & slv_to_hex(rsp_in.rsp_data) &
								" masked=0x" & slv_to_hex(masked_v) &
								" DONE"
							);
						end if;
					end if;

					----------------------------------------------------------------
					-- POLL_PING: periferica NON pronta
					-- ⭐ usa s_ack_err
					----------------------------------------------------------------
					if s_ack_err = '1' and s_mc_cur.cmd_type = CMD_POLL_PING then

						if s_poll_timeout = '1' then
							log_write(
								s_log_tag,
								LOG_INDENT &
								"RSP: Peripheral NOT ready (TIMEOUT)"
							);
						else
							log_write(
								s_log_tag,
								LOG_INDENT &
								"RSP: Peripheral NOT ready (RETRY)"
							);
						end if;
					end if;

					----------------------------------------------------------------
					-- POLL_PING: periferica pronta
					-- ⭐ usa s_ack_data
					----------------------------------------------------------------
					if s_ack_data = '1' and s_mc_cur.cmd_type = CMD_POLL_PING then
						if s_poll_retry_next = '0' and s_poll_timeout = '0' then
							log_write(
								s_log_tag,
								LOG_INDENT &
								"RSP: Peripheral ready (DONE)"
							);
						end if;
					end if;




				----------------------------------------------------------------
				-- FINISHED
				----------------------------------------------------------------
				when finished =>
					----------------------------------------------------------------
					-- CONSOLE SUMMARY
					----------------------------------------------------------------
					v_exec_errors :=
						s_base_error_count
						+ s_fifo_error_count
						+ s_burst_error_count
						+ s_wrap_error_count
						+ s_fill_error_count
						+ s_poll_error_count
						+ s_dump_error_count
						+ s_axi_error_count;

					v_total_errors := s_parse_error_count + v_exec_errors;

					report "==================== SIMULATION SUMMARY ====================" severity note;

					report "  PARSE errors:       " & integer'image(s_parse_error_count) severity note;
					report "  BASE errors:        " & integer'image(s_base_error_count) severity note;
					report "  FIFO errors:        " & integer'image(s_fifo_error_count) severity note;
					report "  BURST errors:       " & integer'image(s_burst_error_count) severity note;
					report "  WRAP errors:        " & integer'image(s_wrap_error_count) severity note;
					report "  FILL errors:        " & integer'image(s_fill_error_count) severity note;
					report "  POLL errors:        " & integer'image(s_poll_error_count) severity note;
					report "  DUMP errors:        " & integer'image(s_dump_error_count) severity note;
					report "  AXI errors:         " & integer'image(s_axi_error_count) severity note;

					report "  TOTAL EXEC ERRORS = " & integer'image(v_exec_errors) severity note;
					report "  TOTAL ERRORS      = " & integer'image(v_total_errors) severity note;

					if s_mc_cur.cmd_type = CMD_STOP then
						report "STOP command executed: simulation terminated by user command" severity note;
					end if;

					if v_total_errors = 0 then
						report "SIMULATION RESULT: OK" severity note;
					else
						report "SIMULATION RESULT: FAIL" severity error;
					end if;

					report "============================================================" severity note;

					----------------------------------------------------------------
					-- LOG SUMMARY
					----------------------------------------------------------------
					if s_log_open = '1' then

						log_write(s_log_tag, "SIMULATION SUMMARY:");

						log_write(s_log_tag, "  PARSE errors:       " & integer'image(s_parse_error_count));
						log_write(s_log_tag, "  BASE errors:        " & integer'image(s_base_error_count));
						log_write(s_log_tag, "  FIFO errors:        " & integer'image(s_fifo_error_count));
						log_write(s_log_tag, "  BURST errors:       " & integer'image(s_burst_error_count));
						log_write(s_log_tag, "  WRAP errors:        " & integer'image(s_wrap_error_count));
						log_write(s_log_tag, "  FILL errors:        " & integer'image(s_fill_error_count));
						log_write(s_log_tag, "  POLL errors:        " & integer'image(s_poll_error_count));
						log_write(s_log_tag, "  DUMP errors:        " & integer'image(s_dump_error_count));
						log_write(s_log_tag, "  AXI errors:         " & integer'image(s_axi_error_count));

						log_write(s_log_tag, "TOTAL EXEC ERRORS = " & integer'image(v_exec_errors));
						s_exec_error_count <= v_exec_errors;
						s_exec_error       <= (v_exec_errors > 0);

						log_write(s_log_tag, "TOTAL ERRORS = " & integer'image(v_total_errors));
						s_error_count <= v_total_errors;
						s_error       <= (v_total_errors > 0);

						if s_mc_cur.cmd_type = CMD_STOP then
							log_write(s_log_tag, "STOP: simulation terminated by user command");
						end if;

						----------------------------------------------------------------
						-- RISULTATO SIMULAZIONE (OK/FAIL)
						----------------------------------------------------------------
						if v_total_errors = 0 then
							log_write(s_log_tag, "SIMULATION RESULT: OK");
						else
							log_write(s_log_tag, "SIMULATION RESULT: FAIL");
						end if;

						----------------------------------------------------------------
						-- CHIUSURA LOG
						----------------------------------------------------------------
						log_write(s_log_tag, "SIMULATION FINISHED");

						log_close(s_log_tag);
						s_log_open <= '0';
					end if;

				when exec_dump =>
					null;

				----------------------------------------------------------------
				-- OTHERS → AXI ERROR (solo logging)
				----------------------------------------------------------------
				when others =>
					if s_log_open = '1' then
						if rsp_in.rsp_err_valid = '1' then

							-- decodifica errore tramite tabella
							decode_err(rsp_in.rsp_err_code, err_msg, err_flag);

							log_write(
								s_log_tag,
								"AXI_ERROR: id=" &
								integer'image(to_integer(unsigned(rsp_in.rsp_err_id))) &
								" code=0x" & slv_to_hex(rsp_in.rsp_err_code) &
								" msg=" & err_msg
							);

							-- ⭐ errore execution
							s_axi_error       <= true;
							s_axi_error_count <= s_axi_error_count + 1;
						end if;
					end if;

			end case;

		end if;
	end process;


end architecture;

