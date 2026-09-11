-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_text_pkg.vhd
--  Author: Dexter
--  Date: 2026-09-06
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmd_cfg.all;

package cmd_text_pkg is

    -- Funzioni su t_line
    function line_clear return t_line;
    function line_trim(s : t_line) return t_line;
    function line_starts_with(s : t_line; prefix : string) return boolean;
    function line_starts_with_line(s : t_line; prefix : t_line) return boolean;
    function line_to_string(s : t_line) return string;
    function line_to_short_string(s : t_line) return string;

    -- Conversioni string <-> t_line
    function trim_string(s : t_line) return string;
    function trim_string_any(s : string) return string;
    function to_t_line(s : string) return t_line;
    function to_string(l : t_line) return string;

    function slv_to_hex(slv : std_logic_vector) return string;

    -- Procedure di supporto su t_line
	procedure assign_string(
		dst : out t_line;
		src : in string
	);

	procedure clean_line(
		raw_line     : in  t_line;
		file_name    : in  string;
		line_number  : in  natural;
		cleaned_line : inout t_line;
		skip_line    : out boolean
	);

end package cmd_text_pkg;

package body cmd_text_pkg is

	--------------------------------------------------------------------
    -- Utility per t_line
    --------------------------------------------------------------------
    function line_clear return t_line is
        variable r : t_line;
    begin
        for i in r'range loop
            r(i) := ' ';
        end loop;
        return r;
    end function;

    function line_trim(s : t_line) return t_line is
        variable r : t_line := line_clear;
        variable p : natural := 1;
    begin
        for i in s'range loop
            if s(i) /= ' ' then
                r(p) := s(i);
                p := p + 1;
            end if;
        end loop;
        return r;
    end function;

	function line_starts_with(s : t_line; prefix : string) return boolean is
	begin
		-- Confronta ogni carattere del prefix
		for i in prefix'range loop
			-- Se la linea finisce prima del prefix → no match
			if s(i) = character'val(0) then
				return false;
			end if;

			-- Mismatch
			if s(i) /= prefix(i) then
				return false;
			end if;
		end loop;

		return true;
	end function;

	function line_starts_with_line(s : t_line; prefix : t_line) return boolean is
	begin
		for i in 1 to C_MAX_STRING loop
			-- Fine prefix
			if prefix(i) = character'val(0) then
				return true;
			end if;

			-- Mismatch
			if s(i) /= prefix(i) then
				return false;
			end if;
		end loop;

		return true;
	end function;

	function line_to_string(s : t_line) return string is
		variable r : string(1 to C_MAX_STRING);
	begin
		for i in r'range loop
			if s(i) = character'val(0) then
				-- Fine stringa → riempi con spazi
				for j in i to C_MAX_STRING loop
					r(j) := ' ';
				end loop;
				return r;
			end if;

			r(i) := s(i);
		end loop;

		return r;
	end function;

	function line_to_short_string(s : t_line) return string is
		variable tmp  : string(1 to C_MAX_STRING);
		variable last : natural := 0;
	begin
		--------------------------------------------------------------------
		-- Copia fino al NUL
		--------------------------------------------------------------------
		for i in 1 to C_MAX_STRING loop
			if s(i) = character'val(0) then
				exit;
			end if;
			tmp(i) := s(i);
		end loop;

		--------------------------------------------------------------------
		-- Trova l'ultimo carattere non spazio
		--------------------------------------------------------------------
		for i in 1 to C_MAX_STRING loop
			if tmp(i) /= ' ' and tmp(i) /= character'val(0) then
				last := i;
			end if;
		end loop;

		--------------------------------------------------------------------
		-- Se tutto spazio → stringa vuota
		--------------------------------------------------------------------
		if last = 0 then
			return "";
		end if;

		--------------------------------------------------------------------
		-- Restituisci SOLO la parte utile
		--------------------------------------------------------------------
		return tmp(1 to last);
	end function;

	--------------------------------------------------------------------
    -- Utility: trim string (rimuove spazi finali)
    --------------------------------------------------------------------
	function trim_string(s : t_line) return string is
		variable last_char : natural := 0;
		variable result    : string(1 to C_MAX_STRING);
	begin
		--------------------------------------------------------------------
		-- Trova l'ultimo carattere utile (non spazio, non NUL)
		--------------------------------------------------------------------
		for i in s'length downto 1 loop
			exit when s(i) = character'val(0);  -- fine stringa

			if s(i) /= ' ' then
				last_char := i;
				exit;
			end if;
		end loop;

		--------------------------------------------------------------------
		-- Linea vuota → restituisci stringa vuota
		--------------------------------------------------------------------
		if last_char = 0 then
			return "";
		end if;

		--------------------------------------------------------------------
		-- Copia i caratteri utili
		--------------------------------------------------------------------
		for i in 1 to last_char loop
			if s(i) = character'val(0) then
				exit;
			end if;
			result(i) := s(i);
		end loop;

		--------------------------------------------------------------------
		-- Restituisci una stringa dinamica con range corretto
		--------------------------------------------------------------------
		return result(1 to last_char);
	end function trim_string;

	function trim_string_any(s : string) return string is
		variable last_char : natural := 1;
		variable result    : string(1 to s'length);
	begin
		-- Trova ultimo carattere non spazio
		for i in s'length downto 1 loop
			if s(i) /= ' ' then
				last_char := i;
				exit;
			end if;
		end loop;

		-- Copia i caratteri utili
		for i in 1 to last_char loop
			result(i) := s(i);
		end loop;

		-- Riempi il resto con spazi
		for i in last_char+1 to s'length loop
			result(i) := ' ';
		end loop;

		return result(1 to last_char);
	end function trim_string_any;

	function to_t_line(s : string) return t_line is
		variable r : t_line := line_clear;
	begin
		for i in s'range loop
			if i <= r'high then
				r(i) := s(i);
			end if;
		end loop;
		return r;
	end function;

	function to_string(l : t_line) return string is
		variable s : string(1 to C_MAX_STRING);
	begin
		for i in 1 to C_MAX_STRING loop
			s(i) := l(i);
		end loop;
		return s;
	end function;

	function slv_to_hex(slv : std_logic_vector) return string is
		constant nibbles : natural := slv'length / 4;
		variable result  : string(1 to nibbles);
		variable nibble  : std_logic_vector(3 downto 0);
		variable val     : natural;
	begin
		for i in 0 to nibbles-1 loop
			nibble := slv(slv'left - i*4 downto slv'left - i*4 - 3);

			val := 0;
			for b in 0 to 3 loop
				if nibble(b) = '1' then
					val := val + (2**b);
				end if;
			end loop;

			if val < 10 then
				result(i+1) := character'val(character'pos('0') + val);
			else
				result(i+1) := character'val(character'pos('A') + (val - 10));
			end if;
		end loop;

		return result;
	end function;

	procedure assign_string(dst : out t_line; src : in string) is
	begin
		dst := line_clear;

		for i in src'range loop
			exit when i > dst'high;

			-- Copia solo caratteri stampabili
			if src(i) = character'val(0) then
				exit;
			end if;

			dst(i) := src(i);
		end loop;
	end procedure;

	procedure clean_line(
		raw_line     : in  t_line;
		file_name    : in  string;
		line_number  : in  natural;
		cleaned_line : inout t_line;
		skip_line    : out boolean
	) is
		variable tmp        : t_line := line_clear;
		variable outl       : t_line := line_clear;
		variable i, o       : natural := 1;
		variable c          : character;
		variable is_print   : boolean := false;
		variable all_spaces : boolean := true;
	begin
		--------------------------------------------------------------------
		-- Stampa RAW (con riga vuota prima per leggibilità)
		--------------------------------------------------------------------
		report "";  -- riga vuota aggiunta

		if ENABLE_DEBUG_LOG then
			report "FILE " & file_name &
				" LINE " & integer'image(line_number) &
				": RAW = '" & to_string(raw_line) & "'" severity note;
		end if;

		--------------------------------------------------------------------
		-- Copia raw_line → tmp rimuovendo NUL e convertendo TAB in spazio
		--------------------------------------------------------------------
		o := 1;
		for j in 1 to C_MAX_STRING loop
			c := raw_line(j);

			if c = character'val(0) then
				exit;  -- fine stringa
			elsif c = HT then
				tmp(o) := ' ';
				o := o + 1;
			else
				tmp(o) := c;
				o := o + 1;
			end if;

			exit when o > C_MAX_STRING;
		end loop;

		--------------------------------------------------------------------
		-- Trim sinistro
		--------------------------------------------------------------------
		i := 1;
		while i <= C_MAX_STRING and tmp(i) = ' ' loop
			i := i + 1;
		end loop;

		o := 1;
		while i <= C_MAX_STRING loop
			exit when tmp(i) = character'val(0);
			outl(o) := tmp(i);
			o := o + 1;
			i := i + 1;
		end loop;

		tmp := outl;
		outl := line_clear;

		--------------------------------------------------------------------
		-- Trim destro
		--------------------------------------------------------------------
		i := C_MAX_STRING;
		while i >= 1 and tmp(i) = ' ' loop
			i := i - 1;
		end loop;

		for j in 1 to i loop
			outl(j) := tmp(j);
		end loop;

		tmp := outl;
		outl := line_clear;

		--------------------------------------------------------------------
		-- Rimuove doppi spazi
		--------------------------------------------------------------------
		o := 1;
		for j in 1 to C_MAX_STRING-1 loop
			exit when tmp(j) = character'val(0);

			if tmp(j) = ' ' and tmp(j+1) = ' ' then
				next;
			end if;

			outl(o) := tmp(j);
			o := o + 1;
			exit when o > C_MAX_STRING;
		end loop;

		tmp := outl;
		outl := line_clear;

		--------------------------------------------------------------------
		-- Righe vuote → skip
		--------------------------------------------------------------------
		all_spaces := true;
		for j in 1 to C_MAX_STRING loop
			exit when tmp(j) = character'val(0);
			if tmp(j) /= ' ' then
				all_spaces := false;
				exit;
			end if;
		end loop;

		if all_spaces then
			skip_line    := true;
			cleaned_line := line_clear;

			if ENABLE_DEBUG_LOG then
				report "FILE " & file_name &
					" LINE " & integer'image(line_number) &
					": Empty line skipped" severity note;
			end if;
			return;
		end if;

		--------------------------------------------------------------------
		-- Righe che iniziano con commento "--"
		--------------------------------------------------------------------
		if tmp(1) = '-' and tmp(2) = '-' then
			skip_line    := true;
			cleaned_line := line_clear;

			if ENABLE_DEBUG_LOG then
				report "FILE " & file_name &
					" LINE " & integer'image(line_number) &
					": Comment-only line skipped" severity note;
			end if;
			return;
		end if;

		--------------------------------------------------------------------
		-- Righe che iniziano con commento "#"
		--------------------------------------------------------------------
		if tmp(1) = '#' then
			skip_line := true;
			cleaned_line := line_clear;

			if ENABLE_DEBUG_LOG then
				report "FILE " & file_name &
					" LINE " & integer'image(line_number) &
					": Comment-only line skipped (#)" severity note;
			end if;
			return;
		end if;

		--------------------------------------------------------------------
		-- Determina se è PRINT
		--------------------------------------------------------------------
		is_print := line_starts_with(tmp, "PRINT");

		--------------------------------------------------------------------
		-- Multiline: se finisce con "\" → NON troncare commenti
		--------------------------------------------------------------------
		if tmp(C_MAX_STRING) = '\' then
			cleaned_line := tmp;

			if ENABLE_DEBUG_LOG then
				report "FILE " & file_name &
					" LINE " & integer'image(line_number) &
					": CLEAN = '" & to_string(cleaned_line) & "'" severity note;
			end if;

			skip_line := false;
			return;
		end if;

		--------------------------------------------------------------------
		-- Commento inline "--" (solo se NON è PRINT)
		--------------------------------------------------------------------
		if not is_print then
			for j in 1 to C_MAX_STRING-1 loop
				if tmp(j) = '-' and tmp(j+1) = '-' then
					for k in 1 to j-1 loop
						outl(k) := tmp(k);
					end loop;

					cleaned_line := outl;

					if ENABLE_DEBUG_LOG then
						report "FILE " & file_name &
							" LINE " & integer'image(line_number) &
							": CLEAN = '" & to_string(cleaned_line) & "'" severity note;
					end if;

					skip_line := false;
					return;
				end if;
			end loop;
		end if;

		--------------------------------------------------------------------
		-- Commento inline "#" (solo se NON è PRINT)
		--------------------------------------------------------------------
		if not is_print then
			for j in 1 to C_MAX_STRING loop
				if tmp(j) = '#' then
					-- Tronca la riga prima del '#'
					for k in 1 to j-1 loop
						outl(k) := tmp(k);
					end loop;

					cleaned_line := outl;

					if ENABLE_DEBUG_LOG then
						report "FILE " & file_name &
							" LINE " & integer'image(line_number) &
							": CLEAN (inline #) = '" & to_string(cleaned_line) & "'" severity note;
					end if;

					skip_line := false;   -- 🔥 NON skippiamo la riga
					return;
				end if;
			end loop;
		end if;

		--------------------------------------------------------------------
		-- Nessun commento inline → linea pulita
		--------------------------------------------------------------------
		cleaned_line := tmp;

		if ENABLE_DEBUG_LOG then
			report "FILE " & file_name &
				" LINE " & integer'image(line_number) &
				": CLEAN = '" & to_string(cleaned_line) & "'" severity note;
		end if;

		skip_line := false;
	end procedure;

end package body cmd_text_pkg;
