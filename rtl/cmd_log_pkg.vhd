-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_log_pkg.vhd
--  Author: Dexter
--  Date: 2026-09-06
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.cmd_text_pkg.all;
use work.cmd_cfg.all;
use work.cmd_cmd_pkg.all;

package cmd_log_pkg is

    constant MAX_LOG_FILES : natural := 8;

    file f0 : text;
    file f1 : text;
    file f2 : text;
    file f3 : text;
    file f4 : text;
    file f5 : text;
    file f6 : text;
    file f7 : text;

    type bool_array_t is array (0 to MAX_LOG_FILES-1) of boolean;

    -- stato condiviso
    shared variable open_flags : bool_array_t := (others => false);
    shared variable next_tag   : natural      := 0;

    -- API originali
    procedure log_open(filename : in string; tag : out natural);
    procedure log_write(tag : in natural; s : in string);
    procedure log_close(tag : in natural);

    -- API estese
    procedure log_open_write(filename : in string; tag : out natural);
    procedure log_open_read(filename : in string; tag : out natural);
    procedure log_read(tag : in natural; line_out : out t_line);

	impure function log_eof(tag : natural) return boolean;

	subtype t_err_string is string(1 to 64);

	type t_err_info is record
		msg      : t_err_string;
		is_error : boolean;
	end record;

	type t_err_info_table is array (0 to 255) of t_err_info;

	constant C_ERR_INFO : t_err_info_table := (
		0 =>		(msg => "OKAY: Access completed correctly                                ",          is_error => false),
		1 =>		(msg => "EXOKAY: Exclusive access OK                                     ",          is_error => false),
		2 =>		(msg => "SLVERR: Slave internal error                                    ",          is_error => true),
		3 =>		(msg => "DECERR: Address decode error                                    ",          is_error => true),
		4 =>		(msg => "TIMEOUT: No response from slave                                 ",          is_error => true),
		5 =>		(msg => "PROT_ERR: AXI protocol violation                                ",          is_error => true),
		6 =>		(msg => "BOUNDARY_ERR: 4k boundary crossed                               ",          is_error => true),
		7 =>		(msg => "BURST_ERR: Invalid or crossing burst                            ",          is_error => true),
		8 =>		(msg => "ID_ERR: ID mismatch                                             ",          is_error => true),
		others =>	(msg => "USER_DEFINED_ERROR                                              ",          is_error => true)
	);

	procedure decode_err(
		code      : in  std_logic_vector(7 downto 0);
		msg       : out t_err_string;
		is_error  : out boolean
	);

end package cmd_log_pkg;

package body cmd_log_pkg is

    procedure open_generic(filename : in string; mode : in file_open_kind; tag : out natural) is
        variable i : natural;
    begin
        -- cerca un tag libero partendo da next_tag, con wrap-around
        for k in 0 to MAX_LOG_FILES-1 loop
            i := (next_tag + k) mod MAX_LOG_FILES;

            if not open_flags(i) then
                tag := i;

                case i is
                    when 0 => file_open(f0, filename, mode);
                    when 1 => file_open(f1, filename, mode);
                    when 2 => file_open(f2, filename, mode);
                    when 3 => file_open(f3, filename, mode);
                    when 4 => file_open(f4, filename, mode);
                    when 5 => file_open(f5, filename, mode);
                    when 6 => file_open(f6, filename, mode);
                    when 7 => file_open(f7, filename, mode);
                    when others =>
                        report "log_open: invalid tag" severity error;
                end case;

                open_flags(i) := true;
                -- punto di partenza per la prossima ricerca
                next_tag := (i + 1) mod MAX_LOG_FILES;
                return;
            end if;
        end loop;

        report "log_open: no free log slots" severity error;
        tag := 0;
    end procedure;

    procedure log_open(filename : in string; tag : out natural) is
    begin
        open_generic(filename, write_mode, tag);
    end procedure;

    procedure log_open_write(filename : in string; tag : out natural) is
    begin
        open_generic(filename, write_mode, tag);
    end procedure;

    procedure log_open_read(filename : in string; tag : out natural) is
    begin
        open_generic(filename, read_mode, tag);
    end procedure;

    procedure log_write(tag : in natural; s : in string) is
        variable L : line;
    begin
        if tag >= MAX_LOG_FILES or not open_flags(tag) then
            report "log_write: invalid tag" severity error;
            return;
        end if;

        write(L, s);

        case tag is
            when 0 => writeline(f0, L);
            when 1 => writeline(f1, L);
            when 2 => writeline(f2, L);
            when 3 => writeline(f3, L);
            when 4 => writeline(f4, L);
            when 5 => writeline(f5, L);
            when 6 => writeline(f6, L);
            when 7 => writeline(f7, L);
            when others =>
                report "log_write: invalid tag" severity error;
        end case;
    end procedure;

    procedure log_read(tag : in natural; line_out : out t_line) is
        variable L   : line;
        variable tmp : string(1 to C_MAX_STRING);
        variable Len : natural;
    begin
        if tag >= MAX_LOG_FILES or not open_flags(tag) then
            report "log_read: invalid tag" severity error;
            return;
        end if;

        case tag is
            when 0 => readline(f0, L);
            when 1 => readline(f1, L);
            when 2 => readline(f2, L);
            when 3 => readline(f3, L);
            when 4 => readline(f4, L);
            when 5 => readline(f5, L);
            when 6 => readline(f6, L);
            when 7 => readline(f7, L);
            when others =>
                report "log_read: invalid tag" severity error;
        end case;

        Len := L.all'length;
        if Len > C_MAX_STRING then
            Len := C_MAX_STRING;
        end if;

        tmp(1 to Len) := L.all(1 to Len);

        for i in 1 to C_MAX_STRING loop
            if i <= Len then
                line_out(i) := tmp(i);
            else
                line_out(i) := ' ';
            end if;
        end loop;
    end procedure;

    procedure log_close(tag : in natural) is
    begin
        if tag >= MAX_LOG_FILES or not open_flags(tag) then
            report "log_close: invalid tag" severity error;
            return;
        end if;

        case tag is
            when 0 => file_close(f0);
            when 1 => file_close(f1);
            when 2 => file_close(f2);
            when 3 => file_close(f3);
            when 4 => file_close(f4);
            when 5 => file_close(f5);
            when 6 => file_close(f6);
            when 7 => file_close(f7);
            when others =>
                report "log_close: invalid tag" severity error;
        end case;

        open_flags(tag) := false;
        -- opzionale: favorisci il riuso immediato del tag appena chiuso
        next_tag := tag;
    end procedure;

	impure function log_eof(tag : natural) return boolean is
	begin
		case tag is
			when 0 => return endfile(f0);
			when 1 => return endfile(f1);
			when 2 => return endfile(f2);
			when 3 => return endfile(f3);
			when 4 => return endfile(f4);
			when 5 => return endfile(f5);
			when 6 => return endfile(f6);
			when 7 => return endfile(f7);
			when others =>
				report "log_eof: invalid tag" severity error;
				return true;
		end case;
	end function;

	procedure decode_err(
		code      : in  std_logic_vector(7 downto 0);
		msg       : out t_err_string;
		is_error  : out boolean
	) is
		variable idx : natural := to_integer(unsigned(code));
	begin
		if idx <= C_ERR_INFO'high then
			msg      := C_ERR_INFO(idx).msg;
			is_error := C_ERR_INFO(idx).is_error;
		else
			msg      := "UNKNOWN_ERROR                                                   ";
			is_error := true;
		end if;
	end procedure;

end package body cmd_log_pkg;
