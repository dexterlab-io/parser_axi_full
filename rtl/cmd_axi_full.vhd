-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_axi_full.vhd
--  Author: Dexter
--  Date: 2026-09-06
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmd_cfg.all;
use work.cmd_eval_pkg.all;
use work.cmd_cmd_pkg.all;
use work.cmd_math_pkg.all;

entity cmd_axi_full is
    port (
        ----------------------------------------------------------------
        -- Clock & Reset
        ----------------------------------------------------------------
        clk     : in  std_logic;
        resetn  : in  std_logic;

        ----------------------------------------------------------------
        -- Handshake + record comandi/risposte
        ----------------------------------------------------------------
        valid    : in  std_logic;
        ready    : out std_logic;

        cmd      : in  t_cmd_out;
        rsp_in   : in  t_rsp_out;
        rsp_out  : out t_rsp_in;

        ----------------------------------------------------------------
        -- AXI WRITE ADDRESS CHANNEL (AW)
        ----------------------------------------------------------------
        awvalid : out std_logic;
        awready : in  std_logic;
        awaddr  : out std_logic_vector(C_ADDR_WIDTH-1 downto 0);
        awlen   : out std_logic_vector(7 downto 0);
        awburst : out std_logic_vector(1 downto 0);
        awsize  : out std_logic_vector(2 downto 0);
        awid    : out std_logic_vector(C_ID_WIDTH-1 downto 0);

        -- Nuovi segnali AXI
        awlock  : out std_logic;                       -- cmd_lock
        awcache : out std_logic_vector(3 downto 0);    -- cmd_cache
        awprot  : out std_logic_vector(2 downto 0);    -- cmd_prot
        awqos   : out std_logic_vector(3 downto 0);    -- cmd_qos

        ----------------------------------------------------------------
        -- AXI WRITE DATA CHANNEL (W)
        ----------------------------------------------------------------
        wvalid : out std_logic;
        wready : in  std_logic;
        wdata  : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        wstrb  : out std_logic_vector((C_DATA_WIDTH/8)-1 downto 0);
        wlast  : out std_logic;

        ----------------------------------------------------------------
        -- AXI WRITE RESPONSE CHANNEL (B)
        ----------------------------------------------------------------
        bvalid : in  std_logic;
        bready : out std_logic;
        bresp  : in  std_logic_vector(1 downto 0);
        bid    : in  std_logic_vector(C_ID_WIDTH-1 downto 0);

        ----------------------------------------------------------------
        -- AXI READ ADDRESS CHANNEL (AR)
        ----------------------------------------------------------------
        arvalid : out std_logic;
        arready : in  std_logic;
        araddr  : out std_logic_vector(C_ADDR_WIDTH-1 downto 0);
        arlen   : out std_logic_vector(7 downto 0);
        arburst : out std_logic_vector(1 downto 0);
        arsize  : out std_logic_vector(2 downto 0);
        arid    : out std_logic_vector(C_ID_WIDTH-1 downto 0);

        -- Nuovi segnali AXI
        arlock  : out std_logic;                       -- cmd_lock
        arcache : out std_logic_vector(3 downto 0);    -- cmd_cache
        arprot  : out std_logic_vector(2 downto 0);    -- cmd_prot
        arqos   : out std_logic_vector(3 downto 0);    -- cmd_qos

        ----------------------------------------------------------------
        -- AXI READ DATA CHANNEL (R)
        ----------------------------------------------------------------
        rvalid : in  std_logic;
        rready : out std_logic;
        rdata  : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
        rlast  : in  std_logic;
        rresp  : in  std_logic_vector(1 downto 0);
        rid    : in  std_logic_vector(C_ID_WIDTH-1 downto 0)
    );
end entity cmd_axi_full;


architecture rtl of cmd_axi_full is

    --------------------------------------------------------------------
    -- FSM
    --------------------------------------------------------------------
    type t_state is (
        idle,
        wr_aw,
        wr_w,
        wr_b,
        rd_ar,
        rd_r
    );

    signal state_current : t_state := idle;
    signal state_next    : t_state := idle;

    --------------------------------------------------------------------
    -- Tipo burst decodificato
    --------------------------------------------------------------------
    type t_burst_kind is (BK_SINGLE, BK_INCR, BK_WRAP, BK_FIFO);
    signal s_burst_kind : t_burst_kind := BK_SINGLE;

    --------------------------------------------------------------------
    -- Latch dei parametri del comando
    --------------------------------------------------------------------
    signal s_cmd_id_cur : std_logic_vector(C_ID_WIDTH-1 downto 0) := (others => '0');
    signal s_addr_cur   : std_logic_vector(C_ADDR_WIDTH-1 downto 0) := (others => '0');

    -- Indirizzo iniziale del comando
    signal s_addr_start : std_logic_vector(C_ADDR_WIDTH-1 downto 0) := (others => '0');

    -- Dato singolo (per comandi non burst/fifo)
    signal s_data_cur   : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');

    -- Burst
    signal s_burst_len_cur : integer range 1 to 256 := 1;
    signal s_burst_index   : integer range 0 to 255 := 0;

    type t_burst_buf is array (0 to 255)
        of std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal s_burst_buf_cur : t_burst_buf := (others => (others => '0'));

    --------------------------------------------------------------------
    -- Parametri di indirizzamento burst (INCR/WRAP/FIFO)
    --------------------------------------------------------------------
    signal s_beat_bytes   : integer range 1 to 16 := C_DATA_WIDTH / 8;
    signal s_wrap_size    : integer range 0 to 4096 := 0;
    signal s_wrap_base    : std_logic_vector(C_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal s_start_offset : integer range 0 to 4096 := 0;

    --------------------------------------------------------------------
    -- WRITE DATA channel (W)
    --------------------------------------------------------------------
    signal s_wvalid_reg : std_logic := '0';
    signal s_wlast_reg  : std_logic := '0';
    signal s_wdata_cur  : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
    signal s_w_index    : integer range 0 to 255 := 0;
    signal s_wstrb_cur  : std_logic_vector((C_DATA_WIDTH/8)-1 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- AXI burst mode
    --------------------------------------------------------------------
    signal s_awburst_reg : std_logic_vector(1 downto 0) := "01";
    signal s_arburst_reg : std_logic_vector(1 downto 0) := "01";

    constant axsize : std_logic_vector(2 downto 0) := "010";

    --------------------------------------------------------------------
    -- READ DATA channel (R)
    --------------------------------------------------------------------
    signal s_rd_valid : std_logic := '0';
    signal s_rd_last  : std_logic := '0';
    signal s_rd_data  : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
    signal s_rd_id    : std_logic_vector(C_ID_WIDTH-1 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- WRITE → parser (canale W “ritorno”)
    --------------------------------------------------------------------
    signal s_wr_valid : std_logic := '0';
    signal s_wr_last  : std_logic := '0';
    signal s_wr_data  : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
    signal s_wr_id    : std_logic_vector(C_ID_WIDTH-1 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- ERROR channel
    --------------------------------------------------------------------
    signal s_err_valid : std_logic := '0';
    signal s_err_code  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_err_info  : std_logic_vector(31 downto 0) := (others => '0');
    signal s_err_id    : std_logic_vector(C_ID_WIDTH-1 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- AXI handshake
    --------------------------------------------------------------------
    signal s_rready : std_logic := '0';
    signal s_bready : std_logic := '0';

    --------------------------------------------------------------------
    -- ACK / fine comando
    --------------------------------------------------------------------
    signal s_ack      : std_logic := '0';
    signal s_cmd_done : std_logic := '0';

    --------------------------------------------------------------------
    -- Tipo comando registrato (READ/WRITE)
    --------------------------------------------------------------------
    signal s_cmd_is_write : std_logic := '0';

    --------------------------------------------------------------------
    -- READY verso parser
    --------------------------------------------------------------------
    signal s_ready : std_logic := '0';

    signal s_timeout_cnt : integer range 0 to C_MAX_AXI_TIMEOUT := 0;

    signal s_4k_check_ok    : std_logic := '1';
    signal s_burst_check_ok : std_logic := '1';

begin


	--------------------------------------------------------------------
	-- Processo asincrono: verifica crossing 4k boundary
	--------------------------------------------------------------------
	boundary_check_proc : process(cmd)
		variable start_addr      : unsigned(C_ADDR_WIDTH-1 downto 0);
		variable end_addr        : unsigned(C_ADDR_WIDTH-1 downto 0);
		variable next_4k         : unsigned(C_ADDR_WIDTH-1 downto 0);
		variable burst_len_live  : integer;
		variable beat_bytes      : integer;
	begin
		----------------------------------------------------------------
		-- Default: nessun errore
		----------------------------------------------------------------
		s_4k_check_ok <= '1';

		----------------------------------------------------------------
		-- Se non è burst, o è FIFO (indirizzo fisso), non c'è crossing
		----------------------------------------------------------------
		if cmd.cmd_burst = '0' or cmd.cmd_fifo = '1' then
			-- nessun check → OK
			s_4k_check_ok <= '1';
		else

			----------------------------------------------------------------
			-- Calcolo burst_len_live = clamp(cmd.cmd_len)
			----------------------------------------------------------------
			if cmd.cmd_len < 1 then
				burst_len_live := 1;
			elsif cmd.cmd_len > 256 then
				burst_len_live := 256;
			else
				burst_len_live := cmd.cmd_len;
			end if;

			----------------------------------------------------------------
			-- Dimensione beat
			----------------------------------------------------------------
			beat_bytes := C_DATA_WIDTH / 8;

			----------------------------------------------------------------
			-- Calcolo indirizzi
			----------------------------------------------------------------
			start_addr := unsigned(cmd.cmd_addr);
			end_addr   := start_addr + to_unsigned(burst_len_live * beat_bytes, C_ADDR_WIDTH);
			next_4k    := next_4k_boundary(cmd.cmd_addr);

			----------------------------------------------------------------
			-- Check boundary (AXI: crossing solo se end_addr > next_4k)
			----------------------------------------------------------------
			if end_addr > next_4k then
				s_4k_check_ok <= '0';
			else
				s_4k_check_ok <= '1';
			end if;

		end if;
	end process;


	--------------------------------------------------------------------
	-- Processo asincrono: verifica semantica del burst
	--------------------------------------------------------------------
	burst_check_proc : process(cmd)
		variable burst_len_live : integer;
		variable beat_bytes     : integer;
		variable addr_int       : integer;
	begin
		----------------------------------------------------------------
		-- Default: OK
		----------------------------------------------------------------
		s_burst_check_ok <= '1';

		----------------------------------------------------------------
		-- Calcolo burst_len_live = clamp(1..256)
		----------------------------------------------------------------
		if cmd.cmd_len < 1 then
			burst_len_live := 1;
		elsif cmd.cmd_len > 256 then
			burst_len_live := 256;
		else
			burst_len_live := cmd.cmd_len;
		end if;

		----------------------------------------------------------------
		-- Dimensione beat
		----------------------------------------------------------------
		beat_bytes := C_DATA_WIDTH / 8;

		----------------------------------------------------------------
		-- Indirizzo come integer
		----------------------------------------------------------------
		addr_int := to_integer(unsigned(cmd.cmd_addr));

		----------------------------------------------------------------
		-- SINGLE → nessun check
		----------------------------------------------------------------
		if cmd.cmd_burst = '0' then
			s_burst_check_ok <= '1';

		----------------------------------------------------------------
		-- FIFO (FIXED burst) → indirizzo fisso, nessun check
		----------------------------------------------------------------
		elsif cmd.cmd_fifo = '1' then
			s_burst_check_ok <= '1';

		----------------------------------------------------------------
		-- INCR e WRAP → indirizzo deve essere allineato al beat
		----------------------------------------------------------------
		elsif (addr_int mod beat_bytes) /= 0 then
			s_burst_check_ok <= '0';

		----------------------------------------------------------------
		-- WRAP → lunghezza deve essere una potenza di due (4,8,16,...)
		----------------------------------------------------------------
		elsif cmd.cmd_wrap = '1' then
			if not (burst_len_live = 2 or
					burst_len_live = 4 or
					burst_len_live = 8 or
					burst_len_live = 16 or
					burst_len_live = 32 or
					burst_len_live = 64 or
					burst_len_live = 128 or
					burst_len_live = 256) then
				s_burst_check_ok <= '0';
			else
				s_burst_check_ok <= '1';
			end if;

		----------------------------------------------------------------
		-- Tutto OK (INCR valido)
		----------------------------------------------------------------
		else
			s_burst_check_ok <= '1';
		end if;
	end process;


	--------------------------------------------------------------------
	-- PROCESSO 1: Registro di stato
	--------------------------------------------------------------------
	fsm_sync_state_proc : process(clk, resetn)
	begin
		if resetn = '0' then
			state_current <= idle;
		elsif rising_edge(clk) then
			state_current <= state_next;
		end if;
	end process;

	--------------------------------------------------------------------
	-- PROCESSO 2: Latch parametri comando + timeout + registri dati
	--------------------------------------------------------------------
	fsm_sync_data_proc : process(clk, resetn)
		variable v_len        : integer;
		variable beat_bytes   : integer;
		variable wrap_mask    : unsigned(C_ADDR_WIDTH-1 downto 0);
		variable wrap_base_u  : unsigned(C_ADDR_WIDTH-1 downto 0);
		variable addr_u       : unsigned(C_ADDR_WIDTH-1 downto 0);
		variable offset       : integer;
		variable next_addr    : unsigned(C_ADDR_WIDTH-1 downto 0);
	begin
		if resetn = '0' then

			s_cmd_id_cur    <= (others => '0');
			s_addr_cur      <= (others => '0');
			s_addr_start    <= (others => '0');
			s_data_cur      <= (others => '0');

			s_burst_len_cur <= 1;
			s_burst_index   <= 0;
			s_burst_buf_cur <= (others => (others => '0'));

			s_cmd_is_write  <= '0';
			s_timeout_cnt   <= 0;

			s_burst_kind    <= BK_SINGLE;
			s_beat_bytes    <= C_DATA_WIDTH / 8;
			s_wrap_size     <= 0;
			s_wrap_base     <= (others => '0');
			s_start_offset  <= 0;

			s_rd_valid <= '0';
			s_rd_last  <= '0';
			s_rd_data  <= (others => '0');
			s_rd_id    <= (others => '0');

		elsif rising_edge(clk) then

			----------------------------------------------------------------
			-- Timeout counter
			----------------------------------------------------------------
			if state_current = rd_r then
				if rvalid = '1' and s_rready = '1' then
					s_timeout_cnt <= 0;
				else
					if s_timeout_cnt < C_MAX_AXI_TIMEOUT then
						s_timeout_cnt <= s_timeout_cnt + 1;
					end if;
				end if;

			elsif state_current = wr_b then
				if bvalid = '1' and s_bready = '1' then
					s_timeout_cnt <= 0;
				else
					if s_timeout_cnt < C_MAX_AXI_TIMEOUT then
						s_timeout_cnt <= s_timeout_cnt + 1;
					end if;
				end if;

			else
				s_timeout_cnt <= 0;
			end if;

			----------------------------------------------------------------
			-- Latch del comando (solo se valido e non boundary-cross)
			----------------------------------------------------------------
			if state_current = idle and valid = '1' and s_ready = '1' then

				if s_4k_check_ok = '1' and s_burst_check_ok = '1' then

					----------------------------------------------------------------
					-- Burst length clamp
					----------------------------------------------------------------
					v_len := cmd.cmd_len;
					if v_len < 1 then
						v_len := 1;
					elsif v_len > 256 then
						v_len := 256;
					end if;

					s_burst_len_cur <= v_len;
					beat_bytes := C_DATA_WIDTH / 8;
					s_beat_bytes <= beat_bytes;

					----------------------------------------------------------------
					-- Latch parametri base
					----------------------------------------------------------------
					s_cmd_is_write <= cmd.cmd_write;
					s_cmd_id_cur   <= std_logic_vector(cmd.cmd_id);
					s_addr_start   <= std_logic_vector(cmd.cmd_addr);
					s_addr_cur     <= std_logic_vector(cmd.cmd_addr);
					s_data_cur     <= cmd.cmd_data(0);
					s_burst_index  <= 0;

					----------------------------------------------------------------
					-- Decodifica tipo burst
					----------------------------------------------------------------
					if cmd.cmd_burst = '0' then
						s_burst_kind <= BK_SINGLE;

					elsif cmd.cmd_fifo = '1' then
						s_burst_kind <= BK_FIFO;

					elsif cmd.cmd_wrap = '1' then
						s_burst_kind <= BK_WRAP;

					else
						s_burst_kind <= BK_INCR;
					end if;

					----------------------------------------------------------------
					-- Precalcolo WRAP (solo se serve)
					----------------------------------------------------------------
					if cmd.cmd_wrap = '1' then
						-- wrap_size = burst_len * beat_bytes
						s_wrap_size <= v_len * beat_bytes;

						-- wrap_base = addr & ~(wrap_size - 1)
						wrap_mask := not to_unsigned((v_len * beat_bytes) - 1, C_ADDR_WIDTH);
						addr_u    := unsigned(cmd.cmd_addr);
						wrap_base_u := addr_u and wrap_mask;

						s_wrap_base <= std_logic_vector(wrap_base_u);

						-- start_offset = addr - wrap_base
						s_start_offset <= to_integer(addr_u - wrap_base_u);

					else
						s_wrap_size    <= 0;
						s_wrap_base    <= (others => '0');
						s_start_offset <= 0;
					end if;

				end if; -- check OK
			end if; -- latch comando

			--------------------------------------------------------------------
			-- Gestione indice burst lato READ + aggiornamento indirizzo
			--------------------------------------------------------------------
			if state_current = rd_r and rvalid = '1' and s_rready = '1' then

				----------------------------------------------------------------
				-- Aggiornamento indirizzo SOLO per INCR/WRAP, burst > 1, beat NON ultimo
				----------------------------------------------------------------
				if s_burst_len_cur > 1 and rlast = '0' then

					case s_burst_kind is

						----------------------------------------------------------------
						-- SINGLE / FIFO → indirizzo fisso
						----------------------------------------------------------------
						when BK_SINGLE =>
							null;

						when BK_FIFO =>
							null;

						----------------------------------------------------------------
						-- INCR → addr + beat_bytes
						----------------------------------------------------------------
						when BK_INCR =>
							next_addr := unsigned(s_addr_cur) +
										to_unsigned(s_beat_bytes, C_ADDR_WIDTH);
							s_addr_cur <= std_logic_vector(next_addr);

						----------------------------------------------------------------
						-- WRAP → wrap_base + ((start_offset + (index+1)*beat_bytes) mod wrap_size)
						----------------------------------------------------------------
						when BK_WRAP =>
							offset := s_start_offset + (s_burst_index + 1) * s_beat_bytes;

							if s_wrap_size > 0 then
								offset := offset mod s_wrap_size;
							else
								offset := 0;
							end if;

							next_addr := unsigned(s_wrap_base) +
										to_unsigned(offset, C_ADDR_WIDTH);

							s_addr_cur <= std_logic_vector(next_addr);

					end case;

				end if;

				----------------------------------------------------------------
				-- Aggiornamento indice SOLO dopo aver aggiornato l’indirizzo
				----------------------------------------------------------------
				if s_burst_len_cur > 1 then
					if rlast = '0' and s_burst_index < s_burst_len_cur - 1 then
						s_burst_index <= s_burst_index + 1;
					end if;
				end if;

			end if;

			----------------------------------------------------------------
			-- Registri dati di ritorno (solo READ)
			----------------------------------------------------------------
			s_rd_valid <= '0';

			if rvalid = '1' and s_rready = '1' then
				s_rd_valid <= '1';
				s_rd_last  <= rlast;
				s_rd_data  <= rdata;
				s_rd_id    <= rid;
			else
				s_rd_last <= '0';
			end if;

		end if;
	end process;




	--------------------------------------------------------------------
	-- PROCESSO 3: Generazione risposte (ACK, DONE, ERRORI)
	--------------------------------------------------------------------
	fsm_sync_resp_proc : process(clk, resetn)
	begin
		if resetn = '0' then

			s_err_valid <= '0';
			s_err_code  <= (others => '0');
			s_err_info  <= (others => '0');
			s_err_id    <= (others => '0');

			s_ack       <= '0';
			s_cmd_done  <= '0';

		elsif rising_edge(clk) then

			----------------------------------------------------------------
			-- Default: nessuna risposta
			----------------------------------------------------------------
			s_err_valid <= '0';
			s_ack       <= '0';
			s_cmd_done  <= '0';

			----------------------------------------------------------------
			-- TIMEOUT
			----------------------------------------------------------------
			if s_timeout_cnt = C_MAX_AXI_TIMEOUT then
				s_err_valid <= '1';
				s_err_code  <= x"04";  -- TIMEOUT
				s_err_info  <= (others => '0');
				s_err_id    <= s_cmd_id_cur;

				s_ack       <= '1';
				s_cmd_done  <= '1';
			end if;

			----------------------------------------------------------------
			-- BOUNDARY_ERR (comando illegale)
			----------------------------------------------------------------
			if state_current = idle and valid='1' and s_ready='1' and s_4k_check_ok='0' then
				s_err_valid <= '1';
				s_err_code  <= std_logic_vector(to_unsigned(6,8));
				s_err_info  <= s_addr_cur;
				s_err_id    <= s_cmd_id_cur;

				s_ack       <= '1';
				s_cmd_done  <= '1';
			end if;

			----------------------------------------------------------------
			-- BURST_ERR (errore semantico burst)
			----------------------------------------------------------------
			if state_current = idle and valid='1' and s_ready='1' and s_burst_check_ok='0' then
				s_err_valid <= '1';
				s_err_code  <= std_logic_vector(to_unsigned(7,8));  -- BURST_ERR
				s_err_info  <= s_addr_cur;
				s_err_id    <= s_cmd_id_cur;

				s_ack       <= '1';
				s_cmd_done  <= '1';
			end if;

			----------------------------------------------------------------
			-- WRITE-family: fine comando su BRESP
			----------------------------------------------------------------
			if s_cmd_is_write = '1' then
				if bvalid = '1' and s_bready = '1' then

					s_ack      <= '1';
					s_cmd_done <= '1';

					s_err_code <= "000000" & bresp;
					s_err_id   <= bid;

					if bresp /= "00" then
						s_err_valid <= '1';
						s_err_info  <= (others => '0');
					end if;
				end if;
			end if;

			----------------------------------------------------------------
			-- READ-family: fine comando su ultimo beat R
			----------------------------------------------------------------
			if s_cmd_is_write = '0' then
				if rvalid = '1' and s_rready = '1' and rlast = '1' then

					s_ack      <= '1';
					s_cmd_done <= '1';

					s_err_code <= "000000" & rresp;
					s_err_id   <= rid;

					if rresp /= "00" then
						s_err_valid <= '1';
						s_err_info  <= (others => '0');
					end if;
				end if;
			end if;

		end if;
	end process;



	--------------------------------------------------------------------
	-- FSM combinatoria AXI (scelta stato successivo)
	--------------------------------------------------------------------
	fsm_comb_proc : process(
		state_current,
		valid,
		cmd,              -- record live (solo in IDLE/fine comando)
		s_ready,
		s_4k_check_ok,
		awready,
		wready,
		s_burst_len_cur,
		s_w_index,
		s_cmd_done,
		arready
	)
	begin
		state_next <= state_current;

		case state_current is

			----------------------------------------------------------------
			-- IDLE → decide se WRITE o READ
			-- Usa dati live per latenza minima di start
			----------------------------------------------------------------
			when idle =>
				if valid = '1' and s_ready = '1' then
					if s_4k_check_ok = '0' then
						state_next <= idle;   -- abort
					else
						if cmd.cmd_write = '1' then
							state_next <= wr_aw;
						else
							state_next <= rd_ar;
						end if;
					end if;
				end if;

			----------------------------------------------------------------
			-- WRITE ADDRESS
			----------------------------------------------------------------
			when wr_aw =>
				if awready = '1' then
					state_next <= wr_w;
				else
					state_next <= wr_aw;
				end if;

			----------------------------------------------------------------
			-- WRITE DATA
			----------------------------------------------------------------
			when wr_w =>
				if wready = '1' then

					-- SINGLE beat
					if s_burst_len_cur <= 1 then
						state_next <= wr_b;

					-- MULTI beat: ultimo beat?
					elsif s_w_index = s_burst_len_cur - 1 then
						state_next <= wr_b;

					else
						state_next <= wr_w;
					end if;

				else
					state_next <= wr_w;
				end if;

			----------------------------------------------------------------
			-- WRITE RESPONSE
			-- Fine comando WRITE: aspetta s_cmd_done
			----------------------------------------------------------------
			when wr_b =>
				if s_cmd_done = '1' then
					if valid = '1' then
						if cmd.cmd_write = '1' then
							state_next <= wr_aw;
						else
							state_next <= rd_ar;
						end if;
					else
						state_next <= idle;
					end if;
				else
					state_next <= wr_b;
				end if;

			----------------------------------------------------------------
			-- READ ADDRESS
			----------------------------------------------------------------
			when rd_ar =>
				if arready = '1' then
					state_next <= rd_r;
				else
					state_next <= rd_ar;
				end if;

			----------------------------------------------------------------
			-- READ DATA (corretto)
			-- Fine comando READ: aspetta s_cmd_done, NON rlast
			----------------------------------------------------------------
			when rd_r =>
				if s_cmd_done = '1' then
					if valid = '1' then
						if cmd.cmd_write = '1' then
							state_next <= wr_aw;
						else
							state_next <= rd_ar;
						end if;
					else
						state_next <= idle;
					end if;
				else
					state_next <= rd_r;
				end if;

			when others =>
				state_next <= idle;

		end case;
	end process;


	--------------------------------------------------------------------
	-- Canale AXI WRITE DATA (W): wdata, wvalid, wlast
	--------------------------------------------------------------------
	axi_w_proc : process(clk, resetn)
	begin
		if resetn = '0' then
			s_wvalid_reg <= '0';
			s_wlast_reg  <= '0';
			s_wdata_cur  <= (others => '0');
			s_wstrb_cur  <= (others => '0');
			s_w_index    <= 0;

		elsif rising_edge(clk) then

			if state_current = wr_w then

				----------------------------------------------------------------
				-- Primo beat: aspetta AWREADY
				----------------------------------------------------------------
				if s_wvalid_reg = '0' then
					if awready = '1' then
						s_w_index <= 0;

						-- Dato iniziale
						s_wdata_cur <= cmd.cmd_data(0);
						s_wstrb_cur <= cmd.cmd_wstrb;
						s_wvalid_reg <= '1';

						if s_burst_len_cur = 1 then
							s_wlast_reg <= '1';
						else
							s_wlast_reg <= '0';
						end if;
					end if;

				----------------------------------------------------------------
				-- Beat successivi
				----------------------------------------------------------------
				elsif s_wvalid_reg = '1' and wready = '1' then

					----------------------------------------------------------------
					-- Aggiornamento indice + dati
					----------------------------------------------------------------
					if s_w_index < s_burst_len_cur - 1 then
						s_w_index <= s_w_index + 1;
						s_wdata_cur <= cmd.cmd_data(s_w_index + 1);
						s_wstrb_cur <= cmd.cmd_wstrb;

						if (s_w_index + 1) = s_burst_len_cur - 1 then
							s_wlast_reg <= '1';
						else
							s_wlast_reg <= '0';
						end if;

					else
						-- ultimo beat già emesso: chiudi
						s_wvalid_reg <= '0';
						s_wlast_reg  <= '0';
						s_w_index    <= 0;
						s_wstrb_cur  <= (others => '0');
					end if;

				end if;

			else
				----------------------------------------------------------------
				-- Fuori da wr_w: chiudi eventuali segnali pendenti
				----------------------------------------------------------------
				if s_wvalid_reg = '1' and wready = '1' then
					s_wvalid_reg <= '0';
					s_wlast_reg  <= '0';
					s_w_index    <= 0;
					s_wstrb_cur  <= (others => '0');
				end if;
			end if;

		end if;
	end process;




    --------------------------------------------------------------------
    -- Processo di copia del canale W verso il parser (wr_* → s_wr_*)
    --------------------------------------------------------------------
    wr_copy_proc : process(clk, resetn)
    begin
        if resetn = '0' then
            s_wr_valid <= '0';
            s_wr_last  <= '0';
            s_wr_data  <= (others => '0');
            s_wr_id    <= (others => '0');

        elsif rising_edge(clk) then

            s_wr_valid <= '0';
            s_wr_last  <= '0';

            if s_wvalid_reg = '1' and wready = '1' then
                s_wr_valid <= '1';
                s_wr_last <= s_wlast_reg;
                s_wr_data <= s_wdata_cur;
                s_wr_id   <= s_cmd_id_cur;
            end if;
        end if;
    end process;


	--------------------------------------------------------------------
	-- Processo AXI OUT pipelinato (solo segnali AXI)
	--------------------------------------------------------------------
	axi_out_proc : process(clk, resetn)
	begin
		if resetn = '0' then

			awvalid <= '0';
			awaddr  <= (others => '0');
			awlen   <= (others => '0');
			awid    <= (others => '0');

			arvalid <= '0';
			araddr  <= (others => '0');
			arlen   <= (others => '0');
			arid    <= (others => '0');

			s_bready  <= '0';
			s_rready  <= '0';

			s_awburst_reg <= "01";
			s_arburst_reg <= "01";

		elsif rising_edge(clk) then

			awvalid <= '0';
			arvalid <= '0';
			s_bready  <= '0';
			s_rready  <= '0';

			awid <= s_cmd_id_cur;
			arid <= s_cmd_id_cur;

			case state_current is

				----------------------------------------------------------------
				-- WRITE ADDRESS
				----------------------------------------------------------------
				when wr_aw =>
					awvalid <= '1';
					awaddr  <= s_addr_cur;

					if s_burst_len_cur > 1 then
						awlen <= std_logic_vector(to_unsigned(s_burst_len_cur - 1, 8));
					else
						awlen <= (others => '0');
					end if;

					-- Decodifica AXI BURST per WRITE
					case s_burst_kind is
						when BK_SINGLE =>
							s_awburst_reg <= "00";  -- single beat → FIXED
						when BK_FIFO   =>
							s_awburst_reg <= "00";  -- FIFO → FIXED
						when BK_INCR   =>
							s_awburst_reg <= "01";  -- INCR
						when BK_WRAP   =>
							s_awburst_reg <= "10";  -- WRAP
					end case;

				----------------------------------------------------------------
				-- WRITE RESPONSE
				----------------------------------------------------------------
				when wr_b =>
					s_bready <= '1';

				----------------------------------------------------------------
				-- READ ADDRESS
				----------------------------------------------------------------
				when rd_ar =>
					arvalid <= '1';
					araddr  <= s_addr_cur;

					if s_burst_len_cur > 1 then
						arlen <= std_logic_vector(to_unsigned(s_burst_len_cur - 1, 8));
					else
						arlen <= (others => '0');
					end if;

					-- Decodifica AXI BURST per READ
					case s_burst_kind is
						when BK_SINGLE =>
							s_arburst_reg <= "00";  -- single beat → FIXED
						when BK_FIFO   =>
							s_arburst_reg <= "00";  -- FIFO → FIXED
						when BK_INCR   =>
							s_arburst_reg <= "01";  -- INCR
						when BK_WRAP   =>
							s_arburst_reg <= "10";  -- WRAP
					end case;

				----------------------------------------------------------------
				-- READ DATA
				----------------------------------------------------------------
				when rd_r =>
					s_rready <= '1';

				when others =>
					null;

			end case;
		end if;
	end process;

	--------------------------------------------------------------------
	-- Handshake verso parser
	--------------------------------------------------------------------
	s_ready <= '1' when state_current = idle else '0';
	ready   <= s_ready;

	--------------------------------------------------------------------
	-- Costanti AXI (combinatorie, statiche)
	--------------------------------------------------------------------
	awsize  <= axsize;
	awburst <= s_awburst_reg;

	arsize  <= axsize;
	arburst <= s_arburst_reg;

	wstrb <= s_wstrb_cur;

	awlock  <= cmd.cmd_lock;
	awcache <= cmd.cmd_cache;
	awprot  <= cmd.cmd_prot;
	awqos   <= cmd.cmd_qos;

	arlock  <= cmd.cmd_lock;
	arcache <= cmd.cmd_cache;
	arprot  <= cmd.cmd_prot;
	arqos   <= cmd.cmd_qos;

	--------------------------------------------------------------------
	-- Uscite canale W
	--------------------------------------------------------------------
	wdata  <= s_wdata_cur;
	wvalid <= s_wvalid_reg;
	wlast  <= s_wlast_reg;

	--------------------------------------------------------------------
	-- Uscite canale R/B
	--------------------------------------------------------------------
	rready <= s_rready;
	bready <= s_bready;

	--------------------------------------------------------------------
	-- Uscite verso wrapper: RECORD rsp
	--------------------------------------------------------------------
	rsp_out.rsp_valid <= s_rd_valid when s_cmd_is_write = '0'
						else s_wr_valid when s_cmd_is_write = '1'
						else '0';

	rsp_out.rsp_last  <= s_rd_last  when s_cmd_is_write = '0'
						else s_wr_last;

	rsp_out.rsp_data  <= s_rd_data  when s_cmd_is_write = '0'
						else s_wr_data;

	rsp_out.rsp_id    <= s_rd_id    when s_cmd_is_write = '0'
						else s_wr_id;

	rsp_out.rsp_err_valid <= s_cmd_done;
	rsp_out.rsp_err_code  <= s_err_code;
	rsp_out.rsp_err_info  <= s_err_info;
	rsp_out.rsp_err_id    <= s_err_id;

end architecture rtl;

