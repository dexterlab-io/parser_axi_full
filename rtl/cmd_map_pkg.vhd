-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_map_pkg.vhd
--  Author: Dexter
--  Date: 2026-09-06
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmd_cmd_pkg.all;   -- contiene t_command

package cmd_map_pkg is

    function cmd_to_int(c : t_command) return integer;
    function cmd_to_slv(c : t_command) return std_logic_vector;
    function cmd_to_string(c : t_command) return string;

end package cmd_map_pkg;


package body cmd_map_pkg is

    function cmd_to_int(c : t_command) return integer is
    begin
        case c is
            when CMD_READ              => return 1;
            when CMD_WRITE             => return 2;
            when CMD_CHECK             => return 3;
            when CMD_BURST_READ        => return 4;
            when CMD_BURST_WRITE       => return 5;
            when CMD_BURST_CHECK       => return 6;
            when CMD_WRAP_READ         => return 7;
            when CMD_WRAP_WRITE        => return 8;
            when CMD_WRAP_CHECK        => return 9;
            when CMD_FILL_LEN          => return 10;
            when CMD_FILL_RANGE        => return 11;
            when CMD_FILL_CHECK        => return 12;
            when CMD_FIFO_READ         => return 13;
            when CMD_FIFO_WRITE        => return 14;
            when CMD_FIFO_CHECK        => return 15;
            when CMD_WAIT_TIME         => return 16;
            when CMD_WAIT_CLOCKS       => return 17;
            when CMD_WAIT_SIM_TIME     => return 18;
            when CMD_PRINT             => return 19;
            when CMD_POLL_READ         => return 20;
            when CMD_POLL_TOGGLE       => return 21;
            when CMD_POLL_PING         => return 22;
            when CMD_DUMP_LEN          => return 23;
            when CMD_DUMP_RANGE        => return 24;
            when CMD_DUMP_FILE_LEN     => return 25;
            when CMD_DUMP_FILE_RANGE   => return 26;
            when CMD_DUMP_FILE_CHECK_LEN   => return 27;
            when CMD_DUMP_FILE_CHECK_RANGE => return 28;
            when CMD_SET_VAR           => return 29;
            when CMD_SET_ATOMIC        => return 30;
            when CMD_INCLUDE           => return 31;
            when CMD_END_SIM           => return 32;
            when CMD_STOP              => return 33;
            when CMD_WSTRB_WRITE       => return 34;
            when CMD_NOP               => return 35;
            when others                => return 0;
        end case;
    end function;

    function cmd_to_slv(c : t_command) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(cmd_to_int(c), 8));
    end function;

	function cmd_to_string(c : t_command) return string is
	begin
		case c is
			when CMD_READ                => return "READ";
			when CMD_WRITE               => return "WRITE";
			when CMD_CHECK               => return "CHECK";

			when CMD_BURST_READ          => return "BURST_READ";
			when CMD_BURST_WRITE         => return "BURST_WRITE";
			when CMD_BURST_CHECK         => return "BURST_CHECK";

			when CMD_WRAP_READ           => return "WRAP_READ";
			when CMD_WRAP_WRITE          => return "WRAP_WRITE";
			when CMD_WRAP_CHECK          => return "WRAP_CHECK";

			when CMD_FILL_LEN            => return "FILL_LEN";
			when CMD_FILL_RANGE          => return "FILL_RANGE";
			when CMD_FILL_CHECK          => return "FILL_CHECK";

			when CMD_FIFO_READ           => return "FIFO_READ";
			when CMD_FIFO_WRITE          => return "FIFO_WRITE";
			when CMD_FIFO_CHECK          => return "FIFO_CHECK";

			when CMD_WAIT_TIME           => return "WAIT_TIME";
			when CMD_WAIT_CLOCKS         => return "WAIT_CLOCKS";
			when CMD_WAIT_SIM_TIME       => return "WAIT_SIM_TIME";

			when CMD_PRINT               => return "PRINT";

			when CMD_POLL_READ           => return "POLL_READ";
			when CMD_POLL_TOGGLE         => return "POLL_TOGGLE";
			when CMD_POLL_PING           => return "POLL_PING";

			when CMD_DUMP_LEN            => return "DUMP_LEN";
			when CMD_DUMP_RANGE          => return "DUMP_RANGE";
			when CMD_DUMP_FILE_LEN       => return "DUMP_FILE_LEN";
			when CMD_DUMP_FILE_RANGE     => return "DUMP_FILE_RANGE";
			when CMD_DUMP_FILE_CHECK_LEN => return "DUMP_FILE_CHECK_LEN";
			when CMD_DUMP_FILE_CHECK_RANGE => return "DUMP_FILE_CHECK_RANGE";

			when CMD_SET_VAR             => return "SET_VAR";
			when CMD_SET_ATOMIC          => return "SET_ATOMIC";

			when CMD_INCLUDE             => return "INCLUDE";
			when CMD_END_SIM             => return "END_SIM";

            when CMD_STOP                => return "STOP";
            when CMD_WSTRB_WRITE         => return "WSTRB_WRITE";
            when CMD_NOP                 => return "NOP";

			when others                  => return "UNKNOWN";
		end case;
	end function;

end package body cmd_map_pkg;
