-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_semantic_pkg.vhd
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
use work.cmd_eval_pkg.all;
use work.cmd_math_pkg.all;
use work.cmd_time_pkg.all;

package cmd_semantic_pkg is

    --------------------------------------------------------------------
    -- Semantic check
    -- Verifica che il comando sia semanticamente valido:
    -- - numero parametri
    -- - tipo parametri
    -- - range
    -- - coerenza con CMD_SIG
    --------------------------------------------------------------------
    procedure semantic_check(
        cmd       : in  t_cmd;
        parser_ok : out boolean
    );

end package cmd_semantic_pkg;

package body cmd_semantic_pkg is

    --------------------------------------------------------------------
    -- Semantic check FULL — allineato a CMD_SIG, parser e AXI
    --------------------------------------------------------------------
    procedure semantic_check(
        cmd       : in  t_cmd;
        parser_ok : out boolean
    ) is
        variable sig       : t_cmd_signature;
        variable start_u   : unsigned(C_ADDR_WIDTH-1 downto 0);
        variable end_u     : unsigned(C_ADDR_WIDTH-1 downto 0);
        variable range_len : natural;
    begin
        parser_ok := true;

        ----------------------------------------------------------------
        -- 1. Recupera la signature del comando
        ----------------------------------------------------------------
        sig := CMD_SIG(cmd.command);

        ----------------------------------------------------------------
        -- 2. Controllo numero parametri
        ----------------------------------------------------------------
        if (cmd.param_count < sig.min_params) or
           (cmd.param_count > sig.max_params) then

            report "[ERROR] SEMANTIC: wrong number of parameters for "
                & t_command'image(cmd.command)
                severity error;

            parser_ok := false;
            return;
        end if;

        if ENABLE_DEBUG_LOG then
			report "SEM: param_count=" & integer'image(cmd.param_count)
				severity note;
		end if;

		if ENABLE_DEBUG_LOG then
			report "SEM: param_kind range=" &
				integer'image(cmd.param_kind'low) & " .. " &
				integer'image(cmd.param_kind'high)
				severity note;
		end if;

        ----------------------------------------------------------------
        -- 3. Controllo tipi dei parametri (PK_ADDR, PK_DATA, PK_LEN…)
        ----------------------------------------------------------------
        for i in 1 to cmd.param_count loop
            if cmd.param_kind(i) /= sig.param_kinds(i) then
                report "[ERROR] SEMANTIC: parameter " & integer'image(i)
                    & " has wrong type for command "
                    & t_command'image(cmd.command)
                    severity error;

                parser_ok := false;
                return;
            end if;
        end loop;

        ----------------------------------------------------------------
        -- 4. Controllo allineamento indirizzi (word-aligned)
        ----------------------------------------------------------------
        if sig.needs_alignment then
            if (to_integer(unsigned(cmd.addr)) mod 4) /= 0 then
                report "[ERROR] SEMANTIC: unaligned address"
                    severity error;
                parser_ok := false;
                return;
            end if;

            -- RANGE: param2 = PK_ADDR → controlla anche end_addr
            if sig.param_kinds(2) = PK_ADDR then
                if (to_integer(unsigned(cmd.end_addr)) mod 4) /= 0 then
                    report "[ERROR] SEMANTIC: unaligned end address"
                        severity error;
                    parser_ok := false;
                    return;
                end if;
            end if;
        end if;

        ----------------------------------------------------------------
        -- 5. Controllo LEN > 0 SOLO per comandi LEN veri
        ----------------------------------------------------------------
        if cmd.command = CMD_FILL_LEN or
           cmd.command = CMD_FILL_CHECK or
           cmd.command = CMD_DUMP_LEN or
           cmd.command = CMD_DUMP_FILE_LEN or
           cmd.command = CMD_DUMP_FILE_CHECK_LEN then

            if cmd.len = 0 then
                report "[ERROR] SEMANTIC: LEN must be > 0"
                    severity error;
                parser_ok := false;
                return;
            end if;
        end if;

        ----------------------------------------------------------------
        -- 6. Controllo RANGE (start/end) e dimensione massima
        ----------------------------------------------------------------
        if (sig.param_kinds(1) = PK_ADDR) and
           (sig.param_kinds(2) = PK_ADDR) and
           (sig.max_params = 3) then

            start_u := unsigned(cmd.addr);
            end_u   := unsigned(cmd.end_addr);

			if end_u < start_u then
                report "[ERROR] SEMANTIC: range end < start"
                    severity error;
                parser_ok := false;
                return;
            end if;

            -- lunghezza in beat (byte / (C_DATA_WIDTH/8))
            range_len := unsigned_diff(end_u, start_u) / (C_DATA_WIDTH/8);

            if range_len > C_MAX_DATA_TOKENS then
                report "[ERROR] SEMANTIC: range too large"
                    severity error;
                parser_ok := false;
                return;
            end if;
        end if;

        ----------------------------------------------------------------
        -- 7. Controllo BURST (max C_MAX_DATA_TOKENS)
        ----------------------------------------------------------------
        if sig.is_burst and not sig.is_wrap then
            if cmd.len = 0 then
                report "[ERROR] SEMANTIC: BURST len must be > 0"
                    severity error;
                parser_ok := false;
                return;
            end if;

            if cmd.len > C_MAX_DATA_TOKENS then
                report "[ERROR] SEMANTIC: BURST len exceeds C_MAX_DATA_TOKENS"
                    severity error;
                parser_ok := false;
                return;
            end if;
        end if;

        ----------------------------------------------------------------
        -- 8. Controllo WRAP (AXI WRAP “vero”, max 256 beat)
        ----------------------------------------------------------------
        if sig.is_wrap then
            if cmd.wrap_size = 0 then
                report "[ERROR] SEMANTIC: WRAP size must be > 0"
                    severity error;
                parser_ok := false;
                return;
            end if;

            if cmd.wrap_size > 256 then
                report "[ERROR] SEMANTIC: WRAP size exceeds 256 (AXI limit)"
                    severity error;
                parser_ok := false;
                return;
            end if;

            -- WRAP: len = wrap_size
            if cmd.len /= cmd.wrap_size then
                report "[ERROR] SEMANTIC: WRAP size mismatch"
                    severity error;
                parser_ok := false;
                return;
            end if;
        end if;

		----------------------------------------------------------------
		-- 9. Controllo POLL (timeout)
		----------------------------------------------------------------
		if cmd.command = CMD_POLL_READ or
		cmd.command = CMD_POLL_TOGGLE then

			-- timeout = cmd.timeout, deve essere > 0
			if cmd.timeout = 0 then
				report "[ERROR] SEMANTIC: POLL invalid timeout (must be > 0)"
					severity error;
				parser_ok := false;
				return;
			end if;

		elsif cmd.command = CMD_POLL_PING then

			-- timeout = cmd.timeout, può essere 0 (0 = MAX_TIMEOUT)
			-- nessun controllo aggiuntivo
			null;

		end if;

        ----------------------------------------------------------------
        -- 10. Controllo FILE (string non vuota)
        ----------------------------------------------------------------
        if sig.param_kinds(3) = PK_STRING then
            if trim_string(cmd.filename) = "" then
                report "[ERROR] SEMANTIC: filename missing"
                    severity error;
                parser_ok := false;
                return;
            end if;
        end if;

    end procedure;

end package body cmd_semantic_pkg;
