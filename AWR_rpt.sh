#!/bin/bash
#
DEBUG=0
report_type=$1

source ~/.bash_profile
. /home/<Location>/config/config.env

AWR_EMAIL_BODY=$DBA_LOG/awr_mail_body.msg
if [ $DEBUG -eq 1 ]; then export EMAIL_LIST='jon@gmail.com'; fi
if [ $DEBUG -eq 1 ]; then export AV5_DB_LIST='prod01'; fi

cd $DBA_LOG
rm -f $DBA_LOG/awr_*.html $DBA_LOG/awr_*.txt

for i in $AV5_DB_LIST; do

sqlplus -s $ZABBIXPASS@$i <<EOF
set lines 130
set feedback off
set pages 0
DEFINE num_days=7;
DEFINE i_instance='$i';
DEFINE report_name='awr_$i';
DEFINE begin_snap=0;
DEFINE end_snap=0;
DEFINE inst_num=0;
DEFINE dbid=0;

col    dbid     heading "dbid"               new_value dbid        for 9999999999;
SELECT dbid FROM v\$DATABASE;

col    inst_num heading "INSTANCE_NUMBER"    new_value inst_num    for 99999999;
SELECT INSTANCE_NUMBER inst_num from gv\$instance;

col    begin_snap heading "Min SNAP ID"      new_value begin_snap  for 9999999999;
col    end_snap   heading "Max SNAP ID"      new_value end_snap    for 9999999999;

SELECT MIN(SNAP_ID) begin_snap FROM dba_hist_snapshot WHERE TRUNC(begin_interval_time) = TRUNC(SYSDATE-&num_days);
SELECT MAX(SNAP_ID) end_snap FROM dba_hist_snapshot WHERE TRUNC(begin_interval_time) = TRUNC(SYSDATE);

col    inst_name  heading "Instance Name"    new_value inst_name    for A16;
SELECT UPPER('&i_instance') inst_name FROM DUAL;

col    report_name heading "AWR file name"   new_value report_name  for A30;

SELECT &inst_num  inst_num        FROM DUAL;
SELECT &dbid      dbid            FROM DUAL;
SELECT &num_days  num_days        FROM DUAL;
SELECT '&report_type' report_type FROM DUAL;
SELECT '&report_name' report_name FROM DUAL;
SELECT &begin_snap begin_snap     FROM DUAL;
SELECT &end_snap end_snap         FROM DUAL;

DEFINE report_type='$report_type';
SELECT '$DBA_LOG/&report_name'.html' report_name FROM DUAL;
@?/rdbms/admin/awrrpti.sql

undefine num_days;
undefine report_type;
undefine report_name;
undefine begin_snap;
undefine i_instance;
undefine inst_name;
undefine inst_num;
undefine end_snap;
undefine dbid;
EOF

if [ -z $report_type ] || [ "$report_type" == "html" ]
 then mv $DBA_LOG/awr_$i.lst $DBA_LOG/awr_$i.html
 else mv $DBA_LOG/awr_$i.lst $DBA_LOG/awr_$i.txt
fi

done

# logic below still sents email if for some reason the database has been down during the past week

filelist=`ls $DBA_LOG/awr_*.html $DBA_LOG/awr_*txt 2>/dev/null|sed 's/^/-a /'|tr "\n" " "`

echo "~~~~~~~ATTENTION~~~~~~~~~~~~~" >> $AWR_EMAIL_BODY
echo "___see AWR attached report__ " >> $AWR_EMAIL_BODY
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $AWR_EMAIL_BODY
echo "............................." >> $AWR_EMAIL_BODY
cat -v $AWR_EMAIL_BODY | mailx -s "--AWR REPORT:`hostname`-->" $filelist $EMAIL_LIST

rm -rf $AWR_EMAIL_BODY

exit 0
