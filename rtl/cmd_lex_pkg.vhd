-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_lex_pkg.vhd
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

package cmd_lex_pkg is

    --------------------------------------------------------------------
    -- Funzioni di analisi caratteri (lexer base)
    --------------------------------------------------------------------
    function is_letter(c : character) return boolean;
    function is_digit(c : character) return boolean;
    function is_hex_digit(c : character) return boolean;
    function is_operator(c : character) return boolean;

    --------------------------------------------------------------------
    -- Debug dei token
    --------------------------------------------------------------------
    procedure dump_token(
        idx : natural;
        t   : t_token
    );

    --------------------------------------------------------------------
    -- Tokenizzazione semantica
    -- Converte una riga pulita in token_acc_list_t
    --------------------------------------------------------------------
	procedure tokenize_semantic(
		line           : in  t_line;
		tokens         : inout token_list_t;
		nt             : inout natural;
		continue_flag  : out boolean;
		suppress_start : in  boolean
	);

end package cmd_lex_pkg;

package body cmd_lex_pkg is

    --------------------------------------------------------------------
    -- Utility di caratteri
    --------------------------------------------------------------------
	function is_letter(c : character) return boolean is
	begin
		return (c >= 'A' and c <= 'Z') or
			(c >= 'a' and c <= 'z') or
			(c = '_');
	end function;

	function is_digit(c : character) return boolean is
	begin
		return (c >= '0' and c <= '9');
	end function;

	function is_hex_digit(c : character) return boolean is
	begin
		return is_digit(c) or
			(c >= 'A' and c <= 'F') or
			(c >= 'a' and c <= 'f');
	end function;

	function is_operator(c : character) return boolean is
	begin
		return (c = '+') or (c = '\');
	end function;

		procedure dump_token(idx : natural; t : t_token) is
		begin
			if ENABLE_DEBUG_LOG then
				report "TOK " & integer'image(idx) &
					": " & t_token_kind'image(t.kind) &
					" """ & trim_string(t.text) & """";
			end if;
		end procedure;

	----------------------------------------------------------------
	-- Semantic tokenizer (minimal form-based classification)
	----------------------------------------------------------------
	procedure tokenize_semantic(
		line           : in  t_line;
		tokens         : inout token_list_t;
		nt             : inout natural;
		continue_flag  : out boolean;
		suppress_start : in  boolean
	) is
		variable i   : natural := 1;
		variable pos : natural := 1;
		variable c   : character;
		variable tmp : t_line := line_clear;

	begin
		--------------------------------------------------------------------
		-- Reset del flag (evita deadlock)
		--------------------------------------------------------------------
		continue_flag := false;

		--------------------------------------------------------------------
		-- TK_START (solo se suppress_start = FALSE)
		--------------------------------------------------------------------
		if not suppress_start then
			nt := 1;
			tokens(nt).kind := TK_START;
			tokens(nt).text := line_clear;
			dump_token(nt, tokens(nt));
		else
			nt := 0;
		end if;

		--------------------------------------------------------------------
		-- Tokenizzazione carattere per carattere
		--------------------------------------------------------------------
		while i <= C_MAX_STRING loop
			c := line(i);

			if c = ' ' then
				i := i + 1;
				next;
			end if;

			if c = character'val(0) then
				exit;
			end if;

			-- OPERATORI
			if c = '+' or c = '\' then
				tmp := line_clear;
				tmp(1) := c;

				nt := nt + 1;
				tokens(nt).kind := TK_OPERATOR;
				tokens(nt).text := tmp;
				dump_token(nt, tokens(nt));

				i := i + 1;
				next;
			end if;

			-- STRINGA "..."
			if c = '"' then
				tmp := line_clear;
				pos := 1;
				i := i + 1;

				while i <= C_MAX_STRING and line(i) /= '"' loop
					tmp(pos) := line(i);
					pos := pos + 1;
					i := i + 1;
				end loop;

				nt := nt + 1;
				tokens(nt).kind := TK_STRING;
				tokens(nt).text := tmp;
				dump_token(nt, tokens(nt));

				if i <= C_MAX_STRING then
					i := i + 1;
				end if;

				next;
			end if;

			-- NUMERI
			if is_digit(c) then
				tmp := line_clear;
				pos := 1;

				while i <= C_MAX_STRING and
					(is_digit(line(i)) or
					is_hex_digit(line(i)) or
					line(i) = 'x' or line(i) = 'X' or
					line(i) = 'b' or line(i) = 'B') loop

					tmp(pos) := line(i);
					pos := pos + 1;
					i := i + 1;
				end loop;

				nt := nt + 1;
				tokens(nt).kind := TK_NUMBER;
				tokens(nt).text := tmp;
				dump_token(nt, tokens(nt));

				if i <= C_MAX_STRING and is_letter(line(i)) then
					tmp := line_clear;
					pos := 1;

					while i <= C_MAX_STRING and is_letter(line(i)) loop
						tmp(pos) := line(i);
						pos := pos + 1;
						i := i + 1;
					end loop;

					nt := nt + 1;
					tokens(nt).kind := TK_STRING;
					tokens(nt).text := tmp;
					dump_token(nt, tokens(nt));
				end if;

				next;
			end if;

			-- STRING GENERICA
			tmp := line_clear;
			pos := 1;

			while i <= C_MAX_STRING and
				line(i) /= ' ' and
				line(i) /= '+' and
				line(i) /= '"' and
				line(i) /= '\' loop

				tmp(pos) := line(i);
				pos := pos + 1;
				i := i + 1;
			end loop;

			nt := nt + 1;
			tokens(nt).kind := TK_STRING;
			tokens(nt).text := tmp;
			dump_token(nt, tokens(nt));

			next;
		end loop;

		--------------------------------------------------------------------
		-- Gestione del backslash finale
		--------------------------------------------------------------------
		if nt >= 1 and tokens(nt).kind = TK_OPERATOR and trim_string(tokens(nt).text) = "\" then
			nt := nt - 1;          -- rimuovi "\"
			continue_flag := true; -- segnala continuazione
			return;                -- NON generare TK_END
		end if;

		--------------------------------------------------------------------
		-- TK_END finale
		--------------------------------------------------------------------
		nt := nt + 1;
		tokens(nt).kind := TK_END;
		tokens(nt).text := line_clear;
		dump_token(nt, tokens(nt));
	end procedure;

end package body cmd_lex_pkg;
