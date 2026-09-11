-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_vars_pkg.vhd
--  Author: Dexter
--  Date: 2026-09-06
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmd_cfg.all;
use work.cmd_text_pkg.all;

package cmd_vars_pkg is

    --------------------------------------------------------------------
    -- Costanti
    --------------------------------------------------------------------
    constant C_MAX_VARS : integer := 128;

    --------------------------------------------------------------------
    -- Tipi
    --------------------------------------------------------------------
    type t_var_table is array (0 to C_MAX_VARS-1) of t_line;
    type t_val_table is array (0 to C_MAX_VARS-1) of t_addr;

    --------------------------------------------------------------------
    -- Variabili globali
    --------------------------------------------------------------------
    shared variable var_names  : t_var_table := (others => (others => ' '));
    shared variable var_values : t_val_table := (others => (others => '0'));

    --------------------------------------------------------------------
    -- API
    --------------------------------------------------------------------
    procedure get_var_value(
        name  : in  t_line;
        value : inout t_addr;
        found : out boolean
    );

    procedure set_var(
        name  : in t_line;
        value : in t_addr
    );

    procedure debug_var_table;

end package cmd_vars_pkg;


package body cmd_vars_pkg is

    --------------------------------------------------------------------
    -- Lookup variabile
    --------------------------------------------------------------------
	procedure get_var_value(
		name  : in  t_line;
		value : inout t_addr;
		found : out boolean
	) is
	begin
		for i in var_names'range loop
			if trim_string(var_names(i)) = trim_string(name) then
				value := var_values(i);
				found := true;

				-- Stampa debug: variabile trovata
				if ENABLE_DEBUG_LOG then
					report "GET_VAR: found '" & trim_string(name)
						& "' = 0x" & slv_to_hex(value);
				end if;

				return;
			end if;
		end loop;

		-- Variabile non trovata
		value := (others => '0');
		found := false;

		if ENABLE_DEBUG_LOG then
			report "GET_VAR: variable '" & trim_string(name)
				& "' not found";
		end if;
	end procedure;

    --------------------------------------------------------------------
    -- Set variabile
    --------------------------------------------------------------------
	procedure set_var(
		name  : in t_line;
		value : in t_addr
	) is
	begin
		-- Cerca variabile esistente o slot libero
		for i in var_names'range loop
			if trim_string(var_names(i)) = trim_string(name) or
			trim_string(var_names(i)) = "" then

				var_names(i)  := name;
				var_values(i) := value;

				-- Stampa conferma salvataggio
				if ENABLE_DEBUG_LOG then
					report "SET_VAR: saved '" & trim_string(name)
						& "' = 0x" & slv_to_hex(value);
				end if;

				return;
			end if;
		end loop;

		-- Nessuno slot disponibile → warning
		report "SET_VAR WARNING: variable table full, cannot store '"
			& trim_string(name) & "'" severity warning;
	end procedure;


    --------------------------------------------------------------------
    -- Debug variabili
    --------------------------------------------------------------------
    procedure debug_var_table is
    begin
        report "---- VARIABLE TABLE ----";
        for i in var_names'range loop
            if trim_string(var_names(i)) /= "" then
                report "VAR[" & integer'image(i) & "] "
                    & trim_string(var_names(i))
                    & " = 0x" & slv_to_hex(var_values(i));
            end if;
        end loop;
        report "------------------------";
    end procedure;

end package body cmd_vars_pkg;
