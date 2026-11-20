-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: axi_full_slave.vhd
--  Author: Dexter
--  Date: 2026-10-31
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_full_slave is
    port (
        clk      : in  std_logic;
        resetn   : in  std_logic;

        interrupts : out std_logic_vector(7 downto 0);

        awvalid  : in  std_logic;
        awready  : out std_logic;
        awaddr   : in  std_logic_vector(31 downto 0);
        awlen    : in  std_logic_vector(7 downto 0);
        awsize   : in  std_logic_vector(2 downto 0);
        awburst  : in  std_logic_vector(1 downto 0);
        awid     : in  std_logic_vector(3 downto 0);

        awlock   : in std_logic;
        awcache  : in std_logic_vector(3 downto 0);
        awprot   : in std_logic_vector(2 downto 0);
        awqos    : in std_logic_vector(3 downto 0);

        wvalid   : in  std_logic;
        wready   : out std_logic;
        wdata    : in  std_logic_vector(31 downto 0);
        wstrb    : in  std_logic_vector(3 downto 0);
        wlast    : in  std_logic;

        bvalid   : out std_logic;
        bready   : in  std_logic;
        bresp    : out std_logic_vector(1 downto 0);
        bid      : out std_logic_vector(3 downto 0);

        arvalid  : in  std_logic;
        arready  : out std_logic;
        araddr   : in  std_logic_vector(31 downto 0);
        arlen    : in  std_logic_vector(7 downto 0);
        arsize   : in  std_logic_vector(2 downto 0);
        arburst  : in  std_logic_vector(1 downto 0);
        arid     : in  std_logic_vector(3 downto 0);

        arlock   : in std_logic;
        arcache  : in std_logic_vector(3 downto 0);
        arprot   : in std_logic_vector(2 downto 0);
        arqos    : in std_logic_vector(3 downto 0);

        rvalid   : out std_logic;
        rready   : in  std_logic;
        rdata    : out std_logic_vector(31 downto 0);
        rlast    : out std_logic;
        rresp    : out std_logic_vector(1 downto 0);
        rid      : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of axi_full_slave is

    --------------------------------------------------------------------
    -- REGISTRI 0WS
    --------------------------------------------------------------------
    signal s_reg0, s_reg1, s_reg2, s_reg3 : std_logic_vector(31 downto 0) := (others => '0');
    signal s_reg4, s_reg5, s_reg6, s_reg7 : std_logic_vector(31 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- RAM
    --------------------------------------------------------------------
    signal s_ram_cs    : std_logic := '0';
    signal s_ram_we    : std_logic := '0';
    signal s_ram_addr  : unsigned(9 downto 0) := (others => '0');
    signal s_ram_wstrb : std_logic_vector(3 downto 0) := (others => '0');
    signal s_ram_din   : std_logic_vector(31 downto 0) := (others => '0');
    signal s_ram_dout  : std_logic_vector(31 downto 0);

    signal s_ram_read_valid : std_logic := '0';
    signal s_ram_ready      : std_logic := '0';
    signal s_ram_cmd_addr   : unsigned(9 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- WRITE STATE
    --------------------------------------------------------------------
    signal s_wr_active : std_logic := '0';
    signal s_wr_addr   : unsigned(31 downto 0) := (others => '0');
    signal s_wr_len    : integer := 0;
    signal s_wr_index  : integer := 0;
    signal s_bvalid    : std_logic := '0';
    signal s_bresp     : std_logic_vector(1 downto 0) := "00";

    signal s_bid_reg   : std_logic_vector(3 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- READ STATE
    --------------------------------------------------------------------
    signal s_rd_active      : std_logic := '0';
    signal s_rd_addr        : unsigned(31 downto 0) := (others => '0');
    signal s_rd_total_beats : integer := 0;
    signal s_rd_cmd_left    : integer := 0;
    signal s_rd_data_left   : integer := 0;
    signal s_rresp          : std_logic_vector(1 downto 0) := "00";

    signal s_rid_reg        : std_logic_vector(3 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- REGISTRI 0WS (combinatori)
    --------------------------------------------------------------------
    signal s_reg_ready_comb : std_logic;
    signal s_reg_data_comb  : std_logic_vector(31 downto 0);

    --------------------------------------------------------------------
    -- RAM CONTROL
    --------------------------------------------------------------------
    signal s_ram_cs_next    : std_logic;
    signal s_ram_we_next    : std_logic;
    signal s_ram_addr_next  : unsigned(9 downto 0);
    signal s_ram_wstrb_next : std_logic_vector(3 downto 0);
    signal s_ram_din_next   : std_logic_vector(31 downto 0);

    signal s_rvalid_ram : std_logic;

    --------------------------------------------------------------------
    -- FIFO SIGNALS
    --------------------------------------------------------------------
    signal fifo_in_data   : std_logic_vector(31 downto 0) := (others => '0');
    signal fifo_in_valid  : std_logic := '0';
    signal fifo_in_ready  : std_logic;

    signal fifo_out_data  : std_logic_vector(31 downto 0);
    signal fifo_out_valid : std_logic;
    signal fifo_out_ready : std_logic;

    --------------------------------------------------------------------
    -- TEST_ERROR
    --------------------------------------------------------------------
    signal reg_err_exokay  : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_err_slverr  : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_err_decerr  : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_err_timeout : std_logic_vector(31 downto 0) := (others => '0');

begin

    interrupts <= (others => '0');

    --------------------------------------------------------------------
    -- READY costanti
    --------------------------------------------------------------------
    awready <= '1';
    wready  <= '1';
    arready <= '1';
    bvalid  <= s_bvalid;
    bresp   <= s_bresp;
    bid     <= s_bid_reg;

    --------------------------------------------------------------------
    -- RAM
    --------------------------------------------------------------------
    u_ram : entity work.ram_sync_wstrb
        generic map (
            g_depth    => 2048,
            g_aw       => 10,
            g_cde_file => "ram_init.cde"
        )
        port map (
            clk   => clk,
            cs    => s_ram_cs,
            we    => s_ram_we,
            addr  => std_logic_vector(s_ram_addr),
            wstrb => s_ram_wstrb,
            din   => s_ram_din,
            dout  => s_ram_dout
        );

    --------------------------------------------------------------------
    -- FIFO
    --------------------------------------------------------------------
    u_fifo : entity work.gen_fifo
        generic map (
            gen_width => 32,
            gen_depth => 256
        )
        port map (
            clk          => clk,
            rstn         => resetn,
            s_in_tdata   => fifo_in_data,
            s_in_tvalid  => fifo_in_valid,
            s_in_tready  => fifo_in_ready,
            m_out_tdata  => fifo_out_data,
            m_out_tvalid => fifo_out_valid,
            m_out_tready => fifo_out_ready
        );

    --------------------------------------------------------------------
    -- FIFO READ HANDSHAKE (0WS)
    --------------------------------------------------------------------
    fifo_out_ready <= rready
                      when (s_rd_active = '1' and s_rd_addr = x"00003100")
                      else '0';

    --------------------------------------------------------------------
    -- WRITE CHANNEL
    --------------------------------------------------------------------
    process(clk, resetn)
        variable wrap_size  : unsigned(31 downto 0);
        variable wrap_mask  : unsigned(31 downto 0);
        variable wrap_base  : unsigned(31 downto 0);
        variable offset     : unsigned(31 downto 0);
    begin
        if resetn = '0' then
            s_wr_active   <= '0';
            s_wr_len      <= 0;
            s_wr_index    <= 0;
            s_wr_addr     <= (others => '0');
            s_bvalid      <= '0';
            s_bresp       <= "00";
            s_bid_reg     <= (others => '0');
            fifo_in_valid <= '0';
            fifo_in_data  <= (others => '0');

        elsif rising_edge(clk) then

            fifo_in_valid <= '0';

            ----------------------------------------------------------------
            -- START WRITE COMMAND
            ----------------------------------------------------------------
            if s_wr_active = '0' then
                if awvalid = '1' then
                    s_wr_active <= '1';
                    s_wr_addr   <= unsigned(awaddr);
                    s_wr_len    <= to_integer(unsigned(awlen)) + 1;
                    s_wr_index  <= 0;
                    s_bvalid    <= '0';
                    s_bid_reg   <= awid;

                    if (unsigned(awaddr) < x"00000020") or
                       (unsigned(awaddr) >= x"00001000" and unsigned(awaddr) <= x"00002FFF") or
                       (unsigned(awaddr) = x"00003000") then
                        s_bresp <= "00";
                    else
                        s_bresp <= "11";
                    end if;
                end if;

            ----------------------------------------------------------------
            -- WRITE BURST ACTIVE
            ----------------------------------------------------------------
            else
                if wvalid = '1' then

                    --------------------------------------------------------
                    -- FIFO WRITE @ 0x00003000
                    --------------------------------------------------------
                    if s_wr_addr = x"00003000" then

                        if fifo_in_ready = '0' then
                            s_bresp <= "11";
                        else
                            fifo_in_data  <= wdata;
                            fifo_in_valid <= '1';
                            s_bresp       <= "00";
                        end if;

                        if wlast = '1' then
                            s_wr_active <= '0';
                            s_bvalid    <= '1';
                        end if;

                    --------------------------------------------------------
                    -- REGISTRI + RAM
                    --------------------------------------------------------
                    else

                        if s_wr_addr < x"00000020" then
                            case s_wr_addr(4 downto 2) is
                                when "000" => s_reg0 <= wdata;
                                when "001" => s_reg1 <= wdata;
                                when "010" => s_reg2 <= wdata;
                                when "011" => s_reg3 <= wdata;
                                when "100" => s_reg4 <= wdata;
                                when "101" => s_reg5 <= wdata;
                                when "110" => s_reg6 <= wdata;
                                when "111" => s_reg7 <= wdata;
                                when others => null;
                            end case;
                        end if;

                        if s_wr_index < s_wr_len - 1 then
                            s_wr_index <= s_wr_index + 1;

                            case awburst is

                                when "00" =>  -- FIXED
                                    null;

                                when "01" =>  -- INCR
                                    s_wr_addr <= s_wr_addr + 4;

                                when "10" =>  -- WRAP
                                    wrap_size := to_unsigned((to_integer(unsigned(awlen)) + 1) * 4, 32);
                                    wrap_mask := not (wrap_size - 1);
                                    wrap_base := unsigned(awaddr) and wrap_mask;
                                    offset    := (s_wr_addr + 4) - wrap_base;
                                    offset    := offset mod wrap_size;
                                    s_wr_addr <= wrap_base + offset;

                                when others =>
                                    null;

                            end case;
                        end if;

                        if not ((s_wr_addr < x"00000020") or
                                (s_wr_addr >= x"00001000" and s_wr_addr <= x"00002FFF") or
                                (s_wr_addr = x"00003000")) then
                            s_bresp <= "11";
                        end if;

                        if wlast = '1' then
                            s_wr_active <= '0';
                            s_bvalid    <= '1';
                        end if;

                    end if;
                end if;
            end if;

            ----------------------------------------------------------------
            -- HANDSHAKE BREADY
            ----------------------------------------------------------------
            if s_bvalid = '1' and bready = '1' then
                s_bvalid <= '0';
                s_bresp  <= "00";
            end if;

        end if;
    end process;

    --------------------------------------------------------------------
    -- READ CHANNEL
    --------------------------------------------------------------------
    process(clk, resetn)
        variable v_valid    : std_logic;
        variable wrap_size  : unsigned(31 downto 0);
        variable wrap_mask  : unsigned(31 downto 0);
        variable wrap_base  : unsigned(31 downto 0);
        variable offset     : unsigned(31 downto 0);
    begin
        if resetn = '0' then
            s_rd_active      <= '0';
            s_rd_addr        <= (others => '0');
            s_rd_total_beats <= 0;
            s_rd_cmd_left    <= 0;
            s_rd_data_left   <= 0;
            s_rresp          <= "00";
            s_rid_reg        <= (others => '0');

        elsif rising_edge(clk) then

            ----------------------------------------------------------------
            -- START READ COMMAND
            ----------------------------------------------------------------
            if s_rd_active = '0' then
                if arvalid = '1' then
                    s_rd_active      <= '1';
                    s_rd_addr        <= unsigned(araddr);
                    s_rd_total_beats <= to_integer(unsigned(arlen)) + 1;
                    s_rd_cmd_left    <= to_integer(unsigned(arlen)) + 1;
                    s_rd_data_left   <= to_integer(unsigned(arlen)) + 1;
                    s_rid_reg        <= arid;

                    if (unsigned(araddr) < x"00000020") or
                       (unsigned(araddr) >= x"00001000" and unsigned(araddr) <= x"00002FFF") or
                       (unsigned(araddr) = x"00003100") then
                        s_rresp <= "00";
                    else
                        s_rresp <= "11";
                    end if;
                end if;

            ----------------------------------------------------------------
            -- READ BURST ACTIVE
            ----------------------------------------------------------------
            else
                if s_ram_cs_next = '1' and s_ram_we_next = '0' and
                   s_rd_cmd_left > 0 then
                    s_rd_cmd_left <= s_rd_cmd_left - 1;
                end if;

                v_valid := '0';
                if s_rd_addr < x"00000020" then
                    v_valid := s_reg_ready_comb;
                elsif s_rd_addr >= x"00001000" and s_rd_addr <= x"00002FFF" then
                    v_valid := s_rvalid_ram;
                elsif s_rd_addr = x"00003100" then
                    v_valid := '1';
                elsif s_rd_addr = x"00004000" or
                      s_rd_addr = x"00004004" or
                      s_rd_addr = x"00004008" or
                      s_rd_addr = x"0000400C" then
                    v_valid := '1';
                else
                    v_valid := '1';
                end if;

                if rready = '1' and v_valid = '1' and s_rd_data_left > 0 then

                    if s_rd_addr = x"00003100" then
                        if s_rd_data_left > 1 then
                            s_rd_data_left <= s_rd_data_left - 1;
                        else
                            s_rd_data_left <= 0;
                            s_rd_active    <= '0';
                            s_rresp        <= "00";
                        end if;

                    else
                        if s_rd_data_left > 1 then
                            s_rd_data_left <= s_rd_data_left - 1;

                            case arburst is

                                when "00" =>  -- FIXED
                                    null;

                                when "01" =>  -- INCR
                                    s_rd_addr <= s_rd_addr + 4;

                                when "10" =>  -- WRAP
                                    wrap_size := to_unsigned((to_integer(unsigned(arlen)) + 1) * 4, 32);
                                    wrap_mask := not (wrap_size - 1);
                                    wrap_base := unsigned(araddr) and wrap_mask;
                                    offset    := (s_rd_addr + 4) - wrap_base;
                                    offset    := offset mod wrap_size;
                                    s_rd_addr <= wrap_base + offset;

                                when others =>
                                    null;

                            end case;

                        else
                            s_rd_data_left <= 0;
                            s_rd_active    <= '0';
                            s_rresp        <= "00";
                        end if;
                    end if;
                end if;

                ----------------------------------------------------------------
                -- AGGIORNAMENTO s_rresp SOLO QUANDO IL BEAT È VALIDO
                ----------------------------------------------------------------
                if v_valid = '1' then
                    if s_rd_addr < x"00000020" then
                        s_rresp <= "00";

                    elsif s_rd_addr >= x"00001000" and s_rd_addr <= x"00002FFF" then
                        s_rresp <= "00";

                    elsif s_rd_addr = x"00003100" then
                        if fifo_out_valid = '1' then
                            s_rresp <= "00";
                        else
                            -- FIFO vuota: rvalid=0, rresp non aggiornato
                            null;
                        end if;

                    elsif s_rd_addr = x"00004000" then
                        s_rresp <= "01";

                    elsif s_rd_addr = x"00004004" then
                        s_rresp <= "10";

                    elsif s_rd_addr = x"00004008" then
                        s_rresp <= "11";

                    elsif s_rd_addr = x"0000400C" then
                        -- timeout: rvalid=0, rresp irrilevante
                        s_rresp <= "00";

                    else
                        s_rresp <= "11";
                    end if;
                end if;

            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- REGISTRI 0WS
    --------------------------------------------------------------------
    process(
        s_rd_active,
        s_rd_addr,
        s_reg0,
        s_reg1,
        s_reg2,
        s_reg3,
        s_reg4,
        s_reg5,
        s_reg6,
        s_reg7
    )
    begin
        s_reg_ready_comb <= '0';
        s_reg_data_comb  <= (others => '0');

        if s_rd_active = '1' and s_rd_addr < x"00000020" then
            s_reg_ready_comb <= '1';

            case s_rd_addr(4 downto 2) is
                when "000" => s_reg_data_comb <= s_reg0;
                when "001" => s_reg_data_comb <= s_reg1;
                when "010" => s_reg_data_comb <= s_reg2;
                when "011" => s_reg_data_comb <= s_reg3;
                when "100" => s_reg_data_comb <= s_reg4;
                when "101" => s_reg_data_comb <= s_reg5;
                when "110" => s_reg_data_comb <= s_reg6;
                when "111" => s_reg_data_comb <= s_reg7;
                when others => s_reg_data_comb <= (others => '0');
            end case;
        end if;
    end process;

    --------------------------------------------------------------------
    -- RAM CONTROL
    --------------------------------------------------------------------
    process(
        s_wr_active,
        wvalid,
        s_wr_addr,
        wdata,
        s_rd_active,
        s_rd_addr,
        s_rd_cmd_left,
        s_rd_total_beats,
        s_ram_cmd_addr,
        s_ram_addr,
        arburst,
        arlen,
        araddr,
        wstrb
    )
        variable v_cs        : std_logic;
        variable v_we        : std_logic;
        variable v_addr      : unsigned(9 downto 0);
        variable v_wstrb     : std_logic_vector(3 downto 0);
        variable v_din       : std_logic_vector(31 downto 0);
        variable wrap_beats  : unsigned(9 downto 0);
        variable wrap_mask_i : unsigned(9 downto 0);
        variable base_idx    : unsigned(9 downto 0);
        variable offset_idx  : unsigned(9 downto 0);
    begin
        v_cs    := '0';
        v_we    := '0';
        v_addr  := s_ram_addr;
        v_din   := (others => '0');
        v_wstrb := (others => '0');

        if s_wr_active = '1' and wvalid = '1' and
           s_wr_addr >= x"00001000" and s_wr_addr <= x"00002FFF" then

            v_cs    := '1';
            v_we    := '1';
            v_addr  := unsigned(s_wr_addr(11 downto 2));
            v_wstrb := wstrb;
            v_din   := wdata;

        elsif s_rd_active = '1' and
              s_rd_addr >= x"00001000" and s_rd_addr <= x"00002FFF" and
              s_rd_cmd_left > 0 then

            v_cs := '1';
            v_we := '0';

            if s_rd_cmd_left = s_rd_total_beats then
                v_addr := unsigned(s_rd_addr(11 downto 2));
            else
                case arburst is

                    when "00" =>  -- FIXED
                        v_addr := s_ram_cmd_addr;

                    when "01" =>  -- INCR
                        v_addr := s_ram_cmd_addr + 1;

                    when "10" =>  -- WRAP
                        wrap_beats  := resize(unsigned(arlen), 10) + 1;
                        wrap_mask_i := not (wrap_beats - 1);

                        base_idx   := unsigned(araddr(11 downto 2)) and wrap_mask_i;
                        offset_idx := s_ram_cmd_addr - base_idx;
                        offset_idx := (offset_idx + 1) mod wrap_beats;
                        v_addr     := base_idx + offset_idx;

                    when others =>
                        v_addr := s_ram_cmd_addr + 1;

                end case;
            end if;
        end if;

        s_ram_cs_next    <= v_cs;
        s_ram_we_next    <= v_we;
        s_ram_addr_next  <= v_addr;
        s_ram_wstrb_next <= v_wstrb;
        s_ram_din_next   <= v_din;
    end process;

    --------------------------------------------------------------------
    -- RAM PROCESS
    --------------------------------------------------------------------
    process(clk, resetn)
    begin
        if resetn = '0' then
            s_ram_cs         <= '0';
            s_ram_we         <= '0';
            s_ram_addr       <= (others => '0');
            s_ram_din        <= (others => '0');
            s_ram_read_valid <= '0';
            s_ram_ready      <= '0';
            s_ram_cmd_addr   <= (others => '0');
            s_ram_wstrb      <= (others => '0');

        elsif rising_edge(clk) then
            s_ram_cs    <= s_ram_cs_next;
            s_ram_we    <= s_ram_we_next;
            s_ram_addr  <= s_ram_addr_next;
            s_ram_din   <= s_ram_din_next;
            s_ram_wstrb <= s_ram_wstrb_next;

            if s_ram_cs_next = '1' and s_ram_we_next = '0' then
                s_ram_cmd_addr <= s_ram_addr_next;
            end if;

            s_ram_read_valid <= s_ram_cs_next and (not s_ram_we_next);
            s_ram_ready      <= s_ram_read_valid;
        end if;
    end process;

    --------------------------------------------------------------------
    -- VALID RAM
    --------------------------------------------------------------------
    s_rvalid_ram <= s_ram_ready and s_rd_active;

    --------------------------------------------------------------------
    -- MUX FINALE
    --------------------------------------------------------------------
    process(
        s_rd_active,
        s_rd_addr,
        s_reg_data_comb,
        s_reg_ready_comb,
        s_rd_data_left,
        s_ram_dout,
        s_rvalid_ram,
        fifo_out_valid,
        fifo_out_data,
        s_rid_reg,
        s_rresp,
        reg_err_exokay,
        reg_err_slverr,
        reg_err_decerr,
        reg_err_timeout
    )
    begin
        rdata  <= (others => '0');
        rvalid <= '0';
        rlast  <= '0';
        rresp  <= s_rresp;
        rid    <= s_rid_reg;

        if s_rd_active = '1' then

            ----------------------------------------------------------------
            -- REGISTRI 0x00000000 – 0x0000001F
            ----------------------------------------------------------------
            if s_rd_addr < x"00000020" then
                rdata  <= s_reg_data_comb;
                rvalid <= s_reg_ready_comb;
                if s_rd_data_left = 1 then
                    rlast <= s_reg_ready_comb;
                end if;

            ----------------------------------------------------------------
            -- RAM 0x00001000 – 0x00002FFF
            ----------------------------------------------------------------
            elsif s_rd_addr >= x"00001000" and s_rd_addr <= x"00002FFF" then
                rdata  <= s_ram_dout;
                rvalid <= s_rvalid_ram;
                if s_rd_data_left = 1 then
                    rlast <= s_rvalid_ram;
                end if;

            ----------------------------------------------------------------
            -- FIFO READ 0x00003100
            ----------------------------------------------------------------
            elsif s_rd_addr = x"00003100" then
                rdata  <= fifo_out_data;
                rvalid <= fifo_out_valid;
                if s_rd_data_left = 1 then
                    rlast <= fifo_out_valid;
                end if;

            ----------------------------------------------------------------
            -- TEST_ERROR: EXOKAY (0x4000)
            ----------------------------------------------------------------
            elsif s_rd_addr = x"00004000" then
                rdata  <= reg_err_exokay;
                rvalid <= '1';
                rresp  <= "01";
                if s_rd_data_left = 1 then
                    rlast <= '1';
                end if;

            ----------------------------------------------------------------
            -- TEST_ERROR: SLVERR (0x4004)
            ----------------------------------------------------------------
            elsif s_rd_addr = x"00004004" then
                rdata  <= reg_err_slverr;
                rvalid <= '1';
                rresp  <= "10";
                if s_rd_data_left = 1 then
                    rlast <= '1';
                end if;

            ----------------------------------------------------------------
            -- TEST_ERROR: DECERR (0x4008)
            ----------------------------------------------------------------
            elsif s_rd_addr = x"00004008" then
                rdata  <= reg_err_decerr;
                rvalid <= '1';
                rresp  <= "11";
                if s_rd_data_left = 1 then
                    rlast <= '1';
                end if;

            ----------------------------------------------------------------
            -- TEST_ERROR: TIMEOUT (0x400C)
            ----------------------------------------------------------------
            elsif s_rd_addr = x"0000400C" then
                rdata  <= reg_err_timeout;
                rvalid <= '0';
                rresp  <= "00";
                rlast  <= '0';

            ----------------------------------------------------------------
            -- DEFAULT: fuori range → DECERR
            ----------------------------------------------------------------
            else
                rdata  <= (others => '0');
                rvalid <= '1';
                rresp  <= "11";
                if s_rd_data_left = 1 then
                    rlast <= '1';
                end if;
            end if;

        end if;
    end process;

end architecture;
