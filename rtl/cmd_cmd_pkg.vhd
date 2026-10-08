-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_cmd_pkg.vhd
--  Author: Dexter
--  Date: 2026-09-06
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmd_cfg.all;
use work.cmd_text_pkg.all;

package cmd_cmd_pkg is

    --------------------------------------------------------------------
    -- ARRAY DI DATI PER COMANDO LOGICO
    --------------------------------------------------------------------
    type t_data_array is array(0 to C_MAX_DATA_TOKENS-1) of t_data;

    --------------------------------------------------------------------
    -- ENUMERAZIONE DEI COMANDI
    --------------------------------------------------------------------
    type t_command is (
        CMD_NOP,

        CMD_SET_VAR,
        CMD_INCLUDE,
        CMD_PRINT,
        CMD_END_SIM,

        CMD_SET_ATOMIC,

        CMD_WAIT_TIME,
        CMD_WAIT_CLOCKS,
        CMD_WAIT_SIM_TIME,

        CMD_WSTRB_WRITE,

        CMD_WRITE,
        CMD_READ,
        CMD_CHECK,

        CMD_FIFO_WRITE,
        CMD_FIFO_READ,
        CMD_FIFO_CHECK,

        CMD_BURST_WRITE,
        CMD_BURST_READ,
        CMD_BURST_CHECK,

        CMD_WRAP_WRITE,
        CMD_WRAP_READ,
        CMD_WRAP_CHECK,

        CMD_FILL_LEN,
        CMD_FILL_RANGE,
        CMD_FILL_CHECK,

        CMD_POLL_READ,
        CMD_POLL_TOGGLE,
        CMD_POLL_PING,

        CMD_DUMP_LEN,
        CMD_DUMP_RANGE,
        CMD_DUMP_FILE_LEN,
        CMD_DUMP_FILE_RANGE,
        CMD_DUMP_FILE_CHECK_LEN,
        CMD_DUMP_FILE_CHECK_RANGE,

        CMD_STOP,

        CMD_UNKNOWN
	);

    function decode_command(s : t_line) return t_command;

    --------------------------------------------------------------------
    -- PROTOCOLLO
    --------------------------------------------------------------------
    type t_protocol is (
        PROT_NONE,
        PROT_AXI,
        PROT_AHB,
        PROT_APB
    );

    --------------------------------------------------------------------
    -- UNITÀ DI TEMPO
    --------------------------------------------------------------------
    type t_time_unit is (
        TU_NONE,
        TU_NS,
        TU_US,
        TU_MS,
        TU_SEC,
        TU_CLK,
        TU_SIM
    );

    --------------------------------------------------------------------
    -- INCLUDE STACK
    --------------------------------------------------------------------
	type include_entry_t is record
		tag         : natural;   -- log file tag
		filename    : t_line;    -- nome del file (range fisso)
		line_number : natural;   -- numero di linea del file corrente
	end record;

	type include_stack_t is array(1 to C_MAX_INCLUDE_DEPTH) of include_entry_t;

    --------------------------------------------------------------------
    -- PARAMETRI SEMANTICI
    --------------------------------------------------------------------
    type t_param_kind is (
        PK_NONE,
        PK_WRAP_SIZE,
        PK_ADDR,
        PK_DATA,
        PK_LEN,
        PK_STRING
    );

    -- Non servono più parametri "per ogni dato" del burst:
    -- i dati del burst stanno in data_array, non in param_kind.
    -- Manteniamo un numero piccolo e sufficiente di parametri semantici.
    subtype t_param_index is natural range 1 to 16;

    type t_param_kind_vec is array(t_param_index) of t_param_kind;

    --------------------------------------------------------------------
    -- TOKEN
    --------------------------------------------------------------------
    type t_token_kind is (
        TK_START,
        TK_COMMAND,
        TK_IDENTIFIER,
        TK_NUMBER,
        TK_OPERATOR,
        TK_STRING,
        TK_FILENAME,
        TK_END
    );

    type t_token is record
        kind : t_token_kind;
        text : t_line;
    end record;

    -- Con C_MAX_DATA_TOKENS=512 questi array restano gestibili.
    type token_list_t     is array(1 to C_MAX_DATA_TOKENS + 32) of t_token;
    type token_acc_list_t is array(1 to (2 * C_MAX_DATA_TOKENS) + 32) of t_token;

    --------------------------------------------------------------------
    -- COMANDO LOGICO (prima dello split)
    --------------------------------------------------------------------
    type t_cmd is record
        command      : t_command;
        addr         : t_addr;
        end_addr     : t_addr;
        offset       : natural;
        len          : natural;
        wrap_size    : natural;
        data         : t_data;
        data_array   : t_data_array;
        wait_value   : natural;
        wait_unit    : t_time_unit;
        timeout      : natural;
        filename     : t_line;
        print_text   : t_line;
        var_name     : t_line;
        param_count  : natural;
        param_kind   : t_param_kind_vec;
        atomic       : std_logic;
		byte_enable  : natural;
    end record;

    -- Vecchio array di tutti i comandi del file: non serve più
    -- con il parser "a riga" e i microcomandi. Lo rimuoviamo.
    -- type t_cmd_list is array(0 to C_MAX_DATA_TOKENS) of t_cmd;

    --------------------------------------------------------------------
    -- RECORD USATO DAL PARSER (comando espanso)
    --------------------------------------------------------------------
    type t_mc_cmd is record
        cmd_type   : t_command;
        cmd_id     : unsigned(C_ID_WIDTH-1 downto 0);
        addr       : t_addr;
        len        : natural;
        data       : t_data;
        data_array : t_data_array;
        wait_value : natural;
        timeout    : natural;
        end_addr   : t_addr;
        wait_unit  : t_time_unit;
        atomic     : std_logic;
        print_text : t_line;
        filename   : t_line;
        byte_enable : natural;
    end record;

    type t_mc_list is array(0 to C_MAX_MC-1) of t_mc_cmd;

    constant mc_clear : t_mc_cmd := (
        cmd_type   => CMD_NOP,
        cmd_id     => (others => '0'),
        addr       => (others => '0'),
        len        => 0,
        data       => (others => '0'),
        data_array => (others => (others => '0')),
        wait_value => 0,
        timeout    => 0,
        end_addr   => (others => '0'),
        wait_unit  => TU_NONE,
        atomic     => '0',
        print_text => (others => ' '),
        filename   => (others => ' '),
		byte_enable => 0
    );

    --------------------------------------------------------------------
    -- SIGNATURE DEI COMANDI
    --------------------------------------------------------------------
    type t_cmd_signature is record
        min_params      : natural;
        max_params      : natural;
        param_kinds     : t_param_kind_vec;
        needs_alignment : boolean;
        is_wrap         : boolean;
        is_burst        : boolean;
    end record;

    type t_cmd_signature_table is array(t_command) of t_cmd_signature;

	--------------------------------------------------------------------
    -- RECORD INTERFACCIA AXI
    --------------------------------------------------------------------
    type t_cmd_out is record
        cmd_write : std_logic;                     -- 1 = write, 0 = read
        cmd_burst : std_logic;                     -- 1 = multi-beat
        cmd_wrap  : std_logic;                     -- 1 = wrap addressing
        cmd_fifo  : std_logic;                     -- 1 = fifo addressing
        cmd_id    : unsigned(C_ID_WIDTH-1 downto 0);
        cmd_addr  : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
        cmd_len   : natural range 0 to 256;
        cmd_data  : t_data_array;
        cmd_wstrb : std_logic_vector((C_DATA_WIDTH/8)-1 downto 0);
        cmd_prot  : std_logic_vector(2 downto 0); -- AXI Protection Attributes (AWPROT/ARPROT) [0] privileged / non-privileged [1] secure / non-secure [2] instruction / data
        cmd_size  : std_logic_vector(2 downto 0); -- AXI Size (AWSIZE/ARSIZE) = log2(bytes_per_beat)
        cmd_lock  : std_logic;                    -- AXI Lock (AWLOCK/ARLOCK)
        cmd_cache : std_logic_vector(3 downto 0); -- AXI Cache Attributes (AWCACHE/ARCACHE)
        cmd_qos   : std_logic_vector(3 downto 0); -- AXI QoS Attributes (AWQOS/ARQOS)
    end record;

	type t_rsp_out is record
		rsp_ready     : std_logic;   -- parser pronto a ricevere dati
		rsp_err_ready : std_logic;   -- parser pronto a ricevere errori
	end record;

	type t_rsp_in is record
		rsp_valid     : std_logic;
		rsp_last      : std_logic;
		rsp_data      : std_logic_vector(C_DATA_WIDTH-1 downto 0);
		rsp_id        : std_logic_vector(C_ID_WIDTH-1 downto 0);
		rsp_err_valid : std_logic;
		rsp_err_code  : std_logic_vector(7 downto 0);
		rsp_err_info  : std_logic_vector(31 downto 0);
		rsp_err_id    : std_logic_vector(C_ID_WIDTH-1 downto 0);
	end record;



	--------------------------------------------------------------------
    -- TABELLA SIGNATURE (CMD_SIG)
    --------------------------------------------------------------------
    constant CMD_SIG : t_cmd_signature_table := (

        ----------------------------------------------------------------
        -- Comandi base / controllo
        ----------------------------------------------------------------
        CMD_NOP => (
            min_params      => 0,
            max_params      => 0,
            param_kinds     => (others => PK_NONE),
            needs_alignment => false,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_STOP => (
            min_params      => 0,
            max_params      => 0,
            param_kinds     => (others => PK_NONE),
            needs_alignment => false,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_SET_VAR => (
            min_params      => 2,
            max_params      => 2,
            param_kinds     => (
                1      => PK_STRING,
                2      => PK_DATA,
                others => PK_NONE
            ),
            needs_alignment => false,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_INCLUDE => (
            min_params      => 1,
            max_params      => 1,
            param_kinds     => (
                1      => PK_STRING,
                others => PK_NONE
            ),
            needs_alignment => false,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_PRINT => (
            min_params      => 1,
            max_params      => 1,
            param_kinds     => (
                1      => PK_STRING,
                others => PK_NONE
            ),
            needs_alignment => false,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_END_SIM => (
            min_params      => 0,
            max_params      => 0,
            param_kinds     => (others => PK_NONE),
            needs_alignment => false,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_SET_ATOMIC => (
            min_params      => 1,
            max_params      => 1,
            param_kinds     => (
                1      => PK_DATA,
                others => PK_NONE
            ),
            needs_alignment => false,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_UNKNOWN => (
            min_params      => 0,
            max_params      => 0,
            param_kinds     => (others => PK_NONE),
            needs_alignment => false,
            is_wrap         => false,
            is_burst        => false
        ),

        ----------------------------------------------------------------
        -- WAIT_*
        ----------------------------------------------------------------
        CMD_WAIT_TIME => (
            min_params      => 2,
            max_params      => 2,
            param_kinds     => (others => PK_NONE),
            needs_alignment => false,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_WAIT_CLOCKS => (
            min_params      => 1,
            max_params      => 1,
            param_kinds     => (1 => PK_LEN, others => PK_NONE),
            needs_alignment => false,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_WAIT_SIM_TIME => (
            min_params      => 1,
            max_params      => 1,
            param_kinds     => (1 => PK_LEN, others => PK_NONE),
            needs_alignment => false,
            is_wrap         => false,
            is_burst        => false
        ),

        ----------------------------------------------------------------
        -- WSTRB_WRITE
        ----------------------------------------------------------------
        CMD_WSTRB_WRITE => (
            min_params      => 3,
            max_params      => 3,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_DATA,
                3      => PK_LEN,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => false
        ),

        ----------------------------------------------------------------
        -- READ / WRITE / CHECK
        ----------------------------------------------------------------
        CMD_READ => (
            min_params      => 1,
            max_params      => 1,
            param_kinds     => (
                1      => PK_ADDR,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_WRITE => (
            min_params      => 2,
            max_params      => 2,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_DATA,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_CHECK => (
            min_params      => 2,
            max_params      => 2,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_DATA,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => false
        ),

        ----------------------------------------------------------------
        -- FIFO_*
        ----------------------------------------------------------------
        CMD_FIFO_WRITE => (
            min_params      => 3,
            max_params      => 3,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_LEN,
                3      => PK_DATA,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_FIFO_READ => (
            min_params      => 2,
            max_params      => 2,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_LEN,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_FIFO_CHECK => (
            min_params      => 3,
            max_params      => 3,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_LEN,
                3      => PK_DATA,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => false
        ),

        ----------------------------------------------------------------
        -- BURST_*
        ----------------------------------------------------------------
		CMD_BURST_WRITE => (
			min_params      => 2,
			max_params      => 2,
			param_kinds     => (
				1      => PK_LEN,
				2      => PK_ADDR,
				others => PK_NONE
			),
			needs_alignment => true,
			is_wrap         => false,
			is_burst        => true
		),

		CMD_BURST_READ => (
			min_params      => 2,
			max_params      => 2,
			param_kinds     => (
				1      => PK_LEN,
				2      => PK_ADDR,
				others => PK_NONE
			),
			needs_alignment => true,
			is_wrap         => false,
			is_burst        => true
		),

		CMD_BURST_CHECK => (
			min_params      => 2,
			max_params      => 2,
			param_kinds     => (
				1      => PK_LEN,
				2      => PK_ADDR,
				others => PK_NONE
			),
			needs_alignment => true,
			is_wrap         => false,
			is_burst        => true
		),

        ----------------------------------------------------------------
        -- WRAP_*
        ----------------------------------------------------------------
		CMD_WRAP_WRITE => (
			min_params      => 2,
			max_params      => 2,
			param_kinds     => (
				1      => PK_WRAP_SIZE,
				2      => PK_ADDR,
				others => PK_NONE
			),
			needs_alignment => true,
			is_wrap         => true,
			is_burst        => true
		),

		CMD_WRAP_READ => (
			min_params      => 2,
			max_params      => 2,
			param_kinds     => (
				1      => PK_WRAP_SIZE,
				2      => PK_ADDR,
				others => PK_NONE
			),
			needs_alignment => true,
			is_wrap         => true,
			is_burst        => true
		),

		CMD_WRAP_CHECK => (
			min_params      => 2,
			max_params      => 2,
			param_kinds     => (
				1      => PK_WRAP_SIZE,
				2      => PK_ADDR,
				others => PK_NONE
			),
			needs_alignment => true,
			is_wrap         => true,
			is_burst        => true
		),

        ----------------------------------------------------------------
        -- FILL_*
        ----------------------------------------------------------------
        CMD_FILL_LEN => (
            min_params      => 3,
            max_params      => 3,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_LEN,
                3      => PK_DATA,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => true
        ),

        CMD_FILL_RANGE => (
            min_params      => 3,
            max_params      => 3,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_ADDR,
                3      => PK_DATA,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => true
        ),

        CMD_FILL_CHECK => (
            min_params      => 3,
            max_params      => 3,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_LEN,
                3      => PK_DATA,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => true
        ),

        ----------------------------------------------------------------
        -- POLL_*
        ----------------------------------------------------------------
        CMD_POLL_READ => (
            min_params      => 5,
            max_params      => 5,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_DATA,
                3      => PK_DATA,
                4      => PK_LEN,
                5      => PK_LEN,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_POLL_TOGGLE => (
            min_params      => 4,
            max_params      => 4,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_DATA,
                3      => PK_LEN,
                4      => PK_LEN,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => false
        ),

        CMD_POLL_PING => (
            min_params      => 3,
            max_params      => 3,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_LEN,
                3      => PK_LEN,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => false
        ),

        ----------------------------------------------------------------
        -- DUMP_*
        ----------------------------------------------------------------
        CMD_DUMP_LEN => (
            min_params      => 2,
            max_params      => 2,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_LEN,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => true
        ),

        CMD_DUMP_RANGE => (
            min_params      => 2,
            max_params      => 2,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_ADDR,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => true
        ),

        CMD_DUMP_FILE_LEN => (
            min_params      => 3,
            max_params      => 3,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_LEN,
                3      => PK_STRING,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => true
        ),

        CMD_DUMP_FILE_RANGE => (
            min_params      => 3,
            max_params      => 3,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_ADDR,
                3      => PK_STRING,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => true
        ),

        CMD_DUMP_FILE_CHECK_LEN => (
            min_params      => 3,
            max_params      => 3,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_LEN,
                3      => PK_STRING,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => true
        ),

        CMD_DUMP_FILE_CHECK_RANGE => (
            min_params      => 3,
            max_params      => 3,
            param_kinds     => (
                1      => PK_ADDR,
                2      => PK_ADDR,
                3      => PK_STRING,
                others => PK_NONE
            ),
            needs_alignment => true,
            is_wrap         => false,
            is_burst        => true
        )
    );

end package cmd_cmd_pkg;

package body cmd_cmd_pkg is

    --------------------------------------------------------------------
    -- Decodifica del comando (case-insensitive)
    --------------------------------------------------------------------
    function decode_command(s : t_line) return t_command is
        variable str      : string(1 to C_MAX_STRING);
        variable tmp_line : t_line := line_clear;
    begin
        -- Converti t_line → string
        str := line_to_string(s);

        -- Normalizza a maiuscolo
        for i in str'range loop
            if str(i) >= 'a' and str(i) <= 'z' then
                str(i) := character'val(character'pos(str(i)) - 32);
            end if;
        end loop;

        assign_string(tmp_line, str);

		if ENABLE_DEBUG_LOG then
			report "DECODE_COMMAND: normalized = '" & str & "'" severity note;
		end if;

        -- Confronto diretto con i comandi
        if line_starts_with(tmp_line, "SET_VAR") then
            return CMD_SET_VAR;
        elsif line_starts_with(tmp_line, "SET_ATOMIC") then
            return CMD_SET_ATOMIC;
        elsif line_starts_with(tmp_line, "INCLUDE") then
            return CMD_INCLUDE;
        elsif line_starts_with(tmp_line, "PRINT") then
            return CMD_PRINT;
        elsif line_starts_with(tmp_line, "END_SIM") then
            return CMD_END_SIM;
        elsif line_starts_with(tmp_line, "STOP") then
            return CMD_STOP;

        elsif line_starts_with(tmp_line, "WAIT_TIME") then
            return CMD_WAIT_TIME;
        elsif line_starts_with(tmp_line, "WAIT_CLOCKS") then
            return CMD_WAIT_CLOCKS;
        elsif line_starts_with(tmp_line, "WAIT_SIM_TIME") then
            return CMD_WAIT_SIM_TIME;

        elsif line_starts_with(tmp_line, "WSTRB_WRITE") then
            return CMD_WSTRB_WRITE;

		elsif line_starts_with(tmp_line, "READ") then
            return CMD_READ;
        elsif line_starts_with(tmp_line, "WRITE") then
            return CMD_WRITE;
        elsif line_starts_with(tmp_line, "CHECK") then
            return CMD_CHECK;

        elsif line_starts_with(tmp_line, "FIFO_WRITE") then
            return CMD_FIFO_WRITE;
        elsif line_starts_with(tmp_line, "FIFO_READ") then
            return CMD_FIFO_READ;
        elsif line_starts_with(tmp_line, "FIFO_CHECK") then
            return CMD_FIFO_CHECK;

        elsif line_starts_with(tmp_line, "BURST_WRITE") then
            return CMD_BURST_WRITE;
        elsif line_starts_with(tmp_line, "BURST_READ") then
            return CMD_BURST_READ;
        elsif line_starts_with(tmp_line, "BURST_CHECK") then
            return CMD_BURST_CHECK;

        elsif line_starts_with(tmp_line, "WRAP_WRITE") then
            return CMD_WRAP_WRITE;
        elsif line_starts_with(tmp_line, "WRAP_READ") then
            return CMD_WRAP_READ;
        elsif line_starts_with(tmp_line, "WRAP_CHECK") then
            return CMD_WRAP_CHECK;

        elsif line_starts_with(tmp_line, "FILL_LEN") then
            return CMD_FILL_LEN;
        elsif line_starts_with(tmp_line, "FILL_RANGE") then
            return CMD_FILL_RANGE;
        elsif line_starts_with(tmp_line, "FILL_CHECK") then
            return CMD_FILL_CHECK;

        elsif line_starts_with(tmp_line, "POLL_READ") then
            return CMD_POLL_READ;
        elsif line_starts_with(tmp_line, "POLL_TOGGLE") then
            return CMD_POLL_TOGGLE;
        elsif line_starts_with(tmp_line, "POLL_PING") then
            return CMD_POLL_PING;

        elsif line_starts_with(tmp_line, "DUMP_LEN") then
            return CMD_DUMP_LEN;
        elsif line_starts_with(tmp_line, "DUMP_RANGE") then
            return CMD_DUMP_RANGE;
        elsif line_starts_with(tmp_line, "DUMP_FILE_LEN") then
            return CMD_DUMP_FILE_LEN;
        elsif line_starts_with(tmp_line, "DUMP_FILE_RANGE") then
            return CMD_DUMP_FILE_RANGE;
        elsif line_starts_with(tmp_line, "DUMP_FILE_CHECK_LEN") then
            return CMD_DUMP_FILE_CHECK_LEN;
        elsif line_starts_with(tmp_line, "DUMP_FILE_CHECK_RANGE") then
            return CMD_DUMP_FILE_CHECK_RANGE;
        end if;

        return CMD_UNKNOWN;
    end function;

end package body cmd_cmd_pkg;
