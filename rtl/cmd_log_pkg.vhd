-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_log_pkg.vhd
--  Author: Dexter
--  Date: 2026-10-23
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

    ----------------------------------------------------------------------
    -- AXI_FULL (0–15)
    ----------------------------------------------------------------------
    0  => (msg => "AXI_FULL OKAY           : Access completed correctly            ", is_error => false),
    1  => (msg => "AXI_FULL EXOKAY         : Exclusive access OK                   ", is_error => false),
    2  => (msg => "AXI_FULL SLVERR         : Slave internal error                  ", is_error => true),
    3  => (msg => "AXI_FULL DECERR         : Address decode error                  ", is_error => true),
    4  => (msg => "AXI_FULL TIMEOUT        : No response from slave                ", is_error => true),
    5  => (msg => "AXI_FULL PROT_ERR       : Protocol violation                    ", is_error => true),
    6  => (msg => "AXI_FULL BOUNDARY_ERR   : 4k boundary crossed                   ", is_error => true),
    7  => (msg => "AXI_FULL BURST_ERR      : Invalid or crossing burst             ", is_error => true),
    8  => (msg => "AXI_FULL ID_ERR         : ID mismatch                           ", is_error => true),
    9  => (msg => "AXI_FULL WSTRB_ERR      : Invalid write strobe pattern          ", is_error => true),

    10 => (msg => "AXI_FULL UNKNOWN_ERROR  : Unexpected error 0x0A                 ", is_error => true),
    11 => (msg => "AXI_FULL UNKNOWN_ERROR  : Unexpected error 0x0B                 ", is_error => true),
    12 => (msg => "AXI_FULL UNKNOWN_ERROR  : Unexpected error 0x0C                 ", is_error => true),
    13 => (msg => "AXI_FULL UNKNOWN_ERROR  : Unexpected error 0x0D                 ", is_error => true),
    14 => (msg => "AXI_FULL UNKNOWN_ERROR  : Unexpected error 0x0E                 ", is_error => true),
    15 => (msg => "AXI_FULL UNKNOWN_ERROR  : Unexpected error 0x0F                 ", is_error => true),

    ----------------------------------------------------------------------
    -- AXI_LITE (16–31)
    ----------------------------------------------------------------------
    16 => (msg => "AXI_LITE OKAY           : Access completed correctly            ", is_error => false),
    17 => (msg => "AXI_LITE RESERVED_1     : Reserved                              ", is_error => false),
    18 => (msg => "AXI_LITE SLVERR         : Slave internal error                  ", is_error => true),
    19 => (msg => "AXI_LITE DECERR         : Address decode error                  ", is_error => true),
    20 => (msg => "AXI_LITE TIMEOUT        : No response from slave                ", is_error => true),
    21 => (msg => "AXI_LITE PROT_ERR       : Protocol violation                    ", is_error => true),
    22 => (msg => "AXI_LITE BOUNDARY_ERR   : 4k boundary crossed                   ", is_error => true),
    23 => (msg => "AXI_LITE BURST_ERR      : Invalid or crossing burst             ", is_error => true),
    24 => (msg => "AXI_LITE ID_ERR         : ID mismatch                           ", is_error => true),
    25 => (msg => "AXI_LITE WSTRB_ERR      : Invalid write strobe pattern          ", is_error => true),

    26 => (msg => "AXI_LITE UNKNOWN_ERROR  : Unexpected error 0x1A                 ", is_error => true),
    27 => (msg => "AXI_LITE UNKNOWN_ERROR  : Unexpected error 0x1B                 ", is_error => true),
    28 => (msg => "AXI_LITE UNKNOWN_ERROR  : Unexpected error 0x1C                 ", is_error => true),
    29 => (msg => "AXI_LITE UNKNOWN_ERROR  : Unexpected error 0x1D                 ", is_error => true),
    30 => (msg => "AXI_LITE UNKNOWN_ERROR  : Unexpected error 0x1E                 ", is_error => true),
    31 => (msg => "AXI_LITE UNKNOWN_ERROR  : Unexpected error 0x1F                 ", is_error => true),

    ----------------------------------------------------------------------
    -- AHB_FULL (32–47)
    ----------------------------------------------------------------------
    32 => (msg => "AHB_FULL OKAY           : Access completed correctly            ", is_error => false),
    33 => (msg => "AHB_FULL ERROR          : Error response                        ", is_error => true),
    34 => (msg => "AHB_FULL RETRY          : Retry requested by slave              ", is_error => true),
    35 => (msg => "AHB_FULL SPLIT          : Split response from slave             ", is_error => true),
    36 => (msg => "AHB_FULL TIMEOUT        : No response from slave                ", is_error => true),
    37 => (msg => "AHB_FULL PROT_ERR       : Protocol violation                    ", is_error => true),
    38 => (msg => "AHB_FULL BOUNDARY_ERR   : 4k boundary crossed                   ", is_error => true),
    39 => (msg => "AHB_FULL BURST_ERR      : Invalid or crossing burst             ", is_error => true),
    40 => (msg => "AHB_FULL ID_ERR         : ID mismatch                           ", is_error => true),
    41 => (msg => "AHB_FULL WSTRB_ERR      : Invalid write strobe pattern          ", is_error => true),

    42 => (msg => "AHB_FULL UNKNOWN_ERROR  : Unexpected error 0x2A                 ", is_error => true),
    43 => (msg => "AHB_FULL UNKNOWN_ERROR  : Unexpected error 0x2B                 ", is_error => true),
    44 => (msg => "AHB_FULL UNKNOWN_ERROR  : Unexpected error 0x2C                 ", is_error => true),
    45 => (msg => "AHB_FULL UNKNOWN_ERROR  : Unexpected error 0x2D                 ", is_error => true),
    46 => (msg => "AHB_FULL UNKNOWN_ERROR  : Unexpected error 0x2E                 ", is_error => true),
    47 => (msg => "AHB_FULL UNKNOWN_ERROR  : Unexpected error 0x2F                 ", is_error => true),

    ----------------------------------------------------------------------
    -- AHB_LITE (48–63)
    ----------------------------------------------------------------------
    48 => (msg => "AHB_LITE OKAY           : Access completed correctly            ", is_error => false),
    49 => (msg => "AHB_LITE ERROR          : Error response                        ", is_error => true),
    50 => (msg => "AHB_LITE RESERVED_2     : Reserved                              ", is_error => true),
    51 => (msg => "AHB_LITE RESERVED_3     : Reserved                              ", is_error => true),
    52 => (msg => "AHB_LITE TIMEOUT        : No response from slave                ", is_error => true),
    53 => (msg => "AHB_LITE PROT_ERR       : Protocol violation                    ", is_error => true),
    54 => (msg => "AHB_LITE BOUNDARY_ERR   : 4k boundary crossed                   ", is_error => true),
    55 => (msg => "AHB_LITE BURST_ERR      : Invalid or crossing burst             ", is_error => true),
    56 => (msg => "AHB_LITE ID_ERR         : ID mismatch                           ", is_error => true),
    57 => (msg => "AHB_LITE WSTRB_ERR      : Invalid write strobe pattern          ", is_error => true),

    58 => (msg => "AHB_LITE UNKNOWN_ERROR  : Unexpected error 0x3A                 ", is_error => true),
    59 => (msg => "AHB_LITE UNKNOWN_ERROR  : Unexpected error 0x3B                 ", is_error => true),
    60 => (msg => "AHB_LITE UNKNOWN_ERROR  : Unexpected error 0x3C                 ", is_error => true),
    61 => (msg => "AHB_LITE UNKNOWN_ERROR  : Unexpected error 0x3D                 ", is_error => true),
    62 => (msg => "AHB_LITE UNKNOWN_ERROR  : Unexpected error 0x3E                 ", is_error => true),
    63 => (msg => "AHB_LITE UNKNOWN_ERROR  : Unexpected error 0x3F                 ", is_error => true),

    others => (msg => "UNEXPECTED ERROR CODE   : This value is not in the error table  ", is_error => true)
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
