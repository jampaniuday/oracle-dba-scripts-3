--
-- Copyright (c) 1988, 2005, Oracle.  All Rights Reserved.
--
-- NAME
--   glogin.sql
--
-- DESCRIPTION
--   SQL*Plus global login "site profile" file
--
--   Add any SQL*Plus commands here that are to be executed when a
--   user starts SQL*Plus, or uses the SQL*Plus CONNECT command.
--
-- USAGE
--   This script is automatically run
--
define _editor=vi
set linesize 110
set pagesize 0 embedded on head on
set feedback off
col bytes for 999,999,999,999,999
alter session set nls_date_format='MON-DD-YYYY HH24:MI:SS';
set feedback on
set sqlprompt "_user'@'_connect_identifier>"
