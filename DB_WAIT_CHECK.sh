#!/bin/bash
#  SCRIPT WILL BE TRIGGER AFTER 60 SECONDS
source ~/.bashrc
. /home/oracle/nethome/dba/config/config.env
export DB_WAIT1=/home/<Location>/logs/dbwait1.sql
export DB_WAIT2=/home/<Location>/logs/dbwait2.sql
#export DB_WAIT_LIST='test01'
cd /home/<Location>/logs/

#-- Loop through databases and check if wait time is longer that 600 seconds (10 minutes)
for i in $PROD_DB_LIST; do

 function wait_time_test(){
    $ORACLE_HOME/bin/sqlplus -s $ZABBIXPASS@$i <<EOF_1
        set head off pages 0
        set feedback off
        select seconds_in_wait from gv\$session
        WHERE  username is not null
        and status='ACTIVE'
        and event not like '%PX%'
        and event not like '%SQL%'
        and event not like '%Stream%'
        and event not like '%broadcast%'
        and event not like '%DIAG%'
        and event not like '%RMAN backup%'
        and event not like '%latch%';
    exit
EOF_1
}
WAIT_TIME=`wait_time_test`
done
#-- Chech if variable is null
if [ -z $WAIT_TIME ]; then

echo $WAIT_TIME
echo "No Wait "
    exit 1

else
echo "Wait wait wait there is a wait"



if [ $WAIT_TIME -gt 600 ]; then

  for i in $PROD_DB_LIST; do
  export ORACLE_HOME
  function user_name(){
     $ORACLE_HOME/bin/sqlplus -s $ZABBIXPASS@$i <<EOF
         set head off pages 0
         select username  from gv\$session
         WHERE  username is not null
         and status='ACTIVE'
         and event not like '%PX%'
         and event not like '%SQL%'
         and event not like '%Stream%'
         and event not like '%broadcast%'
         and event not like '%DIAG%'
         and event not like '%RMAN backup%'
         and event not like '%latch%';
     exit;
EOF
}
  USER_NAME=`user_name`
  echo $USER_NAME

  function sid(){
     $ORACLE_HOME/bin/sqlplus -s $ZABBIXPASS@$i <<EOF
        set head off pages 0
        select sid from gv\$session
        WHERE  username is not null
        and status='ACTIVE'
        and event not like '%PX%'
        and event not like '%SQL%'
        and event not like '%Stream%'
        and event not like '%broadcast%'
        and event not like '%DIAG%'
        and event not like '%RMAN backup%'
        and event not like '%latch%';
    exit;
EOF
}
  SID=`sid`

  function object_name(){
    $ORACLE_HOME/bin/sqlplus -s $ZABBIXPASS@$i <<EOF
        set head off pages 0
        select do.object_name from v\$session s, dba_objects do where sid=${SID} and s.ROW_WAIT_OBJ# = do.OBJECT_ID;
    exit
EOF
}
  OBJECT_NAME=`object_name`

function rowid(){
    $ORACLE_HOME/bin/sqlplus -s $ZABBIXPASS@$i <<EOF
        set head off pages 0
        select dbms_rowid.rowid_create ( 1, ROW_WAIT_OBJ#,ROW_WAIT_FILE#,ROW_WAIT_BLOCK#,ROW_WAIT_ROW#) from v\$session s, dba_objects do where sid=${SID} and s.ROW_WAIT_OBJ#=do.OBJECT_ID;
    exit;
EOF
}
  ROW_ID=`rowid`

   if [ $ROW_ID = "no rows selected" ]; then
   $ROW_ID=''
   fi

  function sql_id(){
    $ORACLE_HOME/bin/sqlplus -s $ZABBIXPASS@$i <<EOF
        set head off pages 0
        select sql_id from gv\$session
        WHERE  username is not null
        and status='ACTIVE'
        and event not like '%PX%'
        and event not like '%SQL%'
        and event not like '%Stream%'
        and event not like '%broadcast%'
        and event not like '%DIAG%'
        and event not like '%RMAN backup%'
        and event not like '%latch%';
    exit;
EOF
}
  SQL_ID=`sql_id`

  function sql_id2(){
    $ORACLE_HOME/bin/sqlplus -s $ZABBIXPASS@$i <<EOF
        set head off pages 0
        select b.prev_sql_id
        FROM GV\$session a LEFT OUTER JOIN GV\$session b ON b.sid=a.blocking_session
        AND b.inst_id = a.blocking_instance
        WHERE  a.username is not null
        and a.status='ACTIVE'
        and a.event not like '%PX%'
        and a.event not like '%SQL%'
        and a.event not like '%Stream%'
        and a.event not like '%broadcast%'
        and a.event not like '%DIAG%'
        and a.event not like '%RMAN backup%';
    exit;
EOF
}
  SQL_ID2=`sql_id2`

  function wait_time(){
    $ORACLE_HOME/bin/sqlplus -s $ZABBIXPASS@$i <<EOF_1
        set head off pages 0
        select seconds_in_wait from gv\$session
        WHERE  username is not null
        and status='ACTIVE'
        and event not like '%PX%'
        and event not like '%SQL%'
        and event not like '%Stream%'
        and event not like '%broadcast%'
        and event not like '%DIAG%'
        and event not like '%RMAN backup%'
        and event not like '%latch%';
    exit
EOF_1
}
  WAIT_TIME=`wait_time`

    if [ $WAIT_TIME -gt 60 ]; then
     echo "--- A WAIT EVENT HAVE BEEN DETECTED ---"         >  $DB_WAIT2
     echo "Date____:`date`"                                 >> $DB_WAIT2
     echo "Host____: $node"                                 >> $DB_WAIT2
     echo "Database: $i"                                    >> $DB_WAIT2
     echo "IP______: $IP "                                  >> $DB_WAIT2
     echo "Time spent waiting $WAIT_TIME Seconds"           >> $DB_WAIT2
     echo "Please notify the appropiate personal"           >> $DB_WAIT2
     $ORACLE_HOME/bin/sqlplus -s $ZABBIXPASS@$i << EOF1 >>     $DB_WAIT2
        SET LINES 150
        col username for a30
        col machine  for a30
        col sid      for 99999
        col blocking_status for a300
        select s1.username || '@' || s1.machine || ' ( SID=' || s1.sid ||' serial#='|| s1.serial# || ' ) is blocking  ' || s2.username || '@' || s2.machine || ' ( SID=' || s2.sid ||' serial#='|| s2.serial# || ' ) ' AS blocking_status
        from   v\$lock l1,  v\$session s1,  v\$lock l2,  v\$session s2
        where s1.sid=l1.sid
        and s2.sid  =l2.sid
        and l1.BLOCK=1
        and l2.request > 0
        and l1.id1 = l2.id1
        and l2.id2 = l2.id2 ;
        set lines 150
        --
        TTITLE LEFT  'QUERY IN QUESTION'
        select * from ${USER_NAME}.${OBJECT_NAME} where rowid='${ROW_ID}';
        --
        TTITLE LEFT  ''
        select DISTINCT sql_text as "First blocking sql" from v\$sql where sql_id='${SQL_ID}';
        --
        TTITLE LEFT  ''
        select DISTINCT sql_text as "Second blocked sql" from v\$sql where sql_id='${SQL_ID2}';
        --
        TTITLE LEFT '--KILL THE OFFENDING SQL--'
        select 'alter system kill session '||''''||sid||','||serial#||''''||' immediate;' as "CAUTION"
        from v\$session where username='${USER_NAME}' and status='ACTIVE';
        --
        set lines    150
        col username for a18
        col event for a40
        col sid for  999
        col seconds_in_wait for 99999
        --
        TTITLE LEFT  'DETAILS'
        select a.seconds_in_wait as "Wait_in_Seconds", a.username, a.sid,a.serial#, a.event,a.sql_id, b.sid,b.prev_sql_id,b.serial#
        FROM GV\$session a  LEFT OUTER  JOIN  GV\$session b  ON  b.sid=a.blocking_session
        AND b.inst_id = a.blocking_instance
        WHERE  a.username is not null
        and a.status='ACTIVE'
        and a.event not like '%PX%'
        and a.event not like '%SQL%'
        and a.event not like '%Stream%'
        and a.event not like '%broadcast%'
        and a.event not like '%DIAG%'
        and a.event not like '%RMAN backup%'
        and a.seconds_in_wait > 20;
        exit
EOF1
       mailx -s "DB_Wait Alert has been detected $i $node " $EMAIL_LIST < $DB_WAIT2
       fi
  done
 fi
fi
rm -rf $FUN
rm -rf $DB_WAIT2
rm -rf $DB_WAIT1
exit 0
