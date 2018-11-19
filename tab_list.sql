-- Reports on the table columns and indexes format a given table
-- Input: owner.table_name

set echo off verify off
set pagesize 50

column table_name format a29
column column_name format a29
column id format 99
column data_type format a14
column n format a1
column index_name format a30

break on table_name
break on index_name on parted
select distinct table_name, column_id id, column_name,
       data_type||decode(instr(data_type,'TIMESTAMP'),0,'('||data_length||')') data_type--,
--       decode(nullable,null,'N') n
from all_tab_columns
where table_name = upper(substr('&1',instr('&1','.')+1,length('&1')))
and owner in (upper(substr('&1',1,instr('&1','.')-1)),user)
order by column_id;

select distinct c.index_name, i.partitioned parted, c.column_position id, c.column_name,
       i.uniqueness
from all_indexes i, all_ind_columns c
where i.index_name = c.index_name
  and i.table_name = upper(substr('&1',instr('&1','.')+1,length('&1')))
  and i.owner in (upper(substr('&1',1,instr('&1','.')-1)),user)
  and i.owner = c.index_owner
order by index_name, column_position;

set long 1000
select e.index_name, c.column_name, e.column_position, e.column_expression
from all_ind_expressions e, all_ind_columns c
where e.table_name = upper(substr('&1',instr('&1','.')+1,length('&1')))
and e.table_owner in (upper(substr('&1',1,instr('&1','.')-1)),user)
and e.table_owner = c.table_owner
and e.column_position = c.column_position
and e.index_name = c.index_name
order by index_name, column_position;

set verify on
