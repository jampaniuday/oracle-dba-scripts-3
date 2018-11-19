#!/bin/bash

########################################################################
# Program: validation_reports.sh                                      #
# Location: :/home/<Location>                                          #
#                                                                      #
# Runs queries to update validation_report table and                   #
#  billing_numbers                                                     #
########################################################################

. /home/oracle/.bash_profile

run_time=$(date +%s)
DBA_LOG=/home/<Location> /logs/ax_reports; export DBA_LOG
DBA_TEMP=/tmp; export DBA_TEMP
DBA_DIR=/home/<Location> ; export DBA_DIR
PASS=; export DBAREPOPASS
v_spoke=oemrep

fn_update_validation_table ()
{
(sqlplus -L -s $DBAREPOPASS@$v_spoke << EOF
   set serveroutput on
   set feedback off
   set heading off
   spool $DBA_LOG/ax_billing_report.log
   Select distinct oracle_sid,username from av_storage_param@$v_spoke where status ='ACTIVE';
spool off
EOF
)|while read v_oracle_sid v_schema_name
  do
   if [[ $v_oracle_sid != '' ]];then
        read v_schema_size <<<$(sqlplus -s -L $DBAREPOPASS@$v_spoke << EOF
        set feedback off
        set heading off
        spool $DBA_LOG/ax_billing_report1.log
        SELECT sum(bytes)/1024/1024/1024
        FROM dba_segments@$v_oracle_sid where owner =upper('$v_schema_name');
spool off
EOF
)
        read v_msg_count v_msg_size v_prev_month_count v_prev_month_size <<<$(sqlplus -s -L $DBAREPOPASS@$v_spoke << EOF
        set feedback off
        set heading off
        spool $DBA_LOG/axel_billing_report.log
        select /*+ parallel (z 4) */ count(1),round(sum(MSGSIZE)/1024/1024/1024,2),
        sum(case
        when msgdateprocessed between trunc(add_months(sysdate,-1),'MON') and trunc(sysdate,'MON')
        then 1
        else 0 end) prev_month_count,
        round(sum(case
        when msgdateprocessed between trunc(add_months(sysdate,-1),'MON') and trunc(sysdate,'MON')
        then msgsize
        else 0 end)/1024/1024/1024,2) prev_month_size
        from $v_schema_name.zlpmessage@$v_oracle_sid z
        where msgdateprocessed<trunc(sysdate,'MON');
        spool off
EOF
)

v_period=`sqlplus -L -s $DBAREPOPASS@$v_spoke << EOF
        set feedback off heading off pages 0
        select distinct replace(to_char(add_months( sysdate,-1 ), 'MON-YYYY'),' ','') from dual;
EOF`

v_msg_dead_queue=`sqlplus -L -s $DBAREPOPASS@$v_spoke << EOF
        set feedback off heading off pages 0
        select sum(rfsdeadcount) Current_Dead_DB_Queue from $v_schema_name.receivedfilestore@$v_oracle_sid where rfsactive='Y';
EOF`

v_dead_msg_db_queue=`sqlplus -L -s $DBAREPOPASS@$v_spoke << EOF
        set feedback off heading off pages 0
        select count(*) Current_Dead_DB_Queue from $v_schema_name.zlpreceivedmail@$v_oracle_sid where rmstatus = 5000;
EOF`

        echo $run_ time $v_oracle_sid $v_schema_size $v_schema_name $v_msg_count $v_msg_size $v_prev_month_count $v_prev_month_size $v_msg_dead_queue $v_dead_msg_db_queue

        (sqlplus -s -L $DBAREPOPASS@$v_spoke << EOF
        spool $DBA_LOG/ax_billing_report.log
        insert into dbarepo.axel_validation_report
        (oracle_sid,schema,schema_size,msg_count,msg_size,month_msg_size,month_msg_count,worm_tape_count,report_date,month,msg_dead_queue,dead_msg_db_queue)
        values('$v_oracle_sid','$v_schema_name','$v_schema_size','$v_msg_count','$v_msg_size','$v_prev_month_size','$v_prev_month_count',0,sysdate,'$v_period',$v_msg_dead_queue,$v_dead_msg_db_queue);
        commit;
        spool off
EOF
)
   fi
   done
}

# Update AV401WM schema size with a constant growth value of 49.905GB

fn_wm_schema_size ()
{
(sqlplus -L -s $DBAREPOPASS@$v_spoke << EOF
        update dbarepo.ax_validation_report
        set schema_size=(select  round(sum(schema_size+49.705),2) from dbarepo.ax_validation_report where oracle_sid='prod01'
        and month=(select distinct replace(to_char(add_months( sysdate,-2 ), 'MON-YYYY'),' ','') from dual) )
        where oracle_sid='prod01' and month=(select distinct replace(to_char(add_months( sysdate,-1 ), 'MON-YYYY'),' ','') from dual);
EOF
)
fn_worm_tape
}

# Updates updates dbarepo.ax_validation_report with the latest month's worm tape count

fn_worm_tape ()
{
(sqlplus -L -s $DBAREPOPASS@$v_spoke << EOF
   set serveroutput on
   set feedback off
   set heading off
        select oracle_sid from dbarepo.databases@oemrep where oracle_sid in ('ib','wm','am');
EOF
)|while read v_w_oracle_sid
  do
        if [[ $v_w_oracle_sid != '' ]];then
        case $v_w_oracle_sid in
           am)
           v__db=am
           ;;
           av401ib)
           v__db=db02
           ;;
           av401wm)
           v__db=db01
           ;;
           esac
(sqlplus -L -s $DBAREPOPASS@$v_spoke << EOF
          set feedback off
          set heading off
          update dbarepo.axel_validation_report
          set worm_tape_count=(select count(*) from worm.tape_master@$v_worm_db where billable='y' and media_fill_date is not null)
          where oracle_sid='$v_w_oracle_sid'
          and month=(select distinct replace(to_char(add_months( sysdate,-1 ), 'MON-YYYY'),' ','') from dual);
Commit;
EOF
)&
   fi
   done
}
fn_worm_tape

fn_update_validation_table

(sqlplus -s -L $DBAREPOPASS@$v_spoke << EOF
set lines 255
spool $DBA_LOG/ax_billing_report.log
select * from dbarepo.ax_validation_report where report_date>sysdate-180 order by oracle_sid,report_date;
spool off
EOF
)

mail -s "AX_VALIDATION_REPORT $run_time" oraclesupport@gmail.com < $DBA_LOG/ax_billing_report.log
