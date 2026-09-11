-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_time_pkg.vhd
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

package cmd_time_pkg is

    --------------------------------------------------------------------
    -- decode_time_unit
    -- Converte una stringa (t_line) in un fattore di scala temporale.
    --
    -- Esempi:
    --   "ns" → 1
    --   "us" → 1000
    --   "ms" → 1000000
    --   "s"  → 1000000000
    --
    -- Il parser usa questo valore per convertire:
    --   WAIT 10 us
    --   WAIT 5 ms
    --   WAIT 1 s
    --------------------------------------------------------------------
    function decode_time_unit(str : t_line) return t_time_unit;

end package cmd_time_pkg;

package body cmd_time_pkg is

    --------------------------------------------------------------------
    -- Decodifica unità di tempo
    --------------------------------------------------------------------
	function decode_time_unit(str : t_line) return t_time_unit is
		variable s_norm   : string(1 to C_MAX_STRING);
		variable tmp_line : t_line := line_clear;
	begin
		--------------------------------------------------------------------
		-- Converti t_line → string
		--------------------------------------------------------------------
		s_norm := line_to_string(str);

		--------------------------------------------------------------------
		-- Normalizza a minuscolo
		--------------------------------------------------------------------
		for i in s_norm'range loop
			if s_norm(i) >= 'A' and s_norm(i) <= 'Z' then
				s_norm(i) := character'val(character'pos(s_norm(i)) + 32);
			end if;
		end loop;

		--------------------------------------------------------------------
		-- Debug
		--------------------------------------------------------------------
		if ENABLE_DEBUG_LOG then
			report "DECODE_TIME_UNIT: normalized = '" & s_norm & "'" severity note;
		end if;

		--------------------------------------------------------------------
		-- Converti string → t_line per line_starts_with
		--------------------------------------------------------------------
		assign_string(tmp_line, s_norm);

		--------------------------------------------------------------------
		-- Confronto diretto con le unità
		--------------------------------------------------------------------
		if line_starts_with(tmp_line, "ns") then
			return TU_NS;

		elsif line_starts_with(tmp_line, "us") then
			return TU_US;

		elsif line_starts_with(tmp_line, "ms") then
			return TU_MS;

		elsif line_starts_with(tmp_line, "sec") or
			line_starts_with(tmp_line, "s") then
			return TU_SEC;

		elsif line_starts_with(tmp_line, "clk") or
			line_starts_with(tmp_line, "clocks") then
			return TU_CLK;

		elsif line_starts_with(tmp_line, "sim") or
			line_starts_with(tmp_line, "simulation") or
			line_starts_with(tmp_line, "simtime") then
			return TU_SIM;
		end if;

		--------------------------------------------------------------------
		-- Nessun match
		--------------------------------------------------------------------
		return TU_NONE;
	end function;

end package body cmd_time_pkg;
