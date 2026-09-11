-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_split_pkg.vhd
--  Author: Dexter
--  Date: 2026-09-06
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmd_cfg.all;
use work.cmd_cmd_pkg.all;
use work.cmd_math_pkg.all;
use work.cmd_text_pkg.all;
use work.cmd_map_pkg.all;

package cmd_split_pkg is

    procedure split_command(
        cmd        : in  t_cmd;
        mc_list_o  : out t_mc_list;
        mc_count_o : out natural
    );

end package cmd_split_pkg;

package body cmd_split_pkg is

    procedure split_command(
        cmd        : in  t_cmd;
        mc_list_o  : out t_mc_list;
        mc_count_o : out natural
    ) is
        constant MAX_BEAT : natural := 256;
		constant BYTES_PER_BEAT  : natural := C_DATA_WIDTH / 8;

		variable bytes_until_boundary : natural;
		variable beats_until_boundary : natural;

        variable base_addr   : t_addr;
        variable curr_addr   : t_addr;
        variable beats_left  : natural;
        variable chunk_len   : natural;
        variable mc_idx      : natural := 0;

        variable curr_u      : unsigned(C_ADDR_WIDTH-1 downto 0);
        variable next_b      : unsigned(C_ADDR_WIDTH-1 downto 0);

        variable beat_index  : natural := 0;

        -- ⭐ Variabile unica per costruire microcomandi
        variable mc : t_mc_cmd;

    begin
        ----------------------------------------------------------------
        -- Reset lista microcomandi
        ----------------------------------------------------------------
        mc_count_o := 0;
        mc_list_o  := (others => mc_clear);

        ----------------------------------------------------------------
        -- Comandi gestiti dal parser
        ----------------------------------------------------------------
        if cmd.command = CMD_SET_VAR or
           cmd.command = CMD_INCLUDE or
           cmd.command = CMD_END_SIM then
            return;
        end if;

		----------------------------------------------------------------
		-- STOP
		----------------------------------------------------------------
		if cmd.command = CMD_STOP then
			mc := mc_clear;
			mc.cmd_type := CMD_STOP;
			mc.cmd_id   := to_unsigned(0, C_ID_WIDTH);

			mc_list_o(0) := mc;
			mc_count_o   := 1;
			return;
		end if;

        ----------------------------------------------------------------
        -- SET_ATOMIC
        ----------------------------------------------------------------
        if cmd.command = CMD_SET_ATOMIC then
            mc := mc_clear;
            mc.cmd_type := CMD_SET_ATOMIC;
            mc.cmd_id   := to_unsigned(0, C_ID_WIDTH);
            mc.atomic   := cmd.atomic;

            mc_list_o(0) := mc;
            mc_count_o   := 1;
            return;
        end if;

        ----------------------------------------------------------------
        -- PRINT
        ----------------------------------------------------------------
        if cmd.command = CMD_PRINT then
            mc := mc_clear;
            mc.cmd_type   := CMD_PRINT;
            mc.cmd_id     := to_unsigned(0, C_ID_WIDTH);
            mc.print_text := cmd.print_text;

            mc_list_o(0) := mc;
            mc_count_o   := 1;
            return;
        end if;

        ----------------------------------------------------------------
        -- WAIT
        ----------------------------------------------------------------
        if cmd.command = CMD_WAIT_TIME or
           cmd.command = CMD_WAIT_CLOCKS or
           cmd.command = CMD_WAIT_SIM_TIME then

            mc := mc_clear;
            mc.cmd_type   := cmd.command;
            mc.cmd_id     := to_unsigned(0, C_ID_WIDTH);
            mc.wait_value := cmd.wait_value;
            mc.wait_unit  := cmd.wait_unit;

            mc_list_o(0) := mc;
            mc_count_o   := 1;
            return;
        end if;

        ----------------------------------------------------------------
        -- READ singolo
        ----------------------------------------------------------------
        if cmd.command = CMD_READ then
            mc := mc_clear;
            mc.cmd_type := CMD_READ;
            mc.cmd_id   := to_unsigned(0, C_ID_WIDTH);
            mc.addr     := cmd.addr;
            mc.len      := 1;

            mc.data_array(0) := (others => '0');
            mc.data          := mc.data_array(0);

            mc_list_o(0) := mc;
            mc_count_o   := 1;
            return;
        end if;

        ----------------------------------------------------------------
        -- WRITE / CHECK singolo
        ----------------------------------------------------------------
        if cmd.command = CMD_WRITE or cmd.command = CMD_CHECK then
            mc := mc_clear;
            mc.cmd_type := cmd.command;
            mc.cmd_id   := to_unsigned(0, C_ID_WIDTH);
            mc.addr     := cmd.addr;
            mc.len      := 1;

            mc.data_array(0) := cmd.data;
            mc.data          := cmd.data;

            mc_list_o(0) := mc;
            mc_count_o   := 1;
            return;
        end if;

		----------------------------------------------------------------
		-- WSTRB_WRITE singolo
		----------------------------------------------------------------
		if cmd.command = CMD_WSTRB_WRITE then
			mc := mc_clear;
			mc.cmd_type    := CMD_WSTRB_WRITE;
			mc.cmd_id      := to_unsigned(0, C_ID_WIDTH);
			mc.addr        := cmd.addr;
			mc.len         := 1;

			mc.data_array(0) := cmd.data;
			mc.data          := cmd.data;

			-- ⭐ nuovo campo
			mc.byte_enable   := cmd.byte_enable;

			mc_list_o(0) := mc;
			mc_count_o   := 1;
			return;
		end if;

        ----------------------------------------------------------------
        -- FIFO
        ----------------------------------------------------------------
        if cmd.command = CMD_FIFO_WRITE or
           cmd.command = CMD_FIFO_READ  or
           cmd.command = CMD_FIFO_CHECK then

            mc := mc_clear;
            mc.cmd_type := cmd.command;
            mc.cmd_id   := to_unsigned(0, C_ID_WIDTH);
            mc.addr     := addr_add_offset(cmd.addr, cmd.offset);
            mc.len      := cmd.len;

            mc.data_array := cmd.data_array;
            mc.data       := mc.data_array(0);

            mc_list_o(0) := mc;
            mc_count_o   := 1;
            return;
        end if;

		----------------------------------------------------------------
		-- BURST / WRAP / FILL
		----------------------------------------------------------------
		if cmd.command = CMD_BURST_WRITE or
		cmd.command = CMD_BURST_READ  or
		cmd.command = CMD_BURST_CHECK or
		cmd.command = CMD_WRAP_WRITE  or
		cmd.command = CMD_WRAP_READ   or
		cmd.command = CMD_WRAP_CHECK  or
		cmd.command = CMD_FILL_LEN    or
		cmd.command = CMD_FILL_CHECK  or
		cmd.command = CMD_FILL_RANGE  then

			base_addr  := addr_add_offset(cmd.addr, cmd.offset);
			curr_addr  := base_addr;
			beats_left := cmd.len;
			beat_index := 0;

			while beats_left > 0 loop

				----------------------------------------------------------------
				-- 1) Limite AXI: massimo 256 beat
				----------------------------------------------------------------
				chunk_len := beats_left;

				if chunk_len > MAX_BEAT then
					chunk_len := MAX_BEAT;
				end if;

				----------------------------------------------------------------
				-- 2) Boundary 4 KB: calcolo in BYTE → poi in BEAT
				----------------------------------------------------------------
				curr_u := unsigned(curr_addr);
				next_b := next_4k_boundary(curr_addr);

				bytes_until_boundary := to_integer(next_b - curr_u);
				beats_until_boundary := bytes_until_boundary / BYTES_PER_BEAT;

				-- evita chunk_len = 0
				if beats_until_boundary = 0 then
					-- siamo a meno di un beat dal boundary → fai almeno 1 beat
					chunk_len := 1;
				elsif beats_until_boundary < chunk_len then
					chunk_len := beats_until_boundary;
				end if;

				----------------------------------------------------------------
				-- 3) Costruzione microcomando
				----------------------------------------------------------------
				mc := mc_clear;
				mc.cmd_type := cmd.command;
				mc.cmd_id   := to_unsigned(mc_idx, C_ID_WIDTH);
				mc.addr     := curr_addr;
				mc.len      := chunk_len;

				----------------------------------------------------------------
				-- BURST_WRITE / BURST_CHECK
				----------------------------------------------------------------
				if cmd.command = CMD_BURST_WRITE or cmd.command = CMD_BURST_CHECK then
					for i in 0 to chunk_len-1 loop
						mc.data_array(i) := cmd.data_array(beat_index + i);
					end loop;

				----------------------------------------------------------------
				-- WRAP_WRITE / WRAP_CHECK
				----------------------------------------------------------------
				elsif cmd.command = CMD_WRAP_WRITE or cmd.command = CMD_WRAP_CHECK then
					for i in 0 to chunk_len-1 loop
						mc.data_array(i) :=
							cmd.data_array((beat_index + i) mod cmd.wrap_size);
					end loop;

				----------------------------------------------------------------
				-- FILL
				----------------------------------------------------------------
				elsif cmd.command = CMD_FILL_LEN or
					cmd.command = CMD_FILL_CHECK or
					cmd.command = CMD_FILL_RANGE then
					for i in 0 to chunk_len-1 loop
						mc.data_array(i) := cmd.data_array(0);
					end loop;
					mc.data := cmd.data_array(0);

				----------------------------------------------------------------
				-- READ
				----------------------------------------------------------------
				else
					mc.data_array(0) := (others => '0');
				end if;

				-- CONSISTENZA
				mc.data := mc.data_array(0);

				----------------------------------------------------------------
				-- ⭐ Protezione overflow microcomandi
				----------------------------------------------------------------
				if mc_idx >= C_MAX_MC then
					report "SPLIT_COMMAND WARNING: microcommand limit reached (" &
						integer'image(C_MAX_MC) & ")" severity warning;

					mc_count_o := C_MAX_MC;  -- evita accesso fuori range
					return;                  -- ⭐ fermati qui
				end if;

				mc_list_o(mc_idx) := mc;

				mc_idx      := mc_idx + 1;
				beats_left  := beats_left - chunk_len;
				beat_index  := beat_index + chunk_len;

				----------------------------------------------------------------
				-- 4) Aggiornamento indirizzo
				----------------------------------------------------------------
				if cmd.command = CMD_WRAP_WRITE or
				cmd.command = CMD_WRAP_READ  or
				cmd.command = CMD_WRAP_CHECK then
					curr_addr := addr_add_offset(
						base_addr,
						(beat_index mod cmd.wrap_size) * BYTES_PER_BEAT
					);
				else
					curr_addr := addr_add_offset(
						curr_addr,
						chunk_len * BYTES_PER_BEAT
					);
				end if;
			end loop;

			mc_count_o := mc_idx;
			return;
		end if;




		----------------------------------------------------------------
		-- POLL
		----------------------------------------------------------------
		if cmd.command = CMD_POLL_READ or
		cmd.command = CMD_POLL_TOGGLE or
		cmd.command = CMD_POLL_PING then

			mc := mc_clear;

			mc.cmd_type   := cmd.command;
			mc.cmd_id     := to_unsigned(0, C_ID_WIDTH);

			mc.addr       := addr_add_offset(cmd.addr, cmd.offset);

			-- ⭐ NON usare più cmd.len per il timeout
			mc.len        := 0;  -- NON usato dal POLL

			----------------------------------------------------------------
			-- ⭐ Valori del POLL
			----------------------------------------------------------------
			if cmd.command = CMD_POLL_READ then
				-- expected + mask
				mc.data_array := cmd.data_array;   -- mask in data_array(0)
				mc.data       := cmd.data;         -- expected

			elsif cmd.command = CMD_POLL_TOGGLE then
				-- solo mask
				mc.data_array := cmd.data_array;   -- mask in data_array(0)
				mc.data       := (others => '0');  -- non usato

			elsif cmd.command = CMD_POLL_PING then
				-- nessun expected, nessuna mask
				mc.data_array := (others => (others => '0'));
				mc.data       := (others => '0');
			end if;

			mc.wait_value := cmd.wait_value;   -- delay tra retry
			mc.timeout    := cmd.timeout;      -- ⭐ numero massimo retry

			mc_list_o(0) := mc;
			mc_count_o   := 1;
			return;
		end if;

		----------------------------------------------------------------
		-- DUMP
		----------------------------------------------------------------
		if cmd.command = CMD_DUMP_LEN or
		cmd.command = CMD_DUMP_RANGE or
		cmd.command = CMD_DUMP_FILE_LEN or
		cmd.command = CMD_DUMP_FILE_RANGE or
		cmd.command = CMD_DUMP_FILE_CHECK_LEN or
		cmd.command = CMD_DUMP_FILE_CHECK_RANGE then

			mc := mc_clear;
			mc.cmd_type := cmd.command;
			mc.cmd_id   := to_unsigned(0, C_ID_WIDTH);
			mc.addr     := addr_add_offset(cmd.addr, cmd.offset);
			mc.end_addr := cmd.end_addr;

			mc.filename := cmd.filename;

			-- ⭐ FIX: usa sempre la lunghezza calcolata dal parser
			mc.len := cmd.len;

			mc.data_array(0) := (others => '0');
			mc.data          := mc.data_array(0);

			mc_list_o(0) := mc;
			mc_count_o   := 1;
			return;
		end if;

    end procedure;

end package body cmd_split_pkg;
