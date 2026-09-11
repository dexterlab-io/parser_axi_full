-- ======================================================================
--  DexterLab™
--  Copyright (c) DexterLab
--  Released as free example code for educational and non-commercial use.
--  No warranty is provided. Use at your own risk.
--  © 2026 DexterLab
-- ======================================================================
--  File: cmd_cfg.vhd
--  Author: Dexter
--  Date: 2026-09-05
--  Version: 1.0
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package cmd_cfg is

    --------------------------------------------------------------------
    -- Logging configuration
    --------------------------------------------------------------------
    -- Abilita/disabilita i messaggi di debug (severity note).
    -- Warning, Error e Fatal rimangono sempre attivi.
    --------------------------------------------------------------------
    constant ENABLE_DEBUG_LOG : boolean := false;

    --------------------------------------------------------------------
    -- CONFIGURAZIONE DI BASE
    --------------------------------------------------------------------
    constant C_ADDR_WIDTH : natural := 32;
    constant C_DATA_WIDTH : natural := 32;

    -- Numero massimo di valori dati che un singolo microcomando può contenere.
    -- Il burst logico può essere > C_MAX_DATA_TOKENS (es. 1024),
    -- ma verrà spezzato in più micro-burst in cmd_cmd_pkg.
    constant C_MAX_DATA_TOKENS    : natural := 1024;  -- buffer per singolo micro-burst
    constant C_MAX_DATA_PER_LINE  : natural := 8;

    --------------------------------------------------------------------
    -- BUFFER MICROCOMANDI
    --------------------------------------------------------------------
    -- Numero massimo di microcomandi generabili dal parser per una riga.
    -- Una singola riga (anche con burst grandi) non genera mai più di
    -- qualche decina di microcomandi; 64 è un valore ampiamente sufficiente.
    constant C_MAX_MC : natural := 64;

    -- Timeout massimo (in unità interne) usato dai comandi di tipo POLL/WAIT.
    constant C_MAX_TIMEOUT : natural := 1024;

    constant C_MAX_AXI_TIMEOUT : integer := 1024;  -- o il valore che preferisci

    --------------------------------------------------------------------
    -- COSTANTI DERIVATE MINIME
    --------------------------------------------------------------------
    constant C_MAX_STRING        : natural := 256;
    constant C_MAX_INCLUDE_DEPTH : natural := 16;

    constant C_ID_WIDTH   : natural := 4;
    constant C_MAX_ATOMIC : natural := 16;

    constant C_CFG_WIDTH : integer := 8;
    constant C_PKG_WIDTH : integer := 16;

    --------------------------------------------------------------------
    -- ID dei generatori di comandi
    --------------------------------------------------------------------
    constant ID_PARSER : unsigned(C_ID_WIDTH-1 downto 0) := to_unsigned(0, C_ID_WIDTH);
    constant ID_MASTER : unsigned(C_ID_WIDTH-1 downto 0) := to_unsigned(1, C_ID_WIDTH);

    --------------------------------------------------------------------
    -- TIPI BASE
    --------------------------------------------------------------------
    subtype t_addr is std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    subtype t_data is std_logic_vector(C_DATA_WIDTH-1 downto 0);

    type t_line is array(1 to C_MAX_STRING) of character;


end package cmd_cfg;

package body cmd_cfg is
end package body cmd_cfg;
