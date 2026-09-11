-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_file_pkg.vhd
--  Author: Dexter
--  Date: 2026-09-06
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

use work.cmd_cfg.all;
use work.cmd_text_pkg.all;
use work.cmd_cmd_pkg.all;      -- t_cmd, t_mc_cmd, t_mc_list
use work.cmd_parse_pkg.all;
use work.cmd_semantic_pkg.all;
use work.cmd_split_pkg.all;    -- split_command
use work.cmd_eval_pkg.all;     -- check_read_data, is_read_or_check
use work.cmd_math_pkg.all;
use work.cmd_time_pkg.all;
use work.cmd_log_pkg.all;

package cmd_file_pkg is

    --------------------------------------------------------------------
    -- Verifica se un file è già nello stack degli include
    --------------------------------------------------------------------
	function is_in_include_stack(
		tag   : natural;
		depth : natural;
		stack : include_stack_t
	) return boolean;

    --------------------------------------------------------------------
    -- Pulizia della riga letta dal file
    --------------------------------------------------------------------
    procedure clean_line(
        raw_line     : in  t_line;
        file_name    : in  string;
        line_number  : in  natural;
        cleaned_line : inout t_line;
        skip_line    : out boolean
    );

    --------------------------------------------------------------------
    -- Processa un file di comandi:
    -- - gestisce INCLUDE
    -- - legge le righe
    -- - chiama clean_line
    -- - aggiorna include_depth e include_stack
    -- - produce micro-comandi già espansi
    -- - segnala END_SIM
    -- - segnala errori
    --------------------------------------------------------------------
	procedure process_file(
		mc_list_o     : inout t_mc_list;
		mc_count_o    : inout natural;
		include_stack : inout include_stack_t;
		include_depth : inout natural;
		end_sim_o     : out   boolean;
		parse_error_o : inout boolean;
		error_count_o : inout natural;
		dry_run       : in    boolean
	);

end package cmd_file_pkg;

package body cmd_file_pkg is

	--------------------------------------------------------------------
	-- Verifica se un tag è già nello stack degli include
	--------------------------------------------------------------------
	function is_in_include_stack(
		tag   : natural;
		depth : natural;
		stack : include_stack_t
	) return boolean is
	begin
		for i in 1 to depth loop
			if stack(i).tag = tag then
				return true;
			end if;
		end loop;

		return false;
	end function;


	--------------------------------------------------------------------
	-- Pulizia della riga
	--------------------------------------------------------------------
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
		if ENABLE_DEBUG_LOG then
			report "";
			report "FILE " & file_name &
				" LINE " & integer'image(line_number) &
				": RAW = '" & to_string(raw_line) & "'" severity note;
		end if;

		----------------------------------------------------------------
		-- COPIA raw_line → tmp
		-- Patch: rimozione esplicita di LF (10) e CR (13)
		----------------------------------------------------------------
		o := 1;
		for j in 1 to C_MAX_STRING loop
			c := raw_line(j);

			if c = character'val(0) then
				exit;

			elsif c = HT then
				-- TAB → spazio
				tmp(o) := ' ';
				o := o + 1;

			elsif c = character'val(10) then   -- LF
				-- Vivado include LF → rimuovere
				null;

			elsif c = character'val(13) then   -- CR
				-- Vivado include CR → rimuovere
				null;

			else
				-- copia il carattere così com'è (incluso '\')
				tmp(o) := c;
				o := o + 1;
			end if;

			exit when o > C_MAX_STRING;
		end loop;

		----------------------------------------------------------------
		-- Trim sinistro
		----------------------------------------------------------------
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

		----------------------------------------------------------------
		-- Trim destro
		----------------------------------------------------------------
		i := C_MAX_STRING;
		while i >= 1 and tmp(i) = ' ' loop
			i := i - 1;
		end loop;

		for j in 1 to i loop
			outl(j) := tmp(j);
		end loop;

		tmp := outl;
		outl := line_clear;

		----------------------------------------------------------------
		-- Rimuove doppi spazi
		----------------------------------------------------------------
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

		----------------------------------------------------------------
		-- Riga vuota
		----------------------------------------------------------------
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

		----------------------------------------------------------------
		-- Commenti "--"
		----------------------------------------------------------------
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

		----------------------------------------------------------------
		-- Commenti "#"
		----------------------------------------------------------------
		if tmp(1) = '#' then
			skip_line    := true;
			cleaned_line := line_clear;

			if ENABLE_DEBUG_LOG then
				report "FILE " & file_name &
					" LINE " & integer'image(line_number) &
					": Comment-only line skipped (#)" severity note;
			end if;
			return;
		end if;

		----------------------------------------------------------------
		-- PRINT
		----------------------------------------------------------------
		is_print := line_starts_with(tmp, "PRINT");

		----------------------------------------------------------------
		-- Multiline "\" → NON troncare
		----------------------------------------------------------------
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

		----------------------------------------------------------------
		-- Commento inline "--"
		----------------------------------------------------------------
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

		----------------------------------------------------------------
		-- Commento inline "#"
		----------------------------------------------------------------
		if not is_print then
			for j in 1 to C_MAX_STRING loop
				if tmp(j) = '#' then
					for k in 1 to j-1 loop
						outl(k) := tmp(k);
					end loop;

					cleaned_line := outl;

					if ENABLE_DEBUG_LOG then
						report "FILE " & file_name &
							" LINE " & integer'image(line_number) &
							": CLEAN (inline #) = '" & to_string(cleaned_line) & "'" severity note;
					end if;

					skip_line := false;
					return;
				end if;
			end loop;
		end if;

		----------------------------------------------------------------
		-- Default: linea pulita
		----------------------------------------------------------------
		cleaned_line := tmp;

		if ENABLE_DEBUG_LOG then
			report "FILE " & file_name &
				" LINE " & integer'image(line_number) &
				": CLEAN = '" & to_string(cleaned_line) & "'" severity note;
		end if;

		skip_line := false;
	end procedure clean_line;

	--------------------------------------------------------------------
	-- PROCESS_FILE — lettura file comandi (streaming + dry_run)
	--------------------------------------------------------------------
	procedure process_file(
		mc_list_o     : inout t_mc_list;
		mc_count_o    : inout natural;
		include_stack : inout include_stack_t;
		include_depth : inout natural;
		end_sim_o     : out   boolean;
		parse_error_o : inout boolean;
		error_count_o : inout natural;
		dry_run       : in    boolean
	) is
		variable tl            : t_line;
		variable cmd           : t_cmd;
		variable parse_error   : boolean;
		variable sem_ok        : boolean;

		variable tmp_mcs       : t_mc_list;
		variable tmp_count     : natural;

		variable skip_line     : boolean;
		variable continue_flag : boolean;
		variable suppress_start: boolean;
		variable tokens_acc    : token_acc_list_t;
		variable nt_acc        : natural;

		variable new_tag       : natural;
		variable current_tag   : natural;

		variable depth_backup  : integer;
		variable inc_line      : natural;

	begin

		current_tag := include_stack(include_depth).tag;

		end_sim_o     := false;
		parse_error_o := false;

		--------------------------------------------------------------------
		-- DRY_RUN → lettura completa del file (con recursion)
		--------------------------------------------------------------------
		if dry_run then
			while not log_eof(current_tag) loop

				-- Leggi una riga
				log_read(current_tag, tl);

				include_stack(include_depth).line_number :=
					include_stack(include_depth).line_number + 1;

				skip_line := false;

				clean_line(
					raw_line     => tl,
					file_name    => trim_string(include_stack(include_depth).filename),
					line_number  => include_stack(include_depth).line_number,
					cleaned_line => tl,
					skip_line    => skip_line
				);

				if skip_line then
					next;
				end if;

				-- Parse + multilinea
				tokens_acc      := (others => (kind => TK_START, text => line_clear));
				nt_acc          := 0;
				suppress_start  := false;
				continue_flag   := false;

				parse_line(
					line          => tl,
					cmd           => cmd,
					parse_error   => parse_error,
					continue_flag => continue_flag,
					suppress_start=> suppress_start,
					tokens_acc    => tokens_acc,
					nt_acc        => nt_acc
				);

				if parse_error then
					error_count_o := error_count_o + 1;
					parse_error_o := true;
					next;
				end if;

				----------------------------------------------------------------
				-- Multilinea
				----------------------------------------------------------------
				while continue_flag loop
					if log_eof(current_tag) then
						exit;
					end if;

					log_read(current_tag, tl);

					include_stack(include_depth).line_number :=
						include_stack(include_depth).line_number + 1;

					skip_line := false;

					clean_line(
						raw_line     => tl,
						file_name    => trim_string(include_stack(include_depth).filename),
						line_number  => include_stack(include_depth).line_number,
						cleaned_line => tl,
						skip_line    => skip_line
					);

					if skip_line then
						continue_flag  := true;
						suppress_start := true;
						next;
					end if;

					parse_line(
						line          => tl,
						cmd           => cmd,
						parse_error   => parse_error,
						continue_flag => continue_flag,
						suppress_start=> true,
						tokens_acc    => tokens_acc,
						nt_acc        => nt_acc
					);

					if parse_error then
						error_count_o := error_count_o + 1;
						parse_error_o := true;
						exit;
					end if;
				end loop;

				----------------------------------------------------------------
				-- INCLUDE → dry_run (ricorsivo)
				----------------------------------------------------------------
				if cmd.command = CMD_INCLUDE then

					log_open_read(trim_string(cmd.filename), new_tag);

					if is_in_include_stack(new_tag, include_depth, include_stack) then
						error_count_o := error_count_o + 1;
					else
						depth_backup := include_depth;

						include_depth := include_depth + 1;

						include_stack(include_depth).tag         := new_tag;
						include_stack(include_depth).filename    := cmd.filename;
						include_stack(include_depth).line_number := 0;

						inc_line := 0;

						process_file(
							mc_list_o,
							mc_count_o,
							include_stack,
							include_depth,
							end_sim_o,
							parse_error_o,
							error_count_o,
							dry_run
						);

						include_stack(depth_backup + 1).tag         := 0;
						include_stack(depth_backup + 1).filename    := (others => ' ');
						include_stack(depth_backup + 1).line_number := 0;

						include_depth := depth_backup;
					end if;

					next;
				end if;

				----------------------------------------------------------------
				-- Semantic check
				----------------------------------------------------------------
				semantic_check(cmd, sem_ok);

				if not sem_ok then
					error_count_o := error_count_o + 1;
					next;
				end if;

				----------------------------------------------------------------
				-- Generazione microcomandi (solo se non dry_run)
				----------------------------------------------------------------
				split_command(cmd, tmp_mcs, tmp_count);

				if not dry_run then
					for i in 0 to tmp_count-1 loop
						tmp_mcs(i).cmd_id := ID_PARSER;
					end loop;

					for i in 0 to tmp_count-1 loop
						mc_list_o(mc_count_o + i) := tmp_mcs(i);
					end loop;

					mc_count_o := mc_count_o + tmp_count;
				end if;
			end loop;

			log_close(current_tag);

			include_stack(include_depth).tag         := 0;
			include_stack(include_depth).filename    := (others => ' ');
			include_stack(include_depth).line_number := 0;

			include_depth := include_depth - 1;

			return;
		end if;

		--------------------------------------------------------------------
		-- STREAMING → una sola riga alla volta
		--------------------------------------------------------------------
		if log_eof(current_tag) then
			return;
		end if;

		-- Leggi UNA sola riga
		log_read(current_tag, tl);

		include_stack(include_depth).line_number :=
			include_stack(include_depth).line_number + 1;

		skip_line := false;

		clean_line(
			raw_line     => tl,
			file_name    => trim_string(include_stack(include_depth).filename),
			line_number  => include_stack(include_depth).line_number,
			cleaned_line => tl,
			skip_line    => skip_line
		);

		if skip_line then
			return;
		end if;

		-- Parse + multilinea
		tokens_acc      := (others => (kind => TK_START, text => line_clear));
		nt_acc          := 0;
		suppress_start  := false;
		continue_flag   := false;

		parse_line(
			line          => tl,
			cmd           => cmd,
			parse_error   => parse_error,
			continue_flag => continue_flag,
			suppress_start=> suppress_start,
			tokens_acc    => tokens_acc,
			nt_acc        => nt_acc
		);

		if parse_error then
			error_count_o := error_count_o + 1;
			parse_error_o := true;
			return;
		end if;

		--------------------------------------------------------------------
		-- Multilinea streaming
		--------------------------------------------------------------------
		while continue_flag loop
			if log_eof(current_tag) then
				exit;
			end if;

			log_read(current_tag, tl);

			include_stack(include_depth).line_number :=
				include_stack(include_depth).line_number + 1;

			skip_line := false;

			clean_line(
				raw_line     => tl,
				file_name    => trim_string(include_stack(include_depth).filename),
				line_number  => include_stack(include_depth).line_number,
				cleaned_line => tl,
				skip_line    => skip_line
			);

			if skip_line then
				continue_flag  := true;
				suppress_start := true;
				next;
			end if;

			parse_line(
				line          => tl,
				cmd           => cmd,
				parse_error   => parse_error,
				continue_flag => continue_flag,
				suppress_start=> true,
				tokens_acc    => tokens_acc,
				nt_acc        => nt_acc
			);

			if parse_error then
				error_count_o := error_count_o + 1;
				parse_error_o := true;
				return;
			end if;
		end loop;

		--------------------------------------------------------------------
		-- INCLUDE → streaming
		--------------------------------------------------------------------
		if cmd.command = CMD_INCLUDE then

			log_open_read(trim_string(cmd.filename), new_tag);

			if is_in_include_stack(new_tag, include_depth, include_stack) then
				error_count_o := error_count_o + 1;
				return;
			end if;

			include_depth := include_depth + 1;

			include_stack(include_depth).tag         := new_tag;
			include_stack(include_depth).filename    := cmd.filename;
			include_stack(include_depth).line_number := 0;

			return;
		end if;

		--------------------------------------------------------------------
		-- Semantic check
		--------------------------------------------------------------------
		semantic_check(cmd, sem_ok);

		if not sem_ok then
			error_count_o := error_count_o + 1;
			return;
		end if;

		--------------------------------------------------------------------
		-- END_SIM → segnala al parser, NON genera microcomandi
		--------------------------------------------------------------------
		if cmd.command = CMD_END_SIM then
			end_sim_o := true;

			mc_list_o  := (others => mc_clear);
			mc_count_o := 0;

			return;
		end if;

		--------------------------------------------------------------------
		-- Generazione microcomandi della riga corrente
		--------------------------------------------------------------------
		split_command(cmd, tmp_mcs, tmp_count);

		for i in 0 to tmp_count-1 loop
			tmp_mcs(i).cmd_id := ID_PARSER;
		end loop;

		for i in 0 to tmp_count-1 loop
			mc_list_o(mc_count_o + i) := tmp_mcs(i);
		end loop;

		mc_count_o := mc_count_o + tmp_count;

	end procedure process_file;

end package body cmd_file_pkg;
