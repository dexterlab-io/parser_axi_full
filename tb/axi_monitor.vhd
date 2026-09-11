-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: axi_monitor.vhd
--  Author: Dexter
--  Date: 2026-09-10
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;

use work.cmd_cfg.all;
use work.cmd_cmd_pkg.all;
use work.cmd_text_pkg.all;

entity axi_monitor is
    generic (
        g_axi_monitor_out : string := "axi_monitor_out.log"
    );
    port (
        clk      : in std_logic;
        resetn   : in std_logic;

        ------------------------------------------------------------------
        -- WRITE ADDRESS CHANNEL
        ------------------------------------------------------------------
        awvalid  : in std_logic;
        awready  : in std_logic;
        awaddr   : in std_logic_vector(C_ADDR_WIDTH-1 downto 0);
        awlen    : in std_logic_vector(7 downto 0);  -- AXI LEN is always 8 bits
        awid     : in std_logic_vector(C_ID_WIDTH-1 downto 0);

        ------------------------------------------------------------------
        -- WRITE DATA CHANNEL
        ------------------------------------------------------------------
        wvalid   : in std_logic;
        wready   : in std_logic;
        wdata    : in std_logic_vector(C_DATA_WIDTH-1 downto 0);
        wstrb    : in std_logic_vector((C_DATA_WIDTH/8)-1 downto 0);
        wlast    : in std_logic;

        ------------------------------------------------------------------
        -- WRITE RESPONSE CHANNEL
        ------------------------------------------------------------------
        bvalid   : in std_logic;
        bready   : in std_logic;
        bresp    : in std_logic_vector(1 downto 0);
        bid      : in std_logic_vector(C_ID_WIDTH-1 downto 0);

        ------------------------------------------------------------------
        -- READ ADDRESS CHANNEL
        ------------------------------------------------------------------
        arvalid  : in std_logic;
        arready  : in std_logic;
        araddr   : in std_logic_vector(C_ADDR_WIDTH-1 downto 0);
        arlen    : in std_logic_vector(7 downto 0);  -- AXI LEN is always 8 bits
        arid     : in std_logic_vector(C_ID_WIDTH-1 downto 0);

        ------------------------------------------------------------------
        -- READ DATA CHANNEL
        ------------------------------------------------------------------
        rvalid   : in std_logic;
        rready   : in std_logic;
        rdata    : in std_logic_vector(C_DATA_WIDTH-1 downto 0);
        rlast    : in std_logic;
        rresp    : in std_logic_vector(1 downto 0);
        rid      : in std_logic_vector(C_ID_WIDTH-1 downto 0)
    );
end entity;


architecture rtl of axi_monitor is

    file f_out : text;
    signal file_opened : boolean := false;

begin

    --------------------------------------------------------------------
    -- Apertura file
    --------------------------------------------------------------------
    open_file_proc : process(clk)
        variable l : line;
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                if file_opened then
                    file_close(f_out);
                    file_opened <= false;
                end if;

            elsif resetn = '1' and not file_opened then
                file_open(f_out, g_axi_monitor_out, write_mode);
                file_opened <= true;

                write(l, string'("### AXI MONITOR START ###"));
                writeline(f_out, l);
            end if;
        end if;
    end process;


    --------------------------------------------------------------------
    -- Monitor AXI
    --------------------------------------------------------------------
    monitor_proc : process(clk)
        variable l : line;
    begin
        if rising_edge(clk) then
            if resetn = '1' and file_opened then

                ----------------------------------------------------------------
                -- WRITE ADDRESS
                ----------------------------------------------------------------
                if awvalid = '1' and awready = '1' then
                    write(l, "[" & time'image(now) & "] ");
                    write(l, string'("AW addr="));
                    write(l, slv_to_hex(awaddr));
                    write(l, string'(" len="));
                    write(l, integer'image(to_integer(unsigned(awlen))));
                    write(l, string'(" AWID="));
                    write(l, slv_to_hex(awid));
                    writeline(f_out, l);
                end if;

                ----------------------------------------------------------------
                -- WRITE DATA
                ----------------------------------------------------------------
                if wvalid = '1' and wready = '1' then
                    write(l, "[" & time'image(now) & "] ");
                    write(l, string'("W data="));
                    write(l, slv_to_hex(wdata));
                    write(l, string'(" strb="));
                    write(l, slv_to_hex(wstrb));
                    if wlast = '1' then
                        write(l, string'(" (LAST)"));
                    end if;
                    writeline(f_out, l);
                end if;

                ----------------------------------------------------------------
                -- WRITE RESPONSE (BRESP + BID)
                ----------------------------------------------------------------
                if bvalid = '1' and bready = '1' then
                    write(l, "[" & time'image(now) & "] ");

                    case bresp is
                        when "00" => write(l, string'("BRESP=OKAY"));
                        when "01" => write(l, string'("BRESP=EXOKAY"));
                        when "10" => write(l, string'("BRESP=SLVERR"));
                        when "11" => write(l, string'("BRESP=DECERR"));
                        when others =>
                            write(l, string'("BRESP=UNKNOWN("));
                            write(l, slv_to_hex(bresp));
                            write(l, string'(")"));
                    end case;

                    write(l, string'(" BID="));
                    write(l, slv_to_hex(bid));

                    writeline(f_out, l);
                end if;

                ----------------------------------------------------------------
                -- READ ADDRESS
                ----------------------------------------------------------------
                if arvalid = '1' and arready = '1' then
                    write(l, "[" & time'image(now) & "] ");
                    write(l, string'("AR addr="));
                    write(l, slv_to_hex(araddr));
                    write(l, string'(" len="));
                    write(l, integer'image(to_integer(unsigned(arlen))));
                    write(l, string'(" ARID="));
                    write(l, slv_to_hex(arid));
                    writeline(f_out, l);
                end if;

                ----------------------------------------------------------------
                -- READ DATA (RRESP + RID)
                ----------------------------------------------------------------
                if rvalid = '1' and rready = '1' then
                    write(l, "[" & time'image(now) & "] ");

                    write(l, string'("R data="));
                    write(l, slv_to_hex(rdata));

                    if rlast = '1' then
                        write(l, string'(" (LAST)"));
                    end if;

                    write(l, string'(" "));

                    case rresp is
                        when "00" => write(l, string'("RRESP=OKAY"));
                        when "01" => write(l, string'("RRESP=EXOKAY"));
                        when "10" => write(l, string'("RRESP=SLVERR"));
                        when "11" => write(l, string'("RRESP=DECERR"));
                        when others =>
                            write(l, string'("RRESP=UNKNOWN("));
                            write(l, slv_to_hex(rresp));
                            write(l, string'(")"));
                    end case;

                    write(l, string'(" RID="));
                    write(l, slv_to_hex(rid));

                    writeline(f_out, l);
                end if;

            end if;
        end if;
    end process;

end architecture;
