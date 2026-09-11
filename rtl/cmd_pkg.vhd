-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_pkg.vhd
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
use work.cmd_lex_pkg.all;
use work.cmd_parse_pkg.all;
use work.cmd_semantic_pkg.all;
use work.cmd_split_pkg.all;

package cmd_pkg is

    --------------------------------------------------------------------
    -- API pubblica del parser minimale
    --------------------------------------------------------------------
    procedure process_line(
        raw_line      : in  t_line;
        file_name     : in  string;
        line_number   : in  natural;
        mc_list_o     : out t_mc_list;
        mc_count_o    : out natural;
        end_sim_o     : out boolean;
        parse_error_o : inout boolean
    );

end package cmd_pkg;

package body cmd_pkg is

    procedure process_line(
        raw_line      : in  t_line;
        file_name     : in  string;
        line_number   : in  natural;
        mc_list_o     : out t_mc_list;
        mc_count_o    : out natural;
        end_sim_o     : out boolean;
        parse_error_o : inout boolean
    ) is
        variable cleaned_line : t_line;
        variable skip_line    : boolean;

        variable tokens       : token_list_t;
        variable nt           : natural;
        variable continue_f   : boolean;

        variable tokens_acc   : token_acc_list_t;
        variable nt_acc       : natural := 0;

        variable cmd          : t_cmd;
        variable sem_ok       : boolean;
    begin

        ----------------------------------------------------------------
        -- 1. Clean line (gestisce commenti, spazi, righe vuote)
        ----------------------------------------------------------------
        clean_line(raw_line, file_name, line_number, cleaned_line, skip_line);
        if skip_line then
            mc_count_o    := 0;
            end_sim_o     := false;
            parse_error_o := false;
            return;
        end if;

        ----------------------------------------------------------------
        -- 2. Tokenize (semantic tokenizer)
        ----------------------------------------------------------------
        tokenize_semantic(cleaned_line, tokens, nt, continue_f, false);
        if continue_f then
            mc_count_o    := 0;
            end_sim_o     := false;
            parse_error_o := false;
            return;
        end if;

        ----------------------------------------------------------------
        -- 3. Ricostruzione accumulator per parse_base
        ----------------------------------------------------------------
        nt_acc := 0;
        for i in 1 to nt loop
            nt_acc := nt_acc + 1;
            tokens_acc(nt_acc) := tokens(i);
        end loop;

        ----------------------------------------------------------------
        -- 4. Parse sintattico
        ----------------------------------------------------------------
        parse_base(tokens_acc, nt_acc, cmd, parse_error_o);
        if parse_error_o then
            mc_count_o    := 0;
            end_sim_o     := false;
            return;
        end if;

        ----------------------------------------------------------------
        -- 5. Semantic check
        ----------------------------------------------------------------
        semantic_check(cmd, sem_ok);
        if not sem_ok then
            parse_error_o := true;
            mc_count_o    := 0;
            end_sim_o     := false;
            return;
        end if;

        ----------------------------------------------------------------
        -- 6. Split in microcomandi (t_mc_cmd)
        ----------------------------------------------------------------
        split_command(cmd, mc_list_o, mc_count_o);

        ----------------------------------------------------------------
        -- 7. END_SIM?
        ----------------------------------------------------------------
        end_sim_o := (cmd.command = CMD_END_SIM);

    end procedure process_line;

end package body cmd_pkg;
