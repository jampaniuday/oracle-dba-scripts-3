col owner for a30
col bytes for 999,999,999,999,999
break on report
compute sum of bytes on report
select owner, sum(bytes) bytes from dba_segments where owner not like '%SYS%' and owner not in ('DBSNMP','OUTLN','PERFSTAT','XDB') group by owner order by 1;
