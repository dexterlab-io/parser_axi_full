-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_parse_pkg.vhd
--  Author: Dexter
--  Date: 2026-09-06
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmd_cfg.all;
use work.cmd_cmd_pkg.all;
use work.cmd_text_pkg.all;
use work.cmd_lex_pkg.all;
use work.cmd_eval_pkg.all;
use work.cmd_map_pkg.all;
use work.cmd_math_pkg.all;
use work.cmd_time_pkg.all;
use work.cmd_vars_pkg.all;

package cmd_parse_pkg is

    procedure parse_line(
        line            : in  t_line;
        cmd             : inout t_cmd;
        parse_error     : inout boolean;
        continue_flag   : out boolean;
        suppress_start  : in  boolean;
        tokens_acc      : inout token_acc_list_t;
        nt_acc          : inout natural
    );

    --------------------------------------------------------------------
    -- BASE
    --------------------------------------------------------------------
    procedure parse_base(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

	--------------------------------------------------------------------
	-- WSTRB_WRITE
	--------------------------------------------------------------------
	procedure parse_wstrb_write(
		tokens      : in  token_acc_list_t;
		nt          : in  natural;
		cmd         : inout t_cmd;
		parse_error : inout boolean
	);

	--------------------------------------------------------------------
	-- STOP
	--------------------------------------------------------------------
	procedure parse_stop(
		tokens      : in  token_acc_list_t;
		nt          : in  natural;
		cmd         : inout t_cmd;
		parse_error : inout boolean
	);

	--------------------------------------------------------------------
    -- SET VAR
    --------------------------------------------------------------------
    procedure parse_set_var(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- SET ATOMIC
    --------------------------------------------------------------------
    procedure parse_set_atomic(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- INCLUDE
    --------------------------------------------------------------------
    procedure parse_include(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- END_SIM
    --------------------------------------------------------------------
    procedure parse_end_sim(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- PRINT
    --------------------------------------------------------------------
    procedure parse_print(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- WAIT CLOCKS
    --------------------------------------------------------------------
    procedure parse_wait_clocks(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- WAIT TIME
    --------------------------------------------------------------------
    procedure parse_wait_time(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- WAIT SIM TIME
    --------------------------------------------------------------------
    procedure parse_wait_sim_time(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- FIFO
    --------------------------------------------------------------------
    procedure parse_fifo(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- BURST
    --------------------------------------------------------------------
    procedure parse_burst(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- WRAP
    --------------------------------------------------------------------
    procedure parse_wrap(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- FILL
    --------------------------------------------------------------------
    procedure parse_fill(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- DUMP
    --------------------------------------------------------------------
    procedure parse_dump(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- POLL READ
    --------------------------------------------------------------------
    procedure parse_poll_read(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- POLL TOGGLE
    --------------------------------------------------------------------
    procedure parse_poll_toggle(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

    --------------------------------------------------------------------
    -- POLL PING
    --------------------------------------------------------------------
    procedure parse_poll_ping(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    );

end package cmd_parse_pkg;

package body cmd_parse_pkg is

    --------------------------------------------------------------------
    -- Parse line: interpreta token semantici
    --------------------------------------------------------------------
    procedure parse_line(
        line            : in  t_line;
        cmd             : inout t_cmd;
        parse_error     : inout boolean;
        continue_flag   : out boolean;
        suppress_start  : in  boolean;
        tokens_acc      : inout token_acc_list_t;
        nt_acc          : inout natural
    ) is
        variable tokens : token_list_t;
        variable nt     : natural;
        variable cf     : boolean;

        procedure dump_parse_token(i : natural; t : t_token) is
        begin
			if ENABLE_DEBUG_LOG then
				report "PARSE TOK " & integer'image(i) &
					": " & t_token_kind'image(t.kind) &
					" """ & trim_string(t.text) & """";
			end if;
        end procedure;

    begin
        parse_error   := false;
        continue_flag := false;

        --------------------------------------------------------------------
        -- 1. Tokenize la riga corrente
        --------------------------------------------------------------------
        tokenize_semantic(line, tokens, nt, cf, suppress_start);

        --------------------------------------------------------------------
        -- 2. Accumula i token nel buffer del comando
        --------------------------------------------------------------------
        for i in 1 to nt loop
            nt_acc := nt_acc + 1;
            tokens_acc(nt_acc) := tokens(i);
        end loop;

        --------------------------------------------------------------------
        -- 3. Se la riga termina con "\" → comando non completo
        --------------------------------------------------------------------
        if cf then
            continue_flag := true;
            return;
        end if;

        --------------------------------------------------------------------
        -- 4. Comando completo → parse dei token accumulati
        --------------------------------------------------------------------
        if nt_acc < 2 then
            parse_error := true;
            return;
        end if;

        --------------------------------------------------------------------
        -- 5. Decodifica comando
        --------------------------------------------------------------------
        cmd.command := decode_command(tokens_acc(2).text);

        if cmd.command = CMD_UNKNOWN then
            parse_error := true;
            return;
        end if;

        --------------------------------------------------------------------
        -- 6. Debug token
        --------------------------------------------------------------------
        for i in 1 to nt_acc loop
            dump_parse_token(i, tokens_acc(i));
        end loop;

		--------------------------------------------------------------------
		-- 7. Dispatch
		--------------------------------------------------------------------
		case cmd.command is

			when CMD_WRITE | CMD_READ | CMD_CHECK =>
				parse_base(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_SET_VAR =>
				parse_set_var(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_SET_ATOMIC =>
				parse_set_atomic(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_INCLUDE =>
				parse_include(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_END_SIM =>
				parse_end_sim(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_PRINT =>
				parse_print(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_WAIT_TIME =>
				parse_wait_time(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_WAIT_CLOCKS =>
				parse_wait_clocks(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_WAIT_SIM_TIME =>
				parse_wait_sim_time(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_POLL_READ =>
				parse_poll_read(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_POLL_TOGGLE =>
				parse_poll_toggle(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_POLL_PING =>
				parse_poll_ping(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_FIFO_WRITE | CMD_FIFO_READ | CMD_FIFO_CHECK =>
				parse_fifo(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_BURST_WRITE | CMD_BURST_READ | CMD_BURST_CHECK =>
				parse_burst(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_WRAP_WRITE | CMD_WRAP_READ | CMD_WRAP_CHECK =>
				parse_wrap(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_FILL_LEN | CMD_FILL_RANGE | CMD_FILL_CHECK =>
				parse_fill(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_DUMP_LEN | CMD_DUMP_RANGE |
				CMD_DUMP_FILE_LEN | CMD_DUMP_FILE_RANGE |
				CMD_DUMP_FILE_CHECK_LEN | CMD_DUMP_FILE_CHECK_RANGE =>
				parse_dump(tokens_acc, nt_acc, cmd, parse_error);

			----------------------------------------------------------------
			-- ⭐ NUOVI COMANDI
			----------------------------------------------------------------
			when CMD_WSTRB_WRITE =>
				parse_wstrb_write(tokens_acc, nt_acc, cmd, parse_error);

			when CMD_STOP =>
				parse_stop(tokens_acc, nt_acc, cmd, parse_error);

			----------------------------------------------------------------
			-- Errore
			----------------------------------------------------------------
			when others =>
				parse_error := true;

		end case;


    end procedure;

	--------------------------------------------------------------------
	-- WSTRB_WRITE
	-- CMD_WSTRB_WRITE <addr_expr> [+ offset] <data_expr> <byte_enable>
	--------------------------------------------------------------------
	procedure parse_wstrb_write(
		tokens      : in  token_acc_list_t;
		nt          : in  natural;
		cmd         : inout t_cmd;
		parse_error : inout boolean
	) is
		variable idx         : natural := 3;  -- dopo TK_START e comando
		variable addr_val_u  : unsigned(C_ADDR_WIDTH-1 downto 0);
		variable data_val_u  : unsigned(C_DATA_WIDTH-1 downto 0);
		variable addr_val    : t_addr := (others => '0');
		variable offset_val  : integer := 0;
		variable data_val    : t_data := (others => '0');
		variable wstrb_val   : natural := 0;
	begin
		parse_error := false;

		--------------------------------------------------------------------
		-- 1. Indirizzo (obbligatorio)
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE WSTRB_WRITE ERROR: missing address" severity error;
			parse_error := true;
			return;
		end if;

		eval_addr_u(tokens(idx).text, addr_val_u, parse_error);
		if parse_error then
			report "PARSE WSTRB_WRITE ERROR: invalid address expression" severity error;
			return;
		end if;

		addr_val := std_logic_vector(addr_val_u);
		idx := idx + 1;

		--------------------------------------------------------------------
		-- 2. Offset (opzionale)
		--------------------------------------------------------------------
		if idx <= nt then
			if trim_string(tokens(idx).text) = "+" then
				idx := idx + 1;

				if idx > nt or tokens(idx).kind = TK_END then
					report "PARSE WSTRB_WRITE ERROR: missing offset value" severity error;
					parse_error := true;
					return;
				end if;

				eval_expr_i(tokens(idx).text, offset_val, parse_error);
				if parse_error then
					report "PARSE WSTRB_WRITE ERROR: invalid offset expression" severity error;
					return;
				end if;

				idx := idx + 1;
			end if;
		end if;

		--------------------------------------------------------------------
		-- 3. Dato (obbligatorio)
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind /= TK_NUMBER then
			report "PARSE WSTRB_WRITE ERROR: missing data" severity error;
			parse_error := true;
			return;
		end if;

		eval_data_u(tokens(idx).text, data_val_u, parse_error);
		if parse_error then
			report "PARSE WSTRB_WRITE ERROR: invalid data expression" severity error;
			return;
		end if;

		data_val := std_logic_vector(data_val_u);
		idx := idx + 1;

		--------------------------------------------------------------------
		-- 4. Byte enable (obbligatorio)
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind /= TK_NUMBER then
			report "PARSE WSTRB_WRITE ERROR: missing byte_enable" severity error;
			parse_error := true;
			return;
		end if;

		eval_expr_i(tokens(idx).text, wstrb_val, parse_error);
		if parse_error then
			report "PARSE WSTRB_WRITE ERROR: invalid byte_enable expression" severity error;
			return;
		end if;

		--------------------------------------------------------------------
		-- 5. Assegna i valori al comando
		--------------------------------------------------------------------
		cmd.addr        := addr_val;
		cmd.offset      := offset_val;
		cmd.data        := data_val;
		cmd.byte_enable := wstrb_val;
		cmd.len         := 1;  -- sempre singola write

		--------------------------------------------------------------------
		-- 6. Parametri per semantic_check
		--------------------------------------------------------------------
		cmd.param_count := 3;
		cmd.param_kind(1) := PK_ADDR;
		cmd.param_kind(2) := PK_DATA;
		cmd.param_kind(3) := PK_LEN;

		cmd.wrap_size := 0;

		--------------------------------------------------------------------
		-- 7. Debug
		--------------------------------------------------------------------
		if ENABLE_DEBUG_LOG then
			report "PARSE WSTRB_WRITE: addr=0x" & slv_to_hex(cmd.addr) &
				" offset=" & integer'image(cmd.offset) &
				" data=0x" & slv_to_hex(cmd.data) &
				" wstrb=" & integer'image(cmd.byte_enable);
		end if;

	end procedure;

	--------------------------------------------------------------------
	-- STOP
	--------------------------------------------------------------------
	procedure parse_stop(
		tokens      : in  token_acc_list_t;
		nt          : in  natural;
		cmd         : inout t_cmd;
		parse_error : inout boolean
	) is
	begin
		-- CMD_STOP non ha parametri
		if nt /= 3 then
			parse_error := true;
			report "PARSE ERROR: CMD_STOP takes no parameters" severity error;
			return;
		end if;

		-- Nessun campo da impostare
		if ENABLE_DEBUG_LOG then
			report "PARSE STOP";
		end if;
	end procedure;

    ----------------------------------------------------------------
    -- parse_base: WRITE / READ / CHECK
    -- WRITE <addr_expr> [+ offset] <data_expr>
    -- READ  <addr_expr> [+ offset]
    -- CHECK <addr_expr> [+ offset] <expected_expr>
    ----------------------------------------------------------------
    procedure parse_base(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    ) is
        variable idx        : natural := 3;  -- dopo TK_START e comando

        -- unsigned intermedi
        variable addr_val_u : unsigned(C_ADDR_WIDTH-1 downto 0);
        variable data_val_u : unsigned(C_DATA_WIDTH-1 downto 0);

        -- tipi finali
        variable addr_val   : t_addr := (others => '0');
        variable offset_val : integer := 0;
        variable data_val   : t_data := (others => '0');
    begin
        parse_error := false;

        --------------------------------------------------------------------
        -- 1. Indirizzo (obbligatorio)
        --------------------------------------------------------------------
        if idx > nt or tokens(idx).kind = TK_END then
            report "PARSE BASE ERROR: missing address" severity error;
            parse_error := true;
            return;
        end if;

        eval_addr_u(tokens(idx).text, addr_val_u, parse_error);
        if parse_error then
            report "PARSE BASE ERROR: invalid address expression" severity error;
            return;
        end if;

        addr_val := std_logic_vector(addr_val_u);
        idx := idx + 1;

        --------------------------------------------------------------------
        -- 2. Offset (opzionale)
        --------------------------------------------------------------------
        if idx <= nt then
            if trim_string(tokens(idx).text) = "+" then
                idx := idx + 1;

                if idx > nt or tokens(idx).kind = TK_END then
                    report "PARSE BASE ERROR: missing offset value" severity error;
                    parse_error := true;
                    return;
                end if;

                eval_expr_i(tokens(idx).text, offset_val, parse_error);
                if parse_error then
                    report "PARSE BASE ERROR: invalid offset expression" severity error;
                    parse_error := true;
                    return;
                end if;

                idx := idx + 1;
            end if;
        end if;

        --------------------------------------------------------------------
        -- 3. Dato (solo WRITE e CHECK)
        --------------------------------------------------------------------
        case cmd.command is

            when CMD_WRITE | CMD_CHECK =>
                if idx > nt or tokens(idx).kind /= TK_NUMBER then
                    report "PARSE BASE ERROR: missing data" severity error;
                    parse_error := true;
                    return;
                end if;

                eval_data_u(tokens(idx).text, data_val_u, parse_error);
                if parse_error then
                    report "PARSE BASE ERROR: invalid data expression" severity error;
                    return;
                end if;

                data_val := std_logic_vector(data_val_u);

            when CMD_READ =>
                data_val := (others => '0');

            when others =>
                report "PARSE BASE ERROR: unsupported command" severity error;
                parse_error := true;
                return;
        end case;

        --------------------------------------------------------------------
        -- 4. Assegna i valori al comando
        --------------------------------------------------------------------
        cmd.addr   := addr_val;
        cmd.offset := offset_val;
        cmd.data   := data_val;

        --------------------------------------------------------------------
        -- 5. Parametri per semantic_check
        --------------------------------------------------------------------
        -- Numero parametri (WRITE/READ/CHECK hanno 1 o 2 parametri)
        -- WRITE: addr (+offset) + data  → 2 parametri
        -- READ:  addr (+offset)         → 1 parametro
        -- CHECK: addr (+offset) + data  → 2 parametri
        if cmd.command = CMD_READ then
            cmd.param_count := 1;
        else
            cmd.param_count := 2;
        end if;

        -- Tipi parametri
        cmd.param_kind(1) := PK_ADDR;

        if cmd.command = CMD_WRITE or cmd.command = CMD_CHECK then
            cmd.param_kind(2) := PK_DATA;
        else
            cmd.param_kind(2) := PK_NONE;
        end if;

        -- WRAP non usato qui
        cmd.wrap_size := 0;

        --------------------------------------------------------------------
        -- 6. Debug
        --------------------------------------------------------------------
        case cmd.command is
            when CMD_WRITE =>
				if ENABLE_DEBUG_LOG then
					report "PARSE WRITE: addr=0x" & slv_to_hex(cmd.addr) &
						" offset=" & integer'image(cmd.offset) &
						" data=0x" & slv_to_hex(cmd.data);
				end if;

            when CMD_READ =>
				if ENABLE_DEBUG_LOG then
					report "PARSE READ: addr=0x" & slv_to_hex(cmd.addr) &
						" offset=" & integer'image(cmd.offset);
				end if;

            when CMD_CHECK =>
				if ENABLE_DEBUG_LOG then
					report "PARSE CHECK: addr=0x" & slv_to_hex(cmd.addr) &
						" offset=" & integer'image(cmd.offset) &
						" expected=0x" & slv_to_hex(cmd.data);
				end if;

            when others =>
                null;
        end case;

    end procedure;

	--------------------------------------------------------------------
	-- parse_poll_read:
	-- POLL_READ <addr_expr> [+ offset] <expected> <mask> <delay> <timeout>
	--------------------------------------------------------------------
	procedure parse_poll_read(
		tokens      : in  token_acc_list_t;
		nt          : in  natural;
		cmd         : inout t_cmd;
		parse_error : inout boolean
	) is
		variable idx        : natural := 3;  -- dopo TK_START e comando

		variable addr_val_u : unsigned(C_ADDR_WIDTH-1 downto 0);
		variable addr_val   : t_addr := (others => '0');
		variable offset_val : integer := 0;

		variable expected_u : unsigned(C_DATA_WIDTH-1 downto 0);
		variable mask_u     : unsigned(C_DATA_WIDTH-1 downto 0);

		variable delay_int  : integer := 0;
		variable timeout_int: integer := 0;
	begin
		parse_error := false;

		--------------------------------------------------------------------
		-- 1. Indirizzo obbligatorio
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE POLL_READ ERROR: missing address" severity error;
			parse_error := true;
			return;
		end if;

		eval_addr_u(tokens(idx).text, addr_val_u, parse_error);
		if parse_error then
			report "PARSE POLL_READ ERROR: invalid address expression" severity error;
			return;
		end if;

		addr_val := std_logic_vector(addr_val_u);
		idx := idx + 1;

		--------------------------------------------------------------------
		-- 2. Offset opzionale: "+ <expr>"
		--------------------------------------------------------------------
		if idx <= nt then
			if trim_string(tokens(idx).text) = "+" then
				idx := idx + 1;

				if idx > nt or tokens(idx).kind = TK_END then
					report "PARSE POLL_READ ERROR: missing offset value" severity error;
					parse_error := true;
					return;
				end if;

				eval_expr_i(tokens(idx).text, offset_val, parse_error);
				if parse_error then
					report "PARSE POLL_READ ERROR: invalid offset expression" severity error;
					return;
				end if;

				idx := idx + 1;
			end if;
		end if;

		--------------------------------------------------------------------
		-- 3. Expected (obbligatorio)
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE POLL_READ ERROR: missing expected value" severity error;
			parse_error := true;
			return;
		end if;

		eval_data_u(tokens(idx).text, expected_u, parse_error);
		if parse_error then
			report "PARSE POLL_READ ERROR: invalid expected value" severity error;
			return;
		end if;

		idx := idx + 1;

		--------------------------------------------------------------------
		-- 4. Mask (obbligatoria)
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE POLL_READ ERROR: missing mask value" severity error;
			parse_error := true;
			return;
		end if;

		eval_data_u(tokens(idx).text, mask_u, parse_error);
		if parse_error then
			report "PARSE POLL_READ ERROR: invalid mask value" severity error;
			return;
		end if;

		idx := idx + 1;

		--------------------------------------------------------------------
		-- 5. Delay (obbligatorio)
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE POLL_READ ERROR: missing delay" severity error;
			parse_error := true;
			return;
		end if;

		eval_expr_i(tokens(idx).text, delay_int, parse_error);
		if parse_error or delay_int < 0 then
			report "PARSE POLL_READ ERROR: invalid delay expression" severity error;
			parse_error := true;
			return;
		end if;

		idx := idx + 1;

		--------------------------------------------------------------------
		-- 6. Timeout (obbligatorio)
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE POLL_READ ERROR: missing timeout" severity error;
			parse_error := true;
			return;
		end if;

		eval_expr_i(tokens(idx).text, timeout_int, parse_error);
		if parse_error or timeout_int < 0 then
			report "PARSE POLL_READ ERROR: invalid timeout expression" severity error;
			parse_error := true;
			return;
		end if;

		--------------------------------------------------------------------
		-- 7. Assegna al comando
		--------------------------------------------------------------------
		cmd.addr       := addr_val;
		cmd.offset     := offset_val;

		cmd.data       := std_logic_vector(expected_u);  -- expected
		cmd.data_array := (others => (others => '0'));
		cmd.data_array(0) := std_logic_vector(mask_u);   -- mask

		cmd.wait_value := delay_int;                     -- delay
		cmd.wait_unit  := TU_CLK;

		cmd.timeout    := natural(timeout_int);          -- ⭐ timeout POLL
		cmd.len        := 1;                             -- NON usato dal POLL

		--------------------------------------------------------------------
		-- 8. Parametri per semantic_check
		--------------------------------------------------------------------
		cmd.param_count := 5;

		cmd.param_kind(1) := PK_ADDR;
		cmd.param_kind(2) := PK_DATA;  -- expected
		cmd.param_kind(3) := PK_DATA;  -- mask
		cmd.param_kind(4) := PK_LEN;   -- delay
		cmd.param_kind(5) := PK_LEN;   -- timeout

		cmd.wrap_size := 0;

		--------------------------------------------------------------------
		-- 9. Debug
		--------------------------------------------------------------------
		if ENABLE_DEBUG_LOG then
			report "PARSE POLL_READ: addr=0x" & slv_to_hex(cmd.addr) &
				" offset=" & integer'image(cmd.offset) &
				" expected=0x" & slv_to_hex(cmd.data) &
				" mask=0x" & slv_to_hex(cmd.data_array(0)) &
				" delay=" & integer'image(cmd.wait_value) &
				" timeout=" & integer'image(cmd.timeout)
				severity note;
		end if;

	end procedure;

	----------------------------------------------------------------
	-- parse_poll_toggle:
	-- POLL_TOGGLE <addr_expr> [+ offset] <mask> <delay> <timeout>
	----------------------------------------------------------------
	procedure parse_poll_toggle(
		tokens      : in  token_acc_list_t;
		nt          : in  natural;
		cmd         : inout t_cmd;
		parse_error : inout boolean
	) is
		variable idx        : natural := 3;

		variable addr_val_u : unsigned(C_ADDR_WIDTH-1 downto 0);
		variable addr_val   : t_addr := (others => '0');
		variable offset_val : integer := 0;

		variable mask_u     : unsigned(C_DATA_WIDTH-1 downto 0);

		variable delay_int  : integer := 0;
		variable timeout_int: integer := 0;
	begin
		parse_error := false;

		--------------------------------------------------------------------
		-- 1. Indirizzo
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE POLL_TOGGLE ERROR: missing address" severity error;
			parse_error := true;
			return;
		end if;

		eval_addr_u(tokens(idx).text, addr_val_u, parse_error);
		if parse_error then
			report "PARSE POLL_TOGGLE ERROR: invalid address expression" severity error;
			return;
		end if;

		addr_val := std_logic_vector(addr_val_u);
		idx := idx + 1;

		--------------------------------------------------------------------
		-- 2. Offset opzionale
		--------------------------------------------------------------------
		if idx <= nt then
			if trim_string(tokens(idx).text) = "+" then
				idx := idx + 1;

				if idx > nt or tokens(idx).kind = TK_END then
					report "PARSE POLL_TOGGLE ERROR: missing offset value" severity error;
					parse_error := true;
					return;
				end if;

				eval_expr_i(tokens(idx).text, offset_val, parse_error);
				if parse_error then
					report "PARSE POLL_TOGGLE ERROR: invalid offset expression" severity error;
					return;
				end if;

				idx := idx + 1;
			end if;
		end if;

		--------------------------------------------------------------------
		-- 3. Mask
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE POLL_TOGGLE ERROR: missing mask value" severity error;
			parse_error := true;
			return;
		end if;

		eval_data_u(tokens(idx).text, mask_u, parse_error);
		if parse_error then
			report "PARSE POLL_TOGGLE ERROR: invalid mask value" severity error;
			return;
		end if;

		idx := idx + 1;

		--------------------------------------------------------------------
		-- 4. Delay
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE POLL_TOGGLE ERROR: missing delay" severity error;
			parse_error := true;
			return;
		end if;

		eval_expr_i(tokens(idx).text, delay_int, parse_error);
		if parse_error or delay_int < 0 then
			report "PARSE POLL_TOGGLE ERROR: invalid delay expression" severity error;
			parse_error := true;
			return;
		end if;

		idx := idx + 1;

		--------------------------------------------------------------------
		-- 5. Timeout
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE POLL_TOGGLE ERROR: missing timeout" severity error;
			parse_error := true;
			return;
		end if;

		eval_expr_i(tokens(idx).text, timeout_int, parse_error);
		if parse_error or timeout_int < 0 then
			report "PARSE POLL_TOGGLE ERROR: invalid timeout expression" severity error;
			parse_error := true;
			return;
		end if;

		--------------------------------------------------------------------
		-- 6. Assegna al comando
		--------------------------------------------------------------------
		cmd.addr       := addr_val;
		cmd.offset     := offset_val;

		cmd.data       := (others => '0');               -- non usato
		cmd.data_array := (others => (others => '0'));
		cmd.data_array(0) := std_logic_vector(mask_u);   -- mask

		cmd.wait_value := delay_int;                     -- delay
		cmd.wait_unit  := TU_CLK;

		cmd.timeout    := natural(timeout_int);          -- ⭐ timeout POLL
		cmd.len        := 1;                             -- NON usato dal POLL

		--------------------------------------------------------------------
		-- 7. Parametri per semantic_check
		--------------------------------------------------------------------
		cmd.param_count := 4;

		cmd.param_kind(1) := PK_ADDR;
		cmd.param_kind(2) := PK_DATA;  -- mask
		cmd.param_kind(3) := PK_LEN;   -- delay
		cmd.param_kind(4) := PK_LEN;   -- timeout

		cmd.wrap_size := 0;

		--------------------------------------------------------------------
		-- 8. Debug
		--------------------------------------------------------------------
		if ENABLE_DEBUG_LOG then
			report "PARSE POLL_TOGGLE: addr=0x" & slv_to_hex(cmd.addr) &
				" offset=" & integer'image(cmd.offset) &
				" mask=0x" & slv_to_hex(cmd.data_array(0)) &
				" delay=" & integer'image(cmd.wait_value) &
				" timeout=" & integer'image(cmd.timeout)
				severity note;
		end if;

	end procedure;

	--------------------------------------------------------------------
	-- parse_poll_ping:
	-- POLL_PING <addr_expr> [+ offset] <delay> <timeout>
	--------------------------------------------------------------------
	procedure parse_poll_ping(
		tokens      : in  token_acc_list_t;
		nt          : in  natural;
		cmd         : inout t_cmd;
		parse_error : inout boolean
	) is
		variable idx         : natural := 3;

		variable addr_val_u  : unsigned(C_ADDR_WIDTH-1 downto 0);
		variable addr_val    : t_addr := (others => '0');
		variable offset_val  : integer := 0;

		variable delay_int   : integer := 0;
		variable timeout_int : integer := 0;
	begin
		parse_error := false;

		--------------------------------------------------------------------
		-- 1. Indirizzo
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE POLL_PING ERROR: missing address" severity error;
			parse_error := true;
			return;
		end if;

		eval_addr_u(tokens(idx).text, addr_val_u, parse_error);
		if parse_error then
			report "PARSE POLL_PING ERROR: invalid address expression" severity error;
			return;
		end if;

		addr_val := std_logic_vector(addr_val_u);
		idx := idx + 1;

		--------------------------------------------------------------------
		-- 2. Offset opzionale "+ <expr>"
		--------------------------------------------------------------------
		if idx <= nt then
			if trim_string(tokens(idx).text) = "+" then
				idx := idx + 1;

				if idx > nt or tokens(idx).kind = TK_END then
					report "PARSE POLL_PING ERROR: missing offset value" severity error;
					parse_error := true;
					return;
				end if;

				eval_expr_i(tokens(idx).text, offset_val, parse_error);
				if parse_error then
					report "PARSE POLL_PING ERROR: invalid offset expression" severity error;
					return;
				end if;

				idx := idx + 1;
			end if;
		end if;

		--------------------------------------------------------------------
		-- 3. Delay
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE POLL_PING ERROR: missing delay" severity error;
			parse_error := true;
			return;
		end if;

		eval_expr_i(tokens(idx).text, delay_int, parse_error);
		if parse_error or delay_int < 0 then
			report "PARSE POLL_PING ERROR: invalid delay expression" severity error;
			parse_error := true;
			return;
		end if;

		idx := idx + 1;

		--------------------------------------------------------------------
		-- 4. Timeout
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE POLL_PING ERROR: missing timeout" severity error;
			parse_error := true;
			return;
		end if;

		eval_expr_i(tokens(idx).text, timeout_int, parse_error);
		if parse_error or timeout_int < 0 then
			report "PARSE POLL_PING ERROR: invalid timeout expression" severity error;
			parse_error := true;
			return;
		end if;

		idx := idx + 1;

		--------------------------------------------------------------------
		-- 5. Assegna al comando
		--------------------------------------------------------------------
		cmd.addr       := addr_val;
		cmd.offset     := offset_val;

		cmd.data       := (others => '0');
		cmd.data_array := (others => (others => '0'));

		cmd.wait_value := delay_int;       -- delay tra retry
		cmd.wait_unit  := TU_CLK;

		cmd.timeout    := natural(timeout_int);  -- ⭐ timeout POLL
		cmd.len        := 1;                     -- NON usato dal POLL

		--------------------------------------------------------------------
		-- 6. Parametri per semantic_check
		--------------------------------------------------------------------
		cmd.param_count := 3;

		cmd.param_kind(1) := PK_ADDR;
		cmd.param_kind(2) := PK_LEN;    -- delay
		cmd.param_kind(3) := PK_LEN;    -- delay
		cmd.wrap_size := 0;

		--------------------------------------------------------------------
		-- 7. Debug
		--------------------------------------------------------------------
		if ENABLE_DEBUG_LOG then
			report "PARSE POLL_PING: addr=0x" & slv_to_hex(cmd.addr) &
				" offset=" & integer'image(cmd.offset) &
				" delay=" & integer'image(cmd.wait_value) &
				" timeout=" & integer'image(cmd.timeout)
				severity note;
		end if;

	end procedure;


	----------------------------------------------------------------
	-- parse_set_var: SET_VAR <identifier> <number>
	----------------------------------------------------------------
	procedure parse_set_var(
		tokens      : in  token_acc_list_t;
		nt          : in  natural;
		cmd         : inout t_cmd;
		parse_error : inout boolean
	) is
		variable idx      : natural := 3;  -- dopo TK_START e comando
		variable var_name : t_line := line_clear;
		variable value_u  : unsigned(C_DATA_WIDTH-1 downto 0);
	begin
		parse_error := false;

		--------------------------------------------------------------------
		-- 1. Nome variabile (obbligatorio)
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind /= TK_STRING then
			report "PARSE SET_VAR ERROR: missing variable name" severity error;
			parse_error := true;
			return;
		end if;

		assign_string(var_name, trim_string(tokens(idx).text));
		idx := idx + 1;

		--------------------------------------------------------------------
		-- 2. Salta eventuale "="
		--------------------------------------------------------------------
		if idx <= nt and trim_string(tokens(idx).text) = "=" then
			idx := idx + 1;
		end if;

		--------------------------------------------------------------------
		-- 3. Valore numerico (obbligatorio)
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind /= TK_NUMBER then
			report "PARSE SET_VAR ERROR: missing numeric value" severity error;
			parse_error := true;
			return;
		end if;

		eval_data_u(tokens(idx).text, value_u, parse_error);
		if parse_error then
			report "PARSE SET_VAR ERROR: invalid numeric value" severity error;
			return;
		end if;

		--------------------------------------------------------------------
		-- 4. Assegna i valori al comando
		--------------------------------------------------------------------
		cmd.var_name := var_name;
		cmd.data     := std_logic_vector(value_u);

		--------------------------------------------------------------------
		-- 5. Salva la variabile nella tabella
		--------------------------------------------------------------------
		set_var(cmd.var_name, cmd.data);

		--------------------------------------------------------------------
		-- 6. Parametri per semantic_check
		--------------------------------------------------------------------
		cmd.param_count := 2;
		cmd.param_kind(1) := PK_STRING;
		cmd.param_kind(2) := PK_DATA;
		cmd.wrap_size := 0;

		--------------------------------------------------------------------
		-- 7. Debug
		--------------------------------------------------------------------
		if ENABLE_DEBUG_LOG then
			report "PARSE SET_VAR: name=""" & trim_string(cmd.var_name)
				& """ value=0x" & slv_to_hex(cmd.data);
		end if;

	end procedure;


    ----------------------------------------------------------------
    -- parse_set_atomic: SET_ATOMIC <0|1>
    ----------------------------------------------------------------
    procedure parse_set_atomic(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    ) is
        variable idx : natural := 3;  -- dopo TK_START e comando
    begin
        parse_error := false;

        --------------------------------------------------------------------
        -- 1. Controllo presenza valore
        --------------------------------------------------------------------
        if idx > nt or tokens(idx).kind = TK_END then
            report "PARSE SET_ATOMIC ERROR: missing value" severity error;
            parse_error := true;
            return;
        end if;

        --------------------------------------------------------------------
        -- 2. Imposta il comando
        --------------------------------------------------------------------
        cmd.command := CMD_SET_ATOMIC;

        --------------------------------------------------------------------
        -- 3. Valore atomico: deve essere 0 o 1
        --------------------------------------------------------------------
        if trim_string(tokens(idx).text) = "1" then
            cmd.atomic := '1';

        elsif trim_string(tokens(idx).text) = "0" then
            cmd.atomic := '0';

        else
            report "PARSE SET_ATOMIC ERROR: invalid value '" &
                trim_string(tokens(idx).text) &
                "' (expected 0 or 1)" severity error;
            parse_error := true;
            return;
        end if;

        --------------------------------------------------------------------
        -- 4. Parametri per semantic_check
        --------------------------------------------------------------------
        -- SET_ATOMIC ha 1 parametro: PK_DATA
        cmd.param_count := 1;
        cmd.param_kind(1) := PK_DATA;

        cmd.wrap_size := 0;  -- non usato

        --------------------------------------------------------------------
        -- 5. Debug compatto
        --------------------------------------------------------------------
        if ENABLE_DEBUG_LOG then
			report "PARSE SET_ATOMIC: atomic=" &
				trim_string(tokens(idx).text) severity note;
		end if;

    end procedure;


    ----------------------------------------------------------------
    -- parse_wait_clocks: WAIT_CLOCKS <expr>
    -- Esempi:
    --   WAIT_CLOCKS 10
    --   WAIT_CLOCKS VAR_X
    --   WAIT_CLOCKS BASE_DELAY + 5
    ----------------------------------------------------------------
    procedure parse_wait_clocks(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    ) is
        variable idx        : natural := 3;  -- dopo TK_START e comando
        variable tmp_int    : integer := 0;
    begin
        parse_error := false;

        --------------------------------------------------------------------
        -- 1. Espressione dei cicli (obbligatoria)
        --------------------------------------------------------------------
        if idx > nt or tokens(idx).kind = TK_END then
            report "PARSE WAIT_CLOCKS ERROR: missing clock expression" severity error;
            parse_error := true;
            return;
        end if;

        -- Valuta l'espressione dei cicli
        eval_expr_i(tokens(idx).text, tmp_int, parse_error);
        if parse_error then
            report "PARSE WAIT_CLOCKS ERROR: invalid clock expression" severity error;
            return;
        end if;

        -- Deve essere >= 0
        if tmp_int < 0 then
            report "PARSE WAIT_CLOCKS ERROR: negative clock count not allowed" severity error;
            parse_error := true;
            return;
        end if;

        --------------------------------------------------------------------
        -- 2. Assegna i valori al comando
        --------------------------------------------------------------------
        cmd.wait_value := natural(tmp_int);
        cmd.wait_unit  := TU_CLK;

        --------------------------------------------------------------------
        -- 3. Parametri per semantic_check
        --------------------------------------------------------------------
        -- WAIT_CLOCKS ha 1 parametro: PK_LEN
        cmd.param_count := 1;
        cmd.param_kind(1) := PK_LEN;

        cmd.wrap_size := 0;  -- non usato

        --------------------------------------------------------------------
        -- 4. Debug compatto
        --------------------------------------------------------------------
        if ENABLE_DEBUG_LOG then
			report "PARSE WAIT_CLOCKS: clocks=" & integer'image(cmd.wait_value);
        end if;

    end procedure;


    ----------------------------------------------------------------
    -- parse_wait_time: WAIT_TIME <time_expr> <unit>
    -- Esempi:
    --   WAIT_TIME 10us
    --   WAIT_TIME 100 ms
    --   WAIT_TIME BASE_DELAY + 5 us
    ----------------------------------------------------------------
    procedure parse_wait_time(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    ) is
        variable idx        : natural := 3;  -- dopo TK_START e comando
        variable tmp_int    : integer := 0;
        variable unit_val   : t_time_unit := TU_NONE;
    begin
        parse_error := false;

        --------------------------------------------------------------------
        -- 1. Valore temporale (espressione)
        --------------------------------------------------------------------
        if idx > nt or tokens(idx).kind = TK_END then
            report "PARSE WAIT_TIME ERROR: missing time value" severity error;
            parse_error := true;
            return;
        end if;

        eval_expr_i(tokens(idx).text, tmp_int, parse_error);
        if parse_error then
            report "PARSE WAIT_TIME ERROR: invalid time expression" severity error;
            return;
        end if;

        if tmp_int < 0 then
            report "PARSE WAIT_TIME ERROR: negative time not allowed" severity error;
            parse_error := true;
            return;
        end if;

        idx := idx + 1;

        --------------------------------------------------------------------
        -- 2. Unità di tempo (obbligatoria)
        --------------------------------------------------------------------
        if idx > nt or tokens(idx).kind = TK_END then
            report "PARSE WAIT_TIME ERROR: missing time unit" severity error;
            parse_error := true;
            return;
        end if;

        unit_val := decode_time_unit(tokens(idx).text);
        if unit_val = TU_NONE then
            report "PARSE WAIT_TIME ERROR: invalid time unit """ &
                trim_string(tokens(idx).text) & """"
                severity error;
            parse_error := true;
            return;
        end if;

        --------------------------------------------------------------------
        -- 3. Assegna i valori al comando
        --------------------------------------------------------------------
        cmd.wait_value := natural(tmp_int);
        cmd.wait_unit  := unit_val;

        --------------------------------------------------------------------
        -- 4. Parametri per semantic_check
        --------------------------------------------------------------------
        -- WAIT_TIME ha 2 parametri, entrambi PK_NONE
        cmd.param_count := 2;
        cmd.param_kind(1) := PK_NONE;
        cmd.param_kind(2) := PK_NONE;

        cmd.wrap_size := 0;  -- non usato

        --------------------------------------------------------------------
        -- 5. Debug compatto
        --------------------------------------------------------------------
        if ENABLE_DEBUG_LOG then
			report "PARSE WAIT_TIME: value=" & integer'image(cmd.wait_value) &
				" unit=" & t_time_unit'image(cmd.wait_unit);
		end if;

    end procedure;

    ----------------------------------------------------------------
    -- parse_wait_sim_time: WAIT_SIM_TIME <expr>
    -- Esempi:
    --   WAIT_SIM_TIME 100
    --   WAIT_SIM_TIME VAR_X
    --   WAIT_SIM_TIME BASE_DELAY + 5
    ----------------------------------------------------------------
    procedure parse_wait_sim_time(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    ) is
        variable idx       : natural := 3;  -- dopo TK_START e comando
        variable tmp_int   : integer := 0;
    begin
        parse_error := false;

        --------------------------------------------------------------------
        -- 1. Espressione del tempo simulato (obbligatoria)
        --------------------------------------------------------------------
        if idx > nt or tokens(idx).kind = TK_END then
            report "PARSE WAIT_SIM_TIME ERROR: missing time expression" severity error;
            parse_error := true;
            return;
        end if;

        eval_expr_i(tokens(idx).text, tmp_int, parse_error);
        if parse_error then
            report "PARSE WAIT_SIM_TIME ERROR: invalid time expression" severity error;
            return;
        end if;

        if tmp_int < 0 then
            report "PARSE WAIT_SIM_TIME ERROR: negative time not allowed" severity error;
            parse_error := true;
            return;
        end if;

        --------------------------------------------------------------------
        -- 2. Assegna i valori al comando
        --------------------------------------------------------------------
        cmd.wait_value := natural(tmp_int);
        cmd.wait_unit  := TU_SIM;

        --------------------------------------------------------------------
        -- 3. Parametri per semantic_check
        --------------------------------------------------------------------
        -- WAIT_SIM_TIME ha 1 parametro: PK_NONE
        cmd.param_count := 1;
        cmd.param_kind(1) := PK_LEN;

        cmd.wrap_size := 0;  -- non usato

        --------------------------------------------------------------------
        -- 4. Debug compatto
        --------------------------------------------------------------------
        if ENABLE_DEBUG_LOG then
			report "PARSE WAIT_SIM_TIME: time=" & integer'image(cmd.wait_value);
        end if;

    end procedure;

    ----------------------------------------------------------------
    -- parse_include: INCLUDE <filename>
    -- Esempi:
    --   INCLUDE "init.cmd"
    --   INCLUDE config.txt
    ----------------------------------------------------------------
    procedure parse_include(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    ) is
        variable idx      : natural := 3;  -- dopo TK_START e comando
        variable filename : t_line := line_clear;

        variable src      : string(1 to C_MAX_STRING);
        variable first    : natural;
        variable last     : natural;
        variable len_trim : natural;
    begin
        parse_error := false;

        --------------------------------------------------------------------
        -- 1. Filename obbligatorio
        --------------------------------------------------------------------
        if idx > nt or tokens(idx).kind = TK_END then
            report "PARSE INCLUDE ERROR: missing filename" severity error;
            parse_error := true;
            return;
        end if;

        if tokens(idx).kind /= TK_STRING then
            report "PARSE INCLUDE ERROR: filename must be a string" severity error;
            parse_error := true;
            return;
        end if;

        --------------------------------------------------------------------
        -- 2. Copia sicura del filename (senza trim_string, senza assign_string)
        --------------------------------------------------------------------
        src := line_to_string(tokens(idx).text);

        -- trim manuale
        first := 1;
        while first <= C_MAX_STRING and src(first) = ' ' loop
            first := first + 1;
        end loop;

        if first > C_MAX_STRING then
            report "PARSE INCLUDE ERROR: empty filename" severity error;
            parse_error := true;
            return;
        end if;

        last := C_MAX_STRING;
        while last >= first and src(last) = ' ' loop
            last := last - 1;
        end loop;

        len_trim := last - first + 1;

        -- copia nel t_line
        for k in 1 to C_MAX_STRING loop
            if k <= len_trim then
                filename(k) := src(first + k - 1);
            else
                filename(k) := ' ';
            end if;
        end loop;

        --------------------------------------------------------------------
        -- 3. Assegna al comando
        --------------------------------------------------------------------
        cmd.filename := filename;

        --------------------------------------------------------------------
        -- 4. Parametri per semantic_check
        --------------------------------------------------------------------
        -- INCLUDE ha 1 parametro: PK_STRING
        cmd.param_count := 1;
        cmd.param_kind(1) := PK_STRING;

        cmd.wrap_size := 0;  -- non usato

        --------------------------------------------------------------------
        -- 5. Debug
        --------------------------------------------------------------------
        if ENABLE_DEBUG_LOG then
			report "PARSE INCLUDE: file=""" &
				trim_string(cmd.filename) &
				"""";
		end if;

    end procedure;

    --------------------------------------------------------------------
    -- PARSE END_SIM
    -- Sintassi valida:
    --     END_SIM
    --
    -- Token attesi:
    --   1: tk_start
    --   2: tk_string "END_SIM"
    --   3: tk_end
    --------------------------------------------------------------------
    procedure parse_end_sim(
        tokens      : in token_acc_list_t;
        nt          : in natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    ) is
    begin
        -- END_SIM non ha argomenti
        if nt /= 3 then
            parse_error := true;
            return;
        end if;

        cmd.command := CMD_END_SIM;
        parse_error := false;

        --------------------------------------------------------------------
        -- Parametri per semantic_check
        --------------------------------------------------------------------
        cmd.param_count := 0;          -- nessun parametro
        cmd.wrap_size   := 0;          -- non usato

        -- Tutti PK_NONE (semantic_check li ignora quando param_count = 0)
        for i in cmd.param_kind'range loop
            cmd.param_kind(i) := PK_NONE;
        end loop;

        --------------------------------------------------------------------
        -- Debug
        --------------------------------------------------------------------
        if ENABLE_DEBUG_LOG then
			report "PARSE END_SIM";
        end if;
    end procedure;


    ----------------------------------------------------------------
    -- parse_print: PRINT <text...>
    -- Esempi:
    --   PRINT Hello world
    --   PRINT "Hello world"
    --   PRINT Value is: 0x10
    ----------------------------------------------------------------
    procedure parse_print(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    ) is
        variable idx      : natural := 3;  -- dopo TK_START e comando
        variable text     : t_line := line_clear;
        variable pos      : natural := 1;

        variable src      : string(1 to C_MAX_STRING);
        variable first    : natural;
        variable last     : natural;
        variable len_trim : natural;
    begin
        parse_error := false;

        --------------------------------------------------------------------
        -- 1. PRINT senza testo → stampa una riga vuota
        --------------------------------------------------------------------
        if idx > nt or tokens(idx).kind = TK_END then
            cmd.print_text := line_clear;

            -- Parametri per semantic_check
            cmd.param_count := 1;
            cmd.param_kind(1) := PK_STRING;
            cmd.wrap_size := 0;

            if ENABLE_DEBUG_LOG then
				report "PARSE PRINT: empty text -> newline" severity note;
            end if;
            return;
        end if;

        --------------------------------------------------------------------
        -- 2. Concatenazione di tutti i token TK_STRING
        --------------------------------------------------------------------
        while idx <= nt loop
            exit when tokens(idx).kind = TK_END;

            if tokens(idx).kind = TK_STRING then

                -- Converti t_line → string
                src := line_to_string(tokens(idx).text);

                -- Trim manuale
                first := 1;
                while first <= C_MAX_STRING and src(first) = ' ' loop
                    first := first + 1;
                end loop;

                if first > C_MAX_STRING then
                    idx := idx + 1;
                    next;
                end if;

                last := C_MAX_STRING;
                while last >= first and src(last) = ' ' loop
                    last := last - 1;
                end loop;

                len_trim := last - first + 1;

                -- Copia nel buffer text
                for j in 1 to len_trim loop
                    exit when pos > C_MAX_STRING;
                    text(pos) := src(first + j - 1);
                    pos := pos + 1;
                end loop;

                -- Aggiungi spazio tra token (solo se ci sarà un altro token)
                if pos <= C_MAX_STRING then
                    text(pos) := ' ';
                    pos := pos + 1;
                end if;
            end if;

            idx := idx + 1;
        end loop;

        --------------------------------------------------------------------
        -- 3. Rimuovi eventuale spazio finale
        --------------------------------------------------------------------
        if pos > 1 and text(pos-1) = ' ' then
            pos := pos - 1;
            text(pos) := ' ';
        end if;

        --------------------------------------------------------------------
        -- 4. Assegna il testo al comando
        --------------------------------------------------------------------
        cmd.print_text := text;

        --------------------------------------------------------------------
        -- 5. Parametri per semantic_check
        --------------------------------------------------------------------
        cmd.param_count := 1;
        cmd.param_kind(1) := PK_STRING;
        cmd.wrap_size := 0;

        --------------------------------------------------------------------
        -- 6. Debug compatto
        --------------------------------------------------------------------
        if ENABLE_DEBUG_LOG then
			report "PARSE PRINT: """ &
				trim_string(cmd.print_text) &
				"""";
		end if;

    end procedure;


	--------------------------------------------------------------------
	-- parse_fifo: gestisce FIFO_WRITE / FIFO_READ / FIFO_CHECK
	-- Supporta len > 1, data_array[] e multilinea
	--------------------------------------------------------------------
	procedure parse_fifo(
		tokens      : in  token_acc_list_t;
		nt          : in  natural;
		cmd         : inout t_cmd;
		parse_error : inout boolean
	) is
		variable idx        : natural := 3;  -- dopo TK_START e comando

		variable addr_val_u : unsigned(C_ADDR_WIDTH-1 downto 0);
		variable data_val_u : unsigned(C_DATA_WIDTH-1 downto 0);

		variable addr_val   : t_addr := (others => '0');
		variable offset_val : integer := 0;

		variable len_val    : integer := 0;

		variable data_in_line : natural := 0;
	begin
		parse_error := false;

		--------------------------------------------------------------------
		-- 1. Indirizzo (obbligatorio)
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE FIFO ERROR: missing address" severity error;
			parse_error := true;
			return;
		end if;

		eval_addr_u(tokens(idx).text, addr_val_u, parse_error);
		if parse_error then
			report "PARSE FIFO ERROR: invalid address expression" severity error;
			return;
		end if;

		addr_val := std_logic_vector(addr_val_u);
		idx := idx + 1;

		--------------------------------------------------------------------
		-- 2. Offset (opzionale)
		--------------------------------------------------------------------
		if idx <= nt and trim_string(tokens(idx).text) = "+" then
			idx := idx + 1;

			if idx > nt or tokens(idx).kind = TK_END then
				report "PARSE FIFO ERROR: missing offset value" severity error;
				parse_error := true;
				return;
			end if;

			eval_expr_i(tokens(idx).text, offset_val, parse_error);
			if parse_error or offset_val < 0 then
				report "PARSE FIFO ERROR: invalid offset expression" severity error;
				parse_error := true;
				return;
			end if;

			idx := idx + 1;
		end if;

		--------------------------------------------------------------------
		-- 3. Lunghezza (obbligatoria)
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind /= TK_NUMBER then
			report "PARSE FIFO ERROR: missing length" severity error;
			parse_error := true;
			return;
		end if;

		eval_expr_i(tokens(idx).text, len_val, parse_error);
		if parse_error or len_val <= 0 then
			report "PARSE FIFO ERROR: invalid length" severity error;
			parse_error := true;
			return;
		end if;

		--------------------------------------------------------------------
		-- ⭐ Limite massimo: deve stare dentro data_array
		--------------------------------------------------------------------
		if len_val > C_MAX_DATA_TOKENS then
			report "PARSE FIFO ERROR: length exceeds C_MAX_DATA_TOKENS="
				& integer'image(C_MAX_DATA_TOKENS) severity error;
			parse_error := true;
			return;
		end if;

		cmd.len := len_val;

		-- ⭐ inizializza tutto a 0x0
		cmd.data_array := (others => (others => '0'));

		idx := idx + 1;

		--------------------------------------------------------------------
		-- 4. Dati (solo WRITE e CHECK)
		--------------------------------------------------------------------
		if cmd.command = CMD_FIFO_WRITE or cmd.command = CMD_FIFO_CHECK then

			for j in 0 to len_val-1 loop
				if idx > nt or tokens(idx).kind /= TK_NUMBER then
					report "PARSE FIFO ERROR: missing data element "
						& integer'image(j) severity error;
					parse_error := true;
					return;
				end if;

				data_in_line := data_in_line + 1;
				if data_in_line > C_MAX_DATA_PER_LINE then
					data_in_line := 1;
				end if;

				eval_data_u(tokens(idx).text, data_val_u, parse_error);
				if parse_error then
					report "PARSE FIFO ERROR: invalid data element "
						& integer'image(j) severity error;
					return;
				end if;

				cmd.data_array(j) := std_logic_vector(data_val_u);
				idx := idx + 1;
			end loop;

		elsif cmd.command = CMD_FIFO_READ then
			for j in 0 to len_val-1 loop
				cmd.data_array(j) := (others => '0');
			end loop;

		else
			report "PARSE FIFO ERROR: unknown FIFO command" severity error;
			parse_error := true;
			return;
		end if;

		--------------------------------------------------------------------
		-- 5. Assegna valori al comando
		--------------------------------------------------------------------
		cmd.addr   := addr_val;
		cmd.offset := offset_val;

		--------------------------------------------------------------------
		-- 6. Parametri per semantic_check (SOLO quelli sintattici!)
		-- ⭐ NON mettere un PK_DATA per ogni beat: i dati sono in data_array.
		--------------------------------------------------------------------
		cmd.param_kind(1) := PK_ADDR;
		cmd.param_kind(2) := PK_LEN;

		if cmd.command = CMD_FIFO_WRITE or cmd.command = CMD_FIFO_CHECK then
			cmd.param_kind(3) := PK_DATA;  -- solo "c'è un data", non tutti i beat
			cmd.param_count   := 3;
		else
			cmd.param_kind(3) := PK_NONE;
			cmd.param_count   := 2;
		end if;

		cmd.wrap_size := 0;

		--------------------------------------------------------------------
		-- 7. Debug compatto
		--------------------------------------------------------------------
		if ENABLE_DEBUG_LOG then
			report "PARSE " & cmd_to_string(cmd.command) &
				": addr=0x" & slv_to_hex(cmd.addr) &
				" offset=" & integer'image(cmd.offset) &
				" len=" & integer'image(cmd.len);
		end if;

	end procedure;


	--------------------------------------------------------------------
	-- parse_burst: BURST_WRITE / BURST_READ / BURST_CHECK
	-- Sintassi:
	--   BURST_* <addr_expr> [+ offset] <len> <data...>
	--------------------------------------------------------------------
	procedure parse_burst(
		tokens      : in  token_acc_list_t;
		nt          : in  natural;
		cmd         : inout t_cmd;
		parse_error : inout boolean
	) is
		variable idx        : natural := 3;

		variable addr_val_u : unsigned(C_ADDR_WIDTH-1 downto 0);
		variable data_val_u : unsigned(C_DATA_WIDTH-1 downto 0);

		variable addr_val   : t_addr := (others => '0');
		variable offset_val : integer := 0;

		variable len_val    : integer := 0;
	begin
		parse_error := false;

		--------------------------------------------------------------------
		-- DEBUG: ingresso
		--------------------------------------------------------------------
		if ENABLE_DEBUG_LOG then
			report "PB: ENTER parse_burst nt=" & integer'image(nt) &
				" idx_start=" & integer'image(idx)
				severity note;
		end if;

		--------------------------------------------------------------------
		-- 1. ADDR
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind = TK_END then
			report "PARSE BURST ERROR: missing address" severity error;
			parse_error := true;
			return;
		end if;

		if ENABLE_DEBUG_LOG then
			report "PB: ADDR token idx=" & integer'image(idx) &
				" text=" & trim_string(tokens(idx).text)
				severity note;
		end if;

		eval_addr_u(tokens(idx).text, addr_val_u, parse_error);
		if parse_error then
			report "PARSE BURST ERROR: invalid address expression" severity error;
			return;
		end if;

		addr_val := std_logic_vector(addr_val_u);
		idx := idx + 1;

		--------------------------------------------------------------------
		-- 2. OFFSET opzionale "+ <expr>"
		--------------------------------------------------------------------
		if idx <= nt and trim_string(tokens(idx).text) = "+" then
			if ENABLE_DEBUG_LOG then
				report "PB: OFFSET '+' found at idx=" & integer'image(idx)
					severity note;
			end if;

			idx := idx + 1;

			if idx > nt or tokens(idx).kind = TK_END then
				report "PARSE BURST ERROR: missing offset value" severity error;
				parse_error := true;
				return;
			end if;

			if ENABLE_DEBUG_LOG then
				report "PB: OFFSET token idx=" & integer'image(idx) &
					" text=" & trim_string(tokens(idx).text)
					severity note;
			end if;

			eval_expr_i(tokens(idx).text, offset_val, parse_error);
			if parse_error or offset_val < 0 then
				report "PARSE BURST ERROR: invalid offset expression" severity error;
				parse_error := true;
				return;
			end if;

			idx := idx + 1;
		end if;

		--------------------------------------------------------------------
		-- 3. LEN
		--------------------------------------------------------------------
		if idx > nt or tokens(idx).kind /= TK_NUMBER then
			report "PARSE BURST ERROR: missing length" severity error;
			parse_error := true;
			return;
		end if;

		if ENABLE_DEBUG_LOG then
			report "PB: LEN token idx=" & integer'image(idx) &
				" text=" & trim_string(tokens(idx).text)
				severity note;
		end if;

		eval_expr_i(tokens(idx).text, len_val, parse_error);
		if parse_error or len_val <= 0 then
			report "PARSE BURST ERROR: invalid length" severity error;
			parse_error := true;
			return;
		end if;

		--------------------------------------------------------------------
		-- 3b. Limite massimo sulla lunghezza del burst
		--------------------------------------------------------------------
		if len_val > C_MAX_DATA_TOKENS then
			report "PARSE BURST ERROR: length exceeds C_MAX_DATA_TOKENS="
				& integer'image(C_MAX_DATA_TOKENS) severity error;
			parse_error := true;
			return;
		end if;

		cmd.len := len_val;
		idx := idx + 1;

		if ENABLE_DEBUG_LOG then
			report "PB: DATA section start idx=" & integer'image(idx) &
				" len_val=" & integer'image(len_val)
				severity note;
		end if;

		--------------------------------------------------------------------
		-- 4. DATA (solo WRITE e CHECK)
		--------------------------------------------------------------------
		if cmd.command = CMD_BURST_WRITE or cmd.command = CMD_BURST_CHECK then

			for j in 0 to len_val-1 loop

				-- Prima controlliamo idx, poi usiamo tokens(idx)
				if idx > nt or tokens(idx).kind /= TK_NUMBER then
					report "PARSE BURST ERROR: missing data element "
						& integer'image(j) severity error;
					parse_error := true;
					return;
				end if;

				if ENABLE_DEBUG_LOG then
					report "PB: j=" & integer'image(j) &
						" idx=" & integer'image(idx) &
						" nt=" & integer'image(nt) &
						" token=" & trim_string(tokens(idx).text)
						severity note;
				end if;

				eval_data_u(tokens(idx).text, data_val_u, parse_error);
				if parse_error then
					report "PARSE BURST ERROR: invalid data element "
						& integer'image(j) severity error;
					return;
				end if;

				if ENABLE_DEBUG_LOG then
					report "PB: writing cmd.data_array(" & integer'image(j) & ")"
						severity note;
				end if;

				cmd.data_array(j) := std_logic_vector(data_val_u);
				idx := idx + 1;
			end loop;

		elsif cmd.command = CMD_BURST_READ then
			for j in 0 to len_val-1 loop
				cmd.data_array(j) := (others => '0');
			end loop;
		end if;

		if ENABLE_DEBUG_LOG then
			report "PB: EXIT data loop final idx=" & integer'image(idx)
				severity note;
		end if;

		--------------------------------------------------------------------
		-- 5. Assegna valori
		--------------------------------------------------------------------
		cmd.addr   := addr_val;
		cmd.offset := offset_val;

        --------------------------------------------------------------------
        -- 6. Parametri per semantic_check
        --------------------------------------------------------------------
        cmd.param_kind(1) := PK_LEN;   -- len
        cmd.param_kind(2) := PK_ADDR;  -- addr;

        -- Per i BURST non mettiamo un PK_DATA per ogni beat:
        -- i dati sono in cmd.data_array, semantic_check guarda solo len/addr.
        cmd.param_count := 2;

        cmd.wrap_size := 0;

		--------------------------------------------------------------------
		-- 7. Debug finale
		--------------------------------------------------------------------
		if ENABLE_DEBUG_LOG then
			report "PB: EXIT parse_burst OK: len=" & integer'image(cmd.len) &
				" addr=0x" & slv_to_hex(cmd.addr) &
				" offset=" & integer'image(cmd.offset)
				severity note;
		end if;

	end procedure;



    ----------------------------------------------------------------
    -- parse_wrap: WRAP_WRITE / WRAP_READ / WRAP_CHECK
    -- Sintassi reale:
    --   WRAP_* <addr_expr> [+ offset] <wrap_size> <data...>
    ----------------------------------------------------------------
    procedure parse_wrap(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    ) is
        variable idx        : natural := 3;

        variable addr_val_u : unsigned(C_ADDR_WIDTH-1 downto 0);
        variable data_val_u : unsigned(C_DATA_WIDTH-1 downto 0);

        variable addr_val   : t_addr := (others => '0');
        variable offset_val : integer := 0;

        variable wrap_val   : integer := 0;
    begin
        parse_error := false;

        --------------------------------------------------------------------
        -- 1. ADDR (param2 = PK_ADDR)
        --------------------------------------------------------------------
        if idx > nt or tokens(idx).kind = TK_END then
            report "PARSE WRAP ERROR: missing address" severity error;
            parse_error := true;
            return;
        end if;

        eval_addr_u(tokens(idx).text, addr_val_u, parse_error);
        if parse_error then
            report "PARSE WRAP ERROR: invalid address expression" severity error;
            return;
        end if;

        addr_val := std_logic_vector(addr_val_u);
        idx := idx + 1;

        --------------------------------------------------------------------
        -- 2. OFFSET opzionale "+ <expr>"
        --------------------------------------------------------------------
        if idx <= nt and trim_string(tokens(idx).text) = "+" then
            idx := idx + 1;

            if idx > nt or tokens(idx).kind = TK_END then
                report "PARSE WRAP ERROR: missing offset value" severity error;
                parse_error := true;
                return;
            end if;

            eval_expr_i(tokens(idx).text, offset_val, parse_error);
            if parse_error or offset_val < 0 then
                report "PARSE WRAP ERROR: invalid offset expression" severity error;
                parse_error := true;
                return;
            end if;

            idx := idx + 1;
        end if;

        --------------------------------------------------------------------
        -- 3. WRAP_SIZE (param1 = PK_WRAP_SIZE)
        --------------------------------------------------------------------
        if idx > nt or tokens(idx).kind /= TK_NUMBER then
            report "PARSE WRAP ERROR: missing wrap_size" severity error;
            parse_error := true;
            return;
        end if;

        eval_expr_i(tokens(idx).text, wrap_val, parse_error);
        if parse_error or wrap_val <= 0 or wrap_val > 256 then
            report "PARSE WRAP ERROR: invalid wrap_size" severity error;
            parse_error := true;
            return;
        end if;

        cmd.wrap_size := wrap_val;
        cmd.len       := wrap_val;   -- ★ semantic_check richiede len = wrap_size
        idx := idx + 1;

        --------------------------------------------------------------------
        -- 4. DATA (solo WRITE e CHECK)
        --------------------------------------------------------------------
        if cmd.command = CMD_WRAP_WRITE or cmd.command = CMD_WRAP_CHECK then

            for j in 0 to wrap_val-1 loop
                if idx > nt or tokens(idx).kind /= TK_NUMBER then
                    report "PARSE WRAP ERROR: missing data element " &
                        integer'image(j) severity error;
                    parse_error := true;
                    return;
                end if;

                eval_data_u(tokens(idx).text, data_val_u, parse_error);
                if parse_error then
                    report "PARSE WRAP ERROR: invalid data element " &
                        integer'image(j) severity error;
                    parse_error := true;
                    return;
                end if;

                cmd.data_array(j) := std_logic_vector(data_val_u);
                idx := idx + 1;
            end loop;

        elsif cmd.command = CMD_WRAP_READ then
            for j in 0 to wrap_val-1 loop
                cmd.data_array(j) := (others => '0');
            end loop;
        end if;

        --------------------------------------------------------------------
        -- 5. Assegna valori
        --------------------------------------------------------------------
        cmd.addr   := addr_val;
        cmd.offset := offset_val;

		--------------------------------------------------------------------
		-- 6. Parametri per semantic_check (allineati a CMD_SIG)
		-- NON inserire PK_DATA per ogni beat: i dati sono in data_array.
		--------------------------------------------------------------------
		cmd.param_kind(1) := PK_WRAP_SIZE;   -- wrap_size
		cmd.param_kind(2) := PK_ADDR;        -- addr
		cmd.param_count   := 2;

		cmd.wrap_size := wrap_val;

        --------------------------------------------------------------------
        -- 7. Debug
        --------------------------------------------------------------------
        if ENABLE_DEBUG_LOG then
			report "PARSE " & cmd_to_string(cmd.command) &
				": wrap_size=" & integer'image(cmd.wrap_size) &
				" addr=0x" & slv_to_hex(cmd.addr) &
				" offset=" & integer'image(cmd.offset)
				severity note;
		end if;

    end procedure;



    ----------------------------------------------------------------
    -- parse_fill: gestisce FILL_LEN / FILL_RANGE / FILL_CHECK
    ----------------------------------------------------------------
    procedure parse_fill(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    ) is
        variable idx           : natural := 3;

        variable addr_start_u  : unsigned(C_ADDR_WIDTH-1 downto 0);
        variable addr_end_u    : unsigned(C_ADDR_WIDTH-1 downto 0);
        variable data_val_u    : unsigned(C_DATA_WIDTH-1 downto 0);

        variable addr_start    : t_addr := (others => '0');
        variable addr_end      : t_addr := (others => '0');

        variable offset_start  : integer := 0;
        variable offset_end    : integer := 0;

        variable len_val       : integer := 0;
    begin
        parse_error := false;

        --------------------------------------------------------------------
        -- 1. Primo indirizzo (PK_ADDR)
        --------------------------------------------------------------------
        eval_addr_u(tokens(idx).text, addr_start_u, parse_error);
        if parse_error then
            report "PARSE FILL ERROR: invalid start address" severity error;
            return;
        end if;

        idx := idx + 1;

        --------------------------------------------------------------------
        -- 2. OFFSET opzionale per start "+ <expr>"
        --------------------------------------------------------------------
        if idx <= nt and trim_string(tokens(idx).text) = "+" then
            idx := idx + 1;

            eval_expr_i(tokens(idx).text, offset_start, parse_error);
            if parse_error or offset_start < 0 then
                report "PARSE FILL ERROR: invalid start offset" severity error;
                parse_error := true;
                return;
            end if;

            idx := idx + 1;
        end if;

        addr_start := std_logic_vector(unsigned(addr_start_u) + offset_start);

        --------------------------------------------------------------------
        -- 3. Secondo parametro: addr_end oppure len
        --------------------------------------------------------------------
        if cmd.command = CMD_FILL_RANGE then

            ----------------------------------------------------------------
            -- 3a. Secondo indirizzo
            ----------------------------------------------------------------
            eval_addr_u(tokens(idx).text, addr_end_u, parse_error);
            if parse_error then
                report "PARSE FILL_RANGE ERROR: invalid end address" severity error;
                return;
            end if;

            idx := idx + 1;

            ----------------------------------------------------------------
            -- 3b. OFFSET opzionale per end "+ <expr>"
            ----------------------------------------------------------------
            if idx <= nt and trim_string(tokens(idx).text) = "+" then
                idx := idx + 1;

                eval_expr_i(tokens(idx).text, offset_end, parse_error);
                if parse_error or offset_end < 0 then
                    report "PARSE FILL_RANGE ERROR: invalid end offset" severity error;
                    parse_error := true;
                    return;
                end if;

                idx := idx + 1;
            end if;

            addr_end := std_logic_vector(unsigned(addr_end_u) + offset_end);

            ----------------------------------------------------------------
            -- 3c. Calcolo lunghezza
            ----------------------------------------------------------------
            len_val := to_integer(unsigned(addr_end) - unsigned(addr_start)) / (C_DATA_WIDTH/8);

            if len_val <= 0 then
                report "PARSE FILL_RANGE ERROR: invalid range length" severity error;
                parse_error := true;
                return;
            end if;

            cmd.len := len_val;

        else
            ----------------------------------------------------------------
            -- FILL_LEN / FILL_CHECK: len
            ----------------------------------------------------------------
            eval_expr_i(tokens(idx).text, len_val, parse_error);

            if parse_error or len_val <= 0 then
                report "PARSE FILL ERROR: invalid length" severity error;
                parse_error := true;
                return;
            end if;

            cmd.len := len_val;
            idx := idx + 1;
        end if;

        --------------------------------------------------------------------
        -- 4. Valore (PK_DATA)
        --------------------------------------------------------------------
        eval_data_u(tokens(idx).text, data_val_u, parse_error);
        if parse_error then
            report "PARSE FILL ERROR: invalid fill value" severity error;
            return;
        end if;

        cmd.data_array(0) := std_logic_vector(data_val_u);
        idx := idx + 1;

        --------------------------------------------------------------------
        -- 5. Assegna valori
        --------------------------------------------------------------------
        cmd.addr     := addr_start;
        cmd.end_addr := addr_end;
        cmd.offset   := offset_start;  -- solo per start

        --------------------------------------------------------------------
        -- 6. Parametri per semantic_check
        --------------------------------------------------------------------
        cmd.param_kind(1) := PK_ADDR;

        if cmd.command = CMD_FILL_RANGE then
            cmd.param_kind(2) := PK_ADDR;
        else
            cmd.param_kind(2) := PK_LEN;
        end if;

        cmd.param_kind(3) := PK_DATA;

        cmd.param_count := 3;

        --------------------------------------------------------------------
        -- 7. Debug
        --------------------------------------------------------------------
        if ENABLE_DEBUG_LOG then
			report "PARSE " & cmd_to_string(cmd.command) &
				": start=0x" & slv_to_hex(cmd.addr) &
				" end=0x" & slv_to_hex(addr_end) &
				" len=" & integer'image(cmd.len)
				severity note;
		end if;

    end procedure;

    ----------------------------------------------------------------
    -- parse_dump: gestisce DUMP_LEN / DUMP_RANGE / DUMP_FILE_*
    ----------------------------------------------------------------
    procedure parse_dump(
        tokens      : in  token_acc_list_t;
        nt          : in  natural;
        cmd         : inout t_cmd;
        parse_error : inout boolean
    ) is
        variable idx           : natural := 3;

        variable addr_start_u  : unsigned(C_ADDR_WIDTH-1 downto 0);
        variable addr_end_u    : unsigned(C_ADDR_WIDTH-1 downto 0);

        variable addr_start    : t_addr := (others => '0');
        variable addr_end      : t_addr := (others => '0');

        variable offset_start  : integer := 0;
        variable offset_end    : integer := 0;

        variable len_val       : integer := 0;

        variable filename      : t_line := (others => ' ');

		variable dbg_msg : string(1 to 512);
		variable fname   : string(1 to 256);

	begin
        parse_error := false;

        --------------------------------------------------------------------
        -- 1. Primo indirizzo (PK_ADDR)
        --------------------------------------------------------------------
        if idx > nt or tokens(idx).kind = TK_END then
            report "PARSE DUMP ERROR: missing start address" severity error;
            parse_error := true;
            return;
        end if;

        eval_addr_u(tokens(idx).text, addr_start_u, parse_error);
        if parse_error then
            report "PARSE DUMP ERROR: invalid start address" severity error;
            return;
        end if;

        idx := idx + 1;

        --------------------------------------------------------------------
        -- 2. OFFSET opzionale per start "+ <expr>"
        --------------------------------------------------------------------
        if idx <= nt and trim_string(tokens(idx).text) = "+" then
            idx := idx + 1;

            if idx > nt or tokens(idx).kind = TK_END then
                report "PARSE DUMP ERROR: missing start offset" severity error;
                parse_error := true;
                return;
            end if;

            eval_expr_i(tokens(idx).text, offset_start, parse_error);
            if parse_error or offset_start < 0 then
                report "PARSE DUMP ERROR: invalid start offset" severity error;
                parse_error := true;
                return;
            end if;

            idx := idx + 1;
        end if;

        addr_start := std_logic_vector(unsigned(addr_start_u) + offset_start);

        --------------------------------------------------------------------
        -- 3. Secondo parametro: addr_end oppure len
        --------------------------------------------------------------------
        case cmd.command is

            ----------------------------------------------------------------
            -- DUMP_LEN / DUMP_FILE_LEN / DUMP_FILE_CHECK_LEN
            ----------------------------------------------------------------
            when CMD_DUMP_LEN |
                 CMD_DUMP_FILE_LEN |
                 CMD_DUMP_FILE_CHECK_LEN =>

                if idx > nt or tokens(idx).kind /= TK_NUMBER then
                    report "PARSE DUMP ERROR: missing length" severity error;
                    parse_error := true;
                    return;
                end if;

                eval_expr_i(tokens(idx).text, len_val, parse_error);
                if parse_error or len_val <= 0 then
                    report "PARSE DUMP ERROR: invalid length" severity error;
                    parse_error := true;
                    return;
                end if;

                cmd.len := len_val;
                idx := idx + 1;

            ----------------------------------------------------------------
            -- DUMP_RANGE / DUMP_FILE_RANGE / DUMP_FILE_CHECK_RANGE
            ----------------------------------------------------------------
            when CMD_DUMP_RANGE |
                 CMD_DUMP_FILE_RANGE |
                 CMD_DUMP_FILE_CHECK_RANGE =>

                if idx > nt or tokens(idx).kind = TK_END then
                    report "PARSE DUMP_RANGE ERROR: missing end address" severity error;
                    parse_error := true;
                    return;
                end if;

                eval_addr_u(tokens(idx).text, addr_end_u, parse_error);
                if parse_error then
                    report "PARSE DUMP_RANGE ERROR: invalid end address" severity error;
                    return;
                end if;

                idx := idx + 1;

                ----------------------------------------------------------------
                -- OFFSET opzionale per end "+ <expr>"
                ----------------------------------------------------------------
                if idx <= nt and trim_string(tokens(idx).text) = "+" then
                    idx := idx + 1;

                    if idx > nt or tokens(idx).kind = TK_END then
                        report "PARSE DUMP_RANGE ERROR: missing end offset" severity error;
                        parse_error := true;
                        return;
                    end if;

                    eval_expr_i(tokens(idx).text, offset_end, parse_error);
                    if parse_error or offset_end < 0 then
                        report "PARSE DUMP_RANGE ERROR: invalid end offset" severity error;
                        parse_error := true;
                        return;
                    end if;

                    idx := idx + 1;
                end if;

                addr_end := std_logic_vector(unsigned(addr_end_u) + offset_end);

                ----------------------------------------------------------------
                -- Calcolo lunghezza
                ----------------------------------------------------------------
                len_val := to_integer(unsigned(addr_end) - unsigned(addr_start)) / (C_DATA_WIDTH/8);

                if len_val <= 0 then
                    report "PARSE DUMP_RANGE ERROR: invalid range length" severity error;
                    parse_error := true;
                    return;
                end if;

                cmd.len := len_val;

            when others =>
                report "PARSE DUMP ERROR: unknown DUMP command" severity error;
                parse_error := true;
                return;
        end case;

        --------------------------------------------------------------------
        -- 4. Filename (solo DUMP_FILE_*)
        --------------------------------------------------------------------
        case cmd.command is

            when CMD_DUMP_FILE_LEN |
                 CMD_DUMP_FILE_RANGE |
                 CMD_DUMP_FILE_CHECK_LEN |
                 CMD_DUMP_FILE_CHECK_RANGE =>

                if idx > nt or tokens(idx).kind /= TK_STRING then
                    report "PARSE DUMP_FILE ERROR: missing filename" severity error;
                    parse_error := true;
                    return;
                end if;

                cmd.filename := tokens(idx).text;  -- t_line → t_line
                idx := idx + 1;

            when others =>
                null;
        end case;

        --------------------------------------------------------------------
        -- 5. Assegna valori base
        --------------------------------------------------------------------
        cmd.addr := addr_start;
        cmd.end_addr := addr_end;

        --------------------------------------------------------------------
        -- 6. Parametri per semantic_check
        --------------------------------------------------------------------
        case cmd.command is

            when CMD_DUMP_LEN =>
                cmd.param_kind(1) := PK_ADDR;
                cmd.param_kind(2) := PK_LEN;
                cmd.param_count   := 2;

            when CMD_DUMP_RANGE =>
                cmd.param_kind(1) := PK_ADDR;
                cmd.param_kind(2) := PK_ADDR;
                cmd.param_count   := 2;

            when CMD_DUMP_FILE_LEN =>
                cmd.param_kind(1) := PK_ADDR;
                cmd.param_kind(2) := PK_LEN;
                cmd.param_kind(3) := PK_STRING;
                cmd.param_count   := 3;

            when CMD_DUMP_FILE_RANGE =>
                cmd.param_kind(1) := PK_ADDR;
                cmd.param_kind(2) := PK_ADDR;
                cmd.param_kind(3) := PK_STRING;
                cmd.param_count   := 3;

            when CMD_DUMP_FILE_CHECK_LEN =>
                cmd.param_kind(1) := PK_ADDR;
                cmd.param_kind(2) := PK_LEN;
                cmd.param_kind(3) := PK_STRING;
                cmd.param_count   := 3;

            when CMD_DUMP_FILE_CHECK_RANGE =>
                cmd.param_kind(1) := PK_ADDR;
                cmd.param_kind(2) := PK_ADDR;
                cmd.param_kind(3) := PK_STRING;
                cmd.param_count   := 3;

            when others =>
                cmd.param_count := 0;
        end case;

        --------------------------------------------------------------------
        -- 7. Debug
        --------------------------------------------------------------------
        if ENABLE_DEBUG_LOG then
			report "PARSE " & cmd_to_string(cmd.command) &
				": start=0x" & slv_to_hex(cmd.addr) &
				" end=0x" & slv_to_hex(cmd.end_addr) &
				" len=" & integer'image(cmd.len)
				severity note;
		end if;

    end procedure;

end package body cmd_parse_pkg;
