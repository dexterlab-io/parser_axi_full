# ======================================================================
#  DexterLab™
#  Copyright (c) DexterLab
#  Released as free example code for educational and non-commercial use.
#  No warranty is provided. Use at your own risk.
#  © 2026 DexterLab
# ======================================================================
#  File: Makefile
#  Author: Dexter
#  Date: 2026-05-13
#  Version: 1.0
# ======================================================================


.SILENT:

#VERBOSE	= ""
#VERBOSE	= " -v "
#WAVEFORMAT	= vcd
#WAVEFORMAT	= fst

VERBOSE		= " -v "
WAVEFORMAT	= ghw

ifeq ($(WAVEFORMAT),vcd)
WAVE		= wave.vcd
WAVECMD		= --vcd=wave.vcd
endif

ifeq ($(WAVEFORMAT),ghw)
WAVE		= wave.ghw
WAVECMD		= --wave=wave.ghw
endif

ifeq ($(WAVEFORMAT),fst)
WAVE		= wave.fst
WAVECMD		= --wave=wave.fst
endif

WORKDIR		= ./workdir

TOP		= tb_axi_full

VHDL_93		= ghdl -a -C --std=93	 -lv --workdir=$(WORKDIR)
VHDL_93C	= ghdl -a --std=93c	 -lv --workdir=$(WORKDIR)
VHDL_2008	= ghdl -a --std=08	 -lv --workdir=$(WORKDIR)
VHDL_2002	= ghdl -a --std=02	 -lv --workdir=$(WORKDIR)

ELAB_93		= ghdl -e -C --std=93	 -lv --workdir=$(WORKDIR)
ELAB_93C	= ghdl -e --std=93c	 -lv --workdir=$(WORKDIR)
ELAB_2008	= ghdl -e --std=08	 -lv --workdir=$(WORKDIR)
ELAB_2002	= ghdl -e --std=02	 -lv --workdir=$(WORKDIR)


RTL_PARSER	=	../../../rtl/cmd_cfg.vhd \
			../../../rtl/cmd_text_pkg.vhd \
			../../../rtl/cmd_cmd_pkg.vhd \
			../../../rtl/cmd_vars_pkg.vhd \
			../../../rtl/cmd_map_pkg.vhd \
			../../../rtl/cmd_math_pkg.vhd \
			../../../rtl/cmd_time_pkg.vhd \
			../../../rtl/cmd_micro_pkg.vhd \
			../../../rtl/cmd_lex_pkg.vhd \
			../../../rtl/cmd_eval_pkg.vhd \
			../../../rtl/cmd_parse_pkg.vhd \
			../../../rtl/cmd_semantic_pkg.vhd \
			../../../rtl/cmd_split_pkg.vhd \
			../../../rtl/cmd_log_pkg.vhd \
			../../../rtl/cmd_file_pkg.vhd \
			../../../rtl/cmd_pkg.vhd \
			../../../rtl/cmd_parser.vhd

RTL_AXI_FULL	=	../../../rtl/cmd_axi_full.vhd

TB		=	../../../tb/ckrst.vhd \
			../../../tb/cmd_master.vhd \
			../../../tb/arbiter_mux.vhd \
			../../../tb/axi_full_monitor.vhd \
			../../../tb/ram_sync.vhd \
			../../../tb/ram_sync_wstrb.vhd \
			../../../tb/gen_fifo_wr.vhd \
			../../../tb/gen_fifo_rd.vhd \
			../../../tb/gen_fifo.vhd \
			../../../tb/axi_full_slave.vhd \
			../../../tb/tb_axi_full.vhd

comp: clean rtl tb elab
all: clean rtl tb elab sim
interactive: clean rtl tb elab simwave

clean:
	rm -f $(WORKDIR)/*.o $(WORKDIR)/*.cf $(WORKDIR)/$(TOP) $(WORKDIR)/$(WAVE)
	rm -f *.o *.cf $(TOP) $(WAVE) *.log


rtl:
	echo Compile RTL
	$(VHDL_93)  $(RTL_PARSER)
	$(VHDL_93)  $(RTL_AXI_FULL)

tb:
	echo Compile TB
	$(VHDL_93)  $(TB)

elab:
	echo Elaborate
	$(ELAB_93) $(TOP)

sim:
	echo Simulating
	ghdl -r $(TOP) $(WAVECMD) --stop-time=200us

wave:
	echo Wave
	gtkwave $(WAVE) &

simwave:
	echo Simwave
	rm -f $(WAVE)
	ghdl -r $(TOP) $(WAVECMD) --assert-level=note --stop-time=1ms
	sleep 1
	gtkwave $(WAVE) &


# ============================================================
#  GHDL target (usa il flusso attuale)
# ============================================================
ghdl: all

