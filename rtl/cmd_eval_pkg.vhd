-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_eval_pkg.vhd
--  Author: Dexter
--  Date: 2026-09-06
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmd_cfg.all;
use work.cmd_cmd_pkg.all;      -- t_command, t_mc_cmd
use work.cmd_text_pkg.all;
use work.cmd_math_pkg.all;
use work.cmd_vars_pkg.all;

package cmd_eval_pkg is

    -- Classificazione comandi WRITE
    function is_write_command(c : t_command) return boolean;

    -- Classificazione comandi READ (richiedono dati dal bus)
    function is_read_command(c : t_command) return boolean;

    -- Classificazione comandi CHECK (confrontano dati)
    function is_check_command(c : t_command) return boolean;

    -- Comandi WAIT (temporizzazioni)
    function is_wait_command(c : t_command) return boolean;

    -- Comandi PRINT
    function is_print_command(c : t_command) return boolean;

    -- Comandi BURST / WRAP / FILL / DUMP
    function is_burst_command(c : t_command) return boolean;

    -- SET_VAR
    function is_set_var_command(c : t_command) return boolean;

    -- Lettura o confronto (usato dal top‑level)
    function is_read_or_check(c : t_command) return boolean;

	function is_poll_command(c : t_command) return boolean;

	function is_dump_command(c : t_command) return boolean;

	function is_fifo_command(c : t_command) return boolean;

	function is_end_sim_command(c : t_command) return boolean;

    -- Verifica dati letti (usato dal top‑level)
    function check_read_data(
        cmd     : t_mc_cmd;
        rd_data : std_logic_vector(C_DATA_WIDTH-1 downto 0)
    ) return boolean;

    --------------------------------------------------------------------
    -- Valutazione indirizzi (unsigned)
    --------------------------------------------------------------------
    procedure eval_addr_u(
        s          : in  t_line;
        result     : inout unsigned(C_ADDR_WIDTH-1 downto 0);
        eval_error : inout boolean
    );

    --------------------------------------------------------------------
    -- Valutazione dati (unsigned)
    --------------------------------------------------------------------
    procedure eval_data_u(
        s          : in  t_line;
        result     : inout unsigned(C_DATA_WIDTH-1 downto 0);
        eval_error : inout boolean
    );

    --------------------------------------------------------------------
    -- Valutazione espressioni intere signed
    --------------------------------------------------------------------
    procedure eval_expr_i(
        s          : in  t_line;
        result     : inout integer;
        eval_error : inout boolean
    );

    --------------------------------------------------------------------
    -- Valutazione numeri unsigned generici
    --------------------------------------------------------------------
    procedure eval_number_u(
        s          : in  t_line;
        result     : inout unsigned(31 downto 0);
        eval_error : inout boolean
    );

end package cmd_eval_pkg;

package body cmd_eval_pkg is

    ----------------------------------------------------------------
    -- Comandi WRITE
    ----------------------------------------------------------------
    function is_write_command(c : t_command) return boolean is
    begin
        return (c = CMD_WRITE or
                c = CMD_WSTRB_WRITE or
                c = CMD_FIFO_WRITE or
                c = CMD_BURST_WRITE or
                c = CMD_WRAP_WRITE or
                c = CMD_FILL_LEN or
                c = CMD_FILL_RANGE);
    end function;

    ----------------------------------------------------------------
    -- Comandi READ
    ----------------------------------------------------------------
    function is_read_command(c : t_command) return boolean is
    begin
        return (c = CMD_READ or
                c = CMD_FIFO_READ or
                c = CMD_BURST_READ or
                c = CMD_WRAP_READ or
                c = CMD_POLL_READ);
    end function;

    ----------------------------------------------------------------
    -- Comandi CHECK
    ----------------------------------------------------------------
    function is_check_command(c : t_command) return boolean is
    begin
        return (c = CMD_CHECK or
                c = CMD_FIFO_CHECK or
                c = CMD_BURST_CHECK or
                c = CMD_WRAP_CHECK or
                c = CMD_FILL_CHECK or
                c = CMD_DUMP_FILE_CHECK_LEN or
                c = CMD_DUMP_FILE_CHECK_RANGE);
    end function;

    ----------------------------------------------------------------
    -- Comandi WAIT
    ----------------------------------------------------------------
    function is_wait_command(c : t_command) return boolean is
    begin
        return (c = CMD_WAIT_TIME or
                c = CMD_WAIT_CLOCKS or
                c = CMD_WAIT_SIM_TIME);
    end function;

    ----------------------------------------------------------------
    -- Comandi PRINT
    ----------------------------------------------------------------
    function is_print_command(c : t_command) return boolean is
    begin
        return (c = CMD_PRINT);
    end function;

    ----------------------------------------------------------------
    -- Comandi BURST / WRAP / FILL / DUMP
    ----------------------------------------------------------------
    function is_burst_command(c : t_command) return boolean is
    begin
        return (c = CMD_BURST_WRITE or
                c = CMD_BURST_READ  or
                c = CMD_BURST_CHECK or
                c = CMD_WRAP_WRITE  or
                c = CMD_WRAP_READ   or
                c = CMD_WRAP_CHECK  or
                c = CMD_FILL_LEN    or
                c = CMD_FILL_RANGE  or
                c = CMD_FILL_CHECK  or
                c = CMD_DUMP_LEN        or
                c = CMD_DUMP_RANGE      or
                c = CMD_DUMP_FILE_LEN   or
                c = CMD_DUMP_FILE_RANGE or
                c = CMD_DUMP_FILE_CHECK_LEN or
                c = CMD_DUMP_FILE_CHECK_RANGE);
    end function;

    ----------------------------------------------------------------
    -- SET_VAR
    ----------------------------------------------------------------
    function is_set_var_command(c : t_command) return boolean is
    begin
        return (c = CMD_SET_VAR);
    end function;

    ----------------------------------------------------------------
    -- READ or CHECK
    ----------------------------------------------------------------
    function is_read_or_check(c : t_command) return boolean is
    begin
        return is_read_command(c) or is_check_command(c);
    end function;

	function is_poll_command(c : t_command) return boolean is
	begin
		case c is
			when CMD_POLL_READ |
				CMD_POLL_TOGGLE |
				CMD_POLL_PING =>
				return true;
			when others =>
				return false;
		end case;
	end function;

	function is_dump_command(c : t_command) return boolean is
	begin
		case c is
			when CMD_DUMP_LEN |
				CMD_DUMP_RANGE |
				CMD_DUMP_FILE_LEN |
				CMD_DUMP_FILE_RANGE |
				CMD_DUMP_FILE_CHECK_LEN |
				CMD_DUMP_FILE_CHECK_RANGE =>
				return true;
			when others =>
				return false;
		end case;
	end function;

	function is_fifo_command(c : t_command) return boolean is
	begin
		case c is
			when CMD_FIFO_WRITE |
				CMD_FIFO_READ |
				CMD_FIFO_CHECK =>
				return true;
			when others =>
				return false;
		end case;
	end function;

	function is_end_sim_command(c : t_command) return boolean is
	begin
		return c = CMD_END_SIM;
	end function;

    ----------------------------------------------------------------
    -- Verifica dati letti
    ----------------------------------------------------------------
    function check_read_data(
        cmd     : t_mc_cmd;
        rd_data : std_logic_vector(C_DATA_WIDTH-1 downto 0)
    ) return boolean is
    begin
        case cmd.cmd_type is

            when CMD_CHECK =>
                return (cmd.data = rd_data);

            when CMD_READ |
                 CMD_FIFO_READ |
                 CMD_POLL_READ =>
                return true;

            when CMD_BURST_READ |
                 CMD_BURST_CHECK |
                 CMD_WRAP_READ |
                 CMD_WRAP_CHECK =>
                -- versione semplificata: non abbiamo più data_array
                return true;

            when others =>
                return true;
        end case;
    end function;

	----------------------------------------------------------------
	-- eval_addr_u (con lookup variabili)
	----------------------------------------------------------------
	procedure eval_addr_u(
		s          : in  t_line;
		result     : inout unsigned(C_ADDR_WIDTH-1 downto 0);
		eval_error : inout boolean
	) is
		variable str     : string(1 to C_MAX_STRING);
		variable src     : string(1 to C_MAX_STRING);
		variable first   : natural := 1;
		variable last    : natural := 0;
		variable len     : natural := 0;

		variable base    : natural := 10;
		variable tmp_val : t_addr := (others => '0');
		variable digit   : natural := 0;
		variable i       : natural := 1;
		variable c       : character;

		-- variabili per lookup
		variable var_val : t_addr;
		variable found   : boolean;
	begin
		eval_error := false;
		result     := (others => '0');

		----------------------------------------------------------------
		-- LOOKUP VARIABILE PRIMA DI QUALSIASI PARSING NUMERICO
		----------------------------------------------------------------
		get_var_value(s, var_val, found);
		if found then
			result := unsigned(var_val);
			eval_error := false;
			return;
		end if;

		----------------------------------------------------------------
		-- PARSING NUMERICO STANDARD
		----------------------------------------------------------------
		src := line_to_string(s);

		-- trim sinistro
		first := 1;
		while first <= C_MAX_STRING and src(first) = ' ' loop
			first := first + 1;
		end loop;

		if first > C_MAX_STRING then
			eval_error := true;
			return;
		end if;

		-- trim destro
		last := C_MAX_STRING;
		while last >= first and src(last) = ' ' loop
			last := last - 1;
		end loop;

		len := last - first + 1;

		for k in 1 to C_MAX_STRING loop
			if k <= len then
				str(k) := src(first + k - 1);
			else
				str(k) := ' ';
			end if;
		end loop;

		if len = 0 then
			eval_error := true;
			return;
		end if;

		-- skip spazi
		i := 1;
		while i <= len and str(i) = ' ' loop
			i := i + 1;
		end loop;

		-- base
		base := 10;

		if i + 1 <= len then
			if str(i) = '0' and (str(i+1) = 'x' or str(i+1) = 'X') then
				base := 16;
				i := i + 2;
			elsif str(i) = '0' and (str(i+1) = 'b' or str(i+1) = 'B') then
				base := 2;
				i := i + 2;
			end if;
		end if;

		-- parse
		tmp_val := (others => '0');

		while i <= len loop
			c := str(i);

			exit when c = ' ';

			if base = 10 then
				exit when not (c >= '0' and c <= '9');
				digit := character'pos(c) - character'pos('0');

				tmp_val := addr_add_offset(addr_shift_left(tmp_val, 1), digit);
				tmp_val := addr_shift_left(tmp_val, 1);
				tmp_val := addr_shift_left(tmp_val, 1);

			elsif base = 16 then
				if c >= '0' and c <= '9' then
					digit := character'pos(c) - character'pos('0');
				elsif c >= 'A' and c <= 'F' then
					digit := character'pos(c) - character'pos('A') + 10;
				elsif c >= 'a' and c <= 'f' then
					digit := character'pos(c) - character'pos('a') + 10;
				else
					eval_error := true;
					return;
				end if;

				tmp_val := addr_add_offset(addr_shift_left(tmp_val, 4), digit);

			elsif base = 2 then
				exit when not (c = '0' or c = '1');
				digit := character'pos(c) - character'pos('0');

				tmp_val := addr_add_offset(addr_shift_left(tmp_val, 1), digit);
			end if;

			i := i + 1;
		end loop;

		result := unsigned(tmp_val);
	end procedure;


    ----------------------------------------------------------------
    -- eval_data_u
    ----------------------------------------------------------------
    procedure eval_data_u(
        s          : in  t_line;
        result     : inout unsigned(C_DATA_WIDTH-1 downto 0);
        eval_error : inout boolean
    ) is
        variable str     : string(1 to C_MAX_STRING);
        variable src     : string(1 to C_MAX_STRING);
        variable first   : natural := 1;
        variable last    : natural := 0;
        variable len     : natural := 0;

        variable base    : natural := 10;
        variable tmp_val : t_data := (others => '0');
        variable digit   : natural := 0;
        variable i       : natural := 1;
        variable c       : character;
    begin
        eval_error := false;
        result     := (others => '0');

        src := line_to_string(s);

        -- trim sinistro
        first := 1;
        while first <= C_MAX_STRING and src(first) = ' ' loop
            first := first + 1;
        end loop;

        if first > C_MAX_STRING then
            eval_error := true;
            return;
        end if;

        -- trim destro
        last := C_MAX_STRING;
        while last >= first and src(last) = ' ' loop
            last := last - 1;
        end loop;

        len := last - first + 1;

        for k in 1 to C_MAX_STRING loop
            if k <= len then
                str(k) := src(first + k - 1);
            else
                str(k) := ' ';
            end if;
        end loop;

        if len = 0 then
            eval_error := true;
            return;
        end if;

        -- skip spazi
        i := 1;
        while i <= len and str(i) = ' ' loop
            i := i + 1;
        end loop;

        -- base
        base := 10;

        if i + 1 <= len then
            if str(i) = '0' and (str(i+1) = 'x' or str(i+1) = 'X') then
                base := 16;
                i := i + 2;
            elsif str(i) = '0' and (str(i+1) = 'b' or str(i+1) = 'B') then
                base := 2;
                i := i + 2;
            end if;
        end if;

        -- parse
        tmp_val := (others => '0');

        while i <= len loop
            c := str(i);

            exit when c = ' ';

            if base = 10 then
                exit when not (c >= '0' and c <= '9');
                digit := character'pos(c) - character'pos('0');

                tmp_val := data_add_offset(data_shift_left(tmp_val, 1), digit);
                tmp_val := data_shift_left(tmp_val, 1);
                tmp_val := data_shift_left(tmp_val, 1);

            elsif base = 16 then
                if c >= '0' and c <= '9' then
                    digit := character'pos(c) - character'pos('0');
                elsif c >= 'A' and c <= 'F' then
                    digit := character'pos(c) - character'pos('A') + 10;
                elsif c >= 'a' and c <= 'f' then
                    digit := character'pos(c) - character'pos('a') + 10;
                else
                    eval_error := true;
                    return;
                end if;

                tmp_val := data_add_offset(data_shift_left(tmp_val, 4), digit);

            elsif base = 2 then
                exit when not (c = '0' or c = '1');
                digit := character'pos(c) - character'pos('0');

                tmp_val := data_add_offset(data_shift_left(tmp_val, 1), digit);
            end if;

            i := i + 1;
        end loop;

        result := unsigned(tmp_val);
    end procedure;

    ----------------------------------------------------------------
    -- eval_expr_i
    ----------------------------------------------------------------
    procedure eval_expr_i(
        s          : in  t_line;
        result     : inout integer;
        eval_error : inout boolean
    ) is
        variable str      : string(1 to C_MAX_STRING);
        variable i        : natural := 1;
        variable len      : natural := 0;
        variable c        : character;
        variable acc      : integer := 0;
        variable term_val : integer := 0;
        variable sign     : integer := +1;

        variable base     : natural := 10;
        variable digit    : natural := 0;

        variable first    : natural := 1;
        variable last     : natural := 0;
        variable src      : string(1 to C_MAX_STRING);
    begin
        eval_error := false;
        result     := 0;

        src := line_to_string(s);

        first := 1;
        while first <= C_MAX_STRING and src(first) = ' ' loop
            first := first + 1;
        end loop;

        if first > C_MAX_STRING then
            eval_error := true;
            return;
        end if;

        last := C_MAX_STRING;
        while last >= first and src(last) = ' ' loop
            last := last - 1;
        end loop;

        len := last - first + 1;

        for k in 1 to C_MAX_STRING loop
            if k <= len then
                str(k) := src(first + k - 1);
            else
                str(k) := ' ';
            end if;
        end loop;

        if len = 0 then
            eval_error := true;
            return;
        end if;

        i    := 1;
        acc  := 0;
        sign := +1;

        while i <= len loop

            if str(i) = '+' then
                sign := +1;
                i := i + 1;
            elsif str(i) = '-' then
                sign := -1;
                i := i + 1;
            end if;

            while i <= len and str(i) = ' ' loop
                i := i + 1;
            end loop;

            if i > len then
                eval_error := true;
                return;
            end if;

            base := 10;

            if i + 1 <= len then
                if str(i) = '0' and (str(i+1) = 'x' or str(i+1) = 'X') then
                    base := 16;
                    i := i + 2;
                elsif str(i) = '0' and (str(i+1) = 'b' or str(i+1) = 'B') then
                    base := 2;
                    i := i + 2;
                end if;
            end if;

            term_val := 0;

            while i <= len loop
                c := str(i);

                exit when c = ' ' or c = '+' or c = '-';

                if base = 10 then
                    exit when not (c >= '0' and c <= '9');
                    digit := character'pos(c) - character'pos('0');
                    term_val := term_val * 10 + digit;

                elsif base = 16 then
                    if c >= '0' and c <= '9' then
                        digit := character'pos(c) - character'pos('0');
                    elsif c >= 'A' and c <= 'F' then
                        digit := character'pos(c) - character'pos('A') + 10;
                    elsif c >= 'a' and c <= 'f' then
                        digit := character'pos(c) - character'pos('a') + 10;
                    else
                        eval_error := true;
                        return;
                    end if;
                    term_val := term_val * 16 + digit;

                elsif base = 2 then
                    exit when not (c = '0' or c = '1');
                    digit := character'pos(c) - character'pos('0');
                    term_val := term_val * 2 + digit;

                end if;

                i := i + 1;
            end loop;

            -- Applica il segno
            acc := acc + sign * term_val;

            -- Salta spazi
            while i <= len and str(i) = ' ' loop
                i := i + 1;
            end loop;

            -- Se c'è altro, deve essere + o -
            if i <= len then
                if str(i) /= '+' and str(i) /= '-' then
                    eval_error := true;
                    return;
                end if;
            end if;

        end loop;

        result := acc;
    end procedure;

        ----------------------------------------------------------------
    -- eval_number_u: valuta un numero unsigned generico (dec/hex/bin)
    ----------------------------------------------------------------
    procedure eval_number_u(
        s          : in  t_line;
        result     : inout unsigned(31 downto 0);
        eval_error : inout boolean
    ) is
        variable str     : string(1 to C_MAX_STRING);
        variable base    : natural := 10;
        variable tmp_val : unsigned(31 downto 0) := (others => '0');
        variable i       : natural := 1;
        variable c       : character;
        variable digit   : natural;
    begin
        eval_error := false;
        result     := (others => '0');

        str := line_to_string(s);

        -- Skip leading spaces
        while i <= C_MAX_STRING and str(i) = ' ' loop
            i := i + 1;
        end loop;

        -- Detect base
        if i + 1 <= C_MAX_STRING then
            if str(i) = '0' and (str(i+1) = 'x' or str(i+1) = 'X') then
                base := 16;
                i := i + 2;
            elsif str(i) = '0' and (str(i+1) = 'b' or str(i+1) = 'B') then
                base := 2;
                i := i + 2;
            end if;
        end if;

        -- Parse digits
        while i <= C_MAX_STRING loop
            c := str(i);

            exit when c = ' ' or c = character'val(0);

            if base = 10 then
                exit when not (c >= '0' and c <= '9');
                digit := character'pos(c) - character'pos('0');
                tmp_val := tmp_val * 10 + to_unsigned(digit, 32);

            elsif base = 16 then
                if c >= '0' and c <= '9' then
                    digit := character'pos(c) - character'pos('0');
                elsif c >= 'A' and c <= 'F' then
                    digit := character'pos(c) - character'pos('A') + 10;
                elsif c >= 'a' and c <= 'f' then
                    digit := character'pos(c) - character'pos('a') + 10;
                else
                    eval_error := true;
                    exit;
                end if;
                tmp_val := tmp_val * 16 + to_unsigned(digit, 32);

            elsif base = 2 then
                exit when not (c = '0' or c = '1');
                digit := character'pos(c) - character'pos('0');
                tmp_val := tmp_val * 2 + to_unsigned(digit, 32);
            end if;

            i := i + 1;
        end loop;

        result := tmp_val;
    end procedure;

end package body cmd_eval_pkg;
