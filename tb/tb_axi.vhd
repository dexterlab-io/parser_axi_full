-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: tb_axi.vhd
--  Author: Dexter
--  Date: 2026-09-10
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmd_cfg.all;
use work.cmd_cmd_pkg.all;
use work.cmd_pkg.all;

entity tb_axi is
end entity;

architecture tb of tb_axi is


    --------------------------------------------------------------------
    -- Clock / Reset / Start (generati da ckrst)
    --------------------------------------------------------------------
    signal s_clk        : std_logic;
    signal s_resetn     : std_logic;
    signal s_start      : std_logic;
    signal s_interrupts : std_logic_vector(7 downto 0);

    --------------------------------------------------------------------
    -- Parser (record interface)
    --------------------------------------------------------------------
    signal s_parser_valid   : std_logic;
    signal s_parser_ready   : std_logic;

    signal s_parser_cmd : t_cmd_out := (
        cmd_write	=> '0',
        cmd_burst	=> '0',
        cmd_wrap	=> '0',
        cmd_fifo	=> '0',
        cmd_atomic	=> '0',
        cmd_id		=> (others => '0'),
        cmd_addr	=> (others => '0'),
        cmd_len		=> 0,
        cmd_data	=> (others => (others => '0')),
   		cmd_wstrb	=> (others => '0')

    );

    signal s_parser_rsp_ready : t_rsp_out := (
        rsp_ready     => '0',
        rsp_err_ready => '0'
    );

    signal s_parser_rsp_valid : t_rsp_in := (
        rsp_valid     => '0',
        rsp_last      => '0',
        rsp_data      => (others => '0'),
        rsp_id        => (others => '0'),
        rsp_err_valid => '0',
        rsp_err_code  => (others => '0'),
        rsp_err_info  => (others => '0'),
        rsp_err_id    => (others => '0')
    );

    --------------------------------------------------------------------
    -- Master (record interface)
    --------------------------------------------------------------------
    signal s_master_valid   : std_logic;
    signal s_master_ready   : std_logic;

    signal s_master_cmd : t_cmd_out := (
        cmd_write	=> '0',
        cmd_burst	=> '0',
        cmd_wrap	=> '0',
        cmd_fifo	=> '0',
        cmd_atomic	=> '0',
        cmd_id		=> (others => '0'),
        cmd_addr	=> (others => '0'),
        cmd_len		=> 0,
        cmd_data	=> (others => (others => '0')),
   		cmd_wstrb	=> (others => '0')
    );

    signal s_master_rsp_ready : t_rsp_out := (
        rsp_ready     => '0',
        rsp_err_ready => '0'
    );

    signal s_master_rsp_valid : t_rsp_in := (
        rsp_valid     => '0',
        rsp_last      => '0',
        rsp_data      => (others => '0'),
        rsp_id        => (others => '0'),
        rsp_err_valid => '0',
        rsp_err_code  => (others => '0'),
        rsp_err_info  => (others => '0'),
        rsp_err_id    => (others => '0')
    );

    --------------------------------------------------------------------
    -- Arbiter <-> Wrapper (record interface)
    --------------------------------------------------------------------
    signal s_cmd_valid : std_logic;
    signal s_cmd_ready : std_logic;

    signal s_cmd : t_cmd_out;
    signal s_rsp_ready  : t_rsp_out;
    signal s_rsp_valid  : t_rsp_in;

    --------------------------------------------------------------------
    -- AXI bus signals (unchanged)
    --------------------------------------------------------------------
    signal s_awvalid : std_logic;
    signal s_awready : std_logic;
    signal s_awaddr  : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    signal s_awlen   : std_logic_vector(7 downto 0);
    signal s_awburst : std_logic_vector(1 downto 0);
    signal s_awsize  : std_logic_vector(2 downto 0);
    signal s_awid    : std_logic_vector(C_ID_WIDTH-1 downto 0);

    signal s_wvalid : std_logic;
    signal s_wready : std_logic;
    signal s_wdata  : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal s_wstrb  : std_logic_vector((C_DATA_WIDTH/8)-1 downto 0);
    signal s_wlast  : std_logic;

    signal s_bvalid : std_logic;
    signal s_bready : std_logic;
    signal s_bresp  : std_logic_vector(1 downto 0);
    signal s_bid    : std_logic_vector(C_ID_WIDTH-1 downto 0);

    signal s_arvalid : std_logic;
    signal s_arready : std_logic;
    signal s_araddr  : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    signal s_arlen   : std_logic_vector(7 downto 0);
    signal s_arburst : std_logic_vector(1 downto 0);
    signal s_arsize  : std_logic_vector(2 downto 0);
    signal s_arid    : std_logic_vector(C_ID_WIDTH-1 downto 0);

    signal s_rvalid : std_logic;
    signal s_rready : std_logic;
    signal s_rdata  : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal s_rlast  : std_logic;
    signal s_rresp  : std_logic_vector(1 downto 0);
    signal s_rid    : std_logic_vector(C_ID_WIDTH-1 downto 0);

begin

    --------------------------------------------------------------------
    -- TB START message (unico processo del TB)
    --------------------------------------------------------------------
    process(s_clk, s_start)
        variable start_prev : std_logic := '0';
    begin
        if rising_edge(s_clk) then
            if start_prev = '0' and s_start = '1' then
                report "TB START" severity note;
            end if;

            start_prev := s_start;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Clock + Reset + Start generator
    --------------------------------------------------------------------
    i_ckrst : entity work.ckrst
        port map (
            clk     => s_clk,
            resetn  => s_resetn,
            start   => s_start
        );

    --------------------------------------------------------------------
    -- Parser
    --------------------------------------------------------------------
    i_cmd_parser : entity work.cmd_parser
        generic map (
            FILENAME => "cmd.txt",
            DRY_RUN  => false
        )
        port map (
            clk        => s_clk,
            resetn     => s_resetn,
            start      => s_start,

            cmd_valid  => s_parser_valid,
            cmd_ready  => s_parser_ready,

            cmd        => s_parser_cmd,
            rsp_out    => s_parser_rsp_ready,
            rsp_in     => s_parser_rsp_valid
        );

    --------------------------------------------------------------------
    -- Master
    --------------------------------------------------------------------
    i_cmd_master : entity work.cmd_master
        port map (
            clk         => s_clk,
            resetn      => s_resetn,
            start       => s_start,
            interrupts  => s_interrupts,

            cmd_valid   => s_master_valid,
            cmd_ready   => s_master_ready,

            cmd         => s_master_cmd,
            rsp_out     => s_master_rsp_ready,
            rsp_in      => s_master_rsp_valid
        );

    --------------------------------------------------------------------
    -- Arbiter MUX (record interface)
    --------------------------------------------------------------------
    i_arbiter_mux : entity work.arbiter_mux
        port map (
            clk             => s_clk,
            resetn          => s_resetn,

            parser_valid    => s_parser_valid,
            parser_ready    => s_parser_ready,
            parser_cmd      => s_parser_cmd,
            parser_rsp_in   => s_parser_rsp_ready,
            parser_rsp_out  => s_parser_rsp_valid,

            master_valid    => s_master_valid,
            master_ready    => s_master_ready,
            master_cmd      => s_master_cmd,
            master_rsp_in   => s_master_rsp_ready,
            master_rsp_out  => s_master_rsp_valid,

            valid           => s_cmd_valid,
            ready           => s_cmd_ready,
            cmd             => s_cmd,
            rsp_out         => s_rsp_ready,
            rsp_in          => s_rsp_valid
        );

    --------------------------------------------------------------------
    -- Wrapper AXI FULL (record interface)
    --------------------------------------------------------------------
    i_cmd_axi_full : entity work.cmd_axi_full
        port map (
            clk        => s_clk,
            resetn     => s_resetn,

            valid      => s_cmd_valid,
            ready      => s_cmd_ready,

            cmd        => s_cmd,
            rsp_in     => s_rsp_ready,
            rsp_out    => s_rsp_valid,

            awvalid    => s_awvalid,
            awready    => s_awready,
            awaddr     => s_awaddr,
            awlen      => s_awlen,
            awburst    => s_awburst,
            awsize     => s_awsize,
            awid       => s_awid,

            wvalid     => s_wvalid,
            wready     => s_wready,
            wdata      => s_wdata,
            wstrb      => s_wstrb,
            wlast      => s_wlast,

            bvalid     => s_bvalid,
            bready     => s_bready,
            bresp      => s_bresp,
            bid        => s_bid,

            arvalid    => s_arvalid,
            arready    => s_arready,
            araddr     => s_araddr,
            arlen      => s_arlen,
            arburst    => s_arburst,
            arsize     => s_arsize,
            arid       => s_arid,

            rvalid     => s_rvalid,
            rready     => s_rready,
            rdata      => s_rdata,
            rlast      => s_rlast,
            rresp      => s_rresp,
            rid        => s_rid
        );

    --------------------------------------------------------------------
    -- AXI Slave model
    --------------------------------------------------------------------
    i_axi_slave_simple : entity work.axi_slave_simple
        port map (
            clk        => s_clk,
            resetn     => s_resetn,
            interrupts => s_interrupts,

            awvalid    => s_awvalid,
            awready    => s_awready,
            awaddr     => s_awaddr,
            awlen      => s_awlen,
            awburst    => s_awburst,
            awsize     => s_awsize,
            awid       => s_awid,

            wvalid     => s_wvalid,
            wready     => s_wready,
            wdata      => s_wdata,
            wstrb      => s_wstrb,
            wlast      => s_wlast,

            bvalid     => s_bvalid,
            bready     => s_bready,
            bresp      => s_bresp,
            bid        => s_bid,

            arvalid    => s_arvalid,
            arready    => s_arready,
            araddr     => s_araddr,
            arlen      => s_arlen,
            arburst    => s_arburst,
            arsize     => s_arsize,
            arid       => s_arid,

            rvalid     => s_rvalid,
            rready     => s_rready,
            rdata      => s_rdata,
            rlast      => s_rlast,
            rresp      => s_rresp,
            rid        => s_rid
        );

    --------------------------------------------------------------------
    -- AXI Monitor (invariato)
    --------------------------------------------------------------------
    u_axi_monitor : entity work.axi_monitor
        generic map (
            g_axi_monitor_out => "axi_monitor_out.log"
        )
        port map (
            clk        => s_clk,
            resetn     => s_resetn,

            awvalid    => s_awvalid,
            awready    => s_awready,
            awaddr     => s_awaddr,
            awlen      => s_awlen,
            awid       => s_awid,

            wvalid     => s_wvalid,
            wready     => s_wready,
            wdata      => s_wdata,
            wstrb      => s_wstrb,
            wlast      => s_wlast,

            bvalid     => s_bvalid,
            bready     => s_bready,
            bresp      => s_bresp,
            bid        => s_bid,

            arvalid    => s_arvalid,
            arready    => s_arready,
            araddr     => s_araddr,
            arlen      => s_arlen,
            arid       => s_arid,

            rvalid     => s_rvalid,
            rready     => s_rready,
            rdata      => s_rdata,
            rlast      => s_rlast,
            rresp      => s_rresp,
            rid        => s_rid
        );

end architecture tb;
