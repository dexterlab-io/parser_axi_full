-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_micro_pkg.vhd
--  Author: Dexter
--  Date: 2026-09-06
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmd_cfg.all;
use work.cmd_cmd_pkg.all;

package cmd_micro_pkg is

    --------------------------------------------------------------------
    -- COSTANTI MICRO-COMANDI
    --------------------------------------------------------------------
    constant C_MAX_MICRO_CMDS : natural := 1024;
    constant C_MAX_DATA       : natural := C_MAX_DATA_TOKENS;

    --------------------------------------------------------------------
    -- MICRO-COMANDO (dopo lo split)
    --------------------------------------------------------------------
    type t_mc_buffer_kind is (
        MC_SINGLE,
        MC_LARGE
    );

    --------------------------------------------------------------------
    -- BUFFER DI LETTURA
    --------------------------------------------------------------------
    type t_read_burst_array is array(0 to C_MAX_DATA-1) of t_data;
    type t_read_buffer      is array(0 to C_MAX_MICRO_CMDS-1) of t_read_burst_array;
    type t_read_len_array   is array(0 to C_MAX_MICRO_CMDS-1) of integer;

    --------------------------------------------------------------------
    -- ARRAY PER BUFFER KIND
    --------------------------------------------------------------------
    type t_mc_buffer_kind_array is array(0 to C_MAX_MICRO_CMDS-1) of t_mc_buffer_kind;

    --------------------------------------------------------------------
    -- ARRAY PER DATA SINGLE
    --------------------------------------------------------------------
    type t_data_single_array is array(0 to C_MAX_MICRO_CMDS-1) of t_data;

    --------------------------------------------------------------------
    -- ARRAY PER DATA LARGE
    --------------------------------------------------------------------
    type t_data_large_matrix is array(0 to C_MAX_MICRO_CMDS-1) of t_data_array;

end package cmd_micro_pkg;

package body cmd_micro_pkg is
end package body cmd_micro_pkg;
