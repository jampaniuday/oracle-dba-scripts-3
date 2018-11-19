#!/bin/bash
DEBUG=0;

. $HOME/.bash_profile
. $HOME/<Location>/config.env
SCRIPT_DIR=$DBADIR/scripts

if [ $DEBUG -eq 1 ]; then export EMAIL_LIST='jon@gmail.com'; fi

#----------------------------------------------------------------------------------------
# Setup log/lock files

ts=`date +%Y%m%d`;
logfile=$DBA_LOG/check_longops/$ts.log;
lockfile=$DBA_LOG/check_longops.lock;
mailfile=$DBA_LOG/check_longops.msg;

if [ -e $lockfile ]; then
 echo `date` : `basename $0` already running >> $logfile;
 let "lockfileage=(`date +%s`)-(`perl -e '$a=(stat(shift))[9];print $a' $lockfile`)";
 if [ $lockfileage -gt 1800 ]; then
  [ $DEBUG -eq 1 ] && (echo `date` : Lock file for `basename $0` is $lockfileage seconds old >> $logfile);
  echo `date` : Lock file for `basename $0` is older than 30 minutes \($lockfileage seconds\) >> $mailfile;
  if [ $(($lockfileage % 300)) -le 60 ]; then
   send_mail;
  fi;
 fi
 exit;
else
 echo $$ > $lockfile;
 echo `date` : Starting `basename $0` >> $logfile;
fi

#----------------------------------------------------------------------------------------
# Check connection

checkDBConnect () {
 db=$1;
 status=`sqlplus -L -s $DBAREPOPASS@$db <<EOF
EOF`
 echo ${status}|grep 'ORA-' >> /dev/null;
 return $?;
}

#----------------------------------------------------------------------------------------
# Get list of databases

getAVList () {
 checkDBConnect "$repo";
 if [ $? -eq 1 ]; then
  [ $DEBUG -eq 1 ] && (echo `date` : Connected to Repository $repo >> $logfile);
  av_list=$(sqlplus -L -s $DBAREPOPASS@$repo << EOF
set heading off feedback off
SELECT oracle_sid FROM dbarepo.databases WHERE alert_status = 'ACTIVE';
EOF
  )
  av_list=`echo $av_list | awk '{gsub(/\r/,"");print}'`;
  [ $DEBUG -eq 1 ] && (echo `date` : $av_list >> $logfile);
 else
  echo `date` : Could not connect to Repository $repo >> $logfile;
  echo `date` : Could not connect to Repository $repo >> $mailfile;
 fi
}

#----------------------------------------------------------------------------------------
# Get list of long ops queries > 10 mins

checkLongOps () {
 db=$1;
 [ $DEBUG -eq 1 ] && (echo `date` : Connecting to $db >> $logfile);
 checkDBConnect "$db";
 if [ $? -eq 1 ]; then
  echo `date` : Connected to $db >> $logfile;
  longops_list=$(sqlplus -L -s $DBAREPOPASS@$db << EOF
set lines 130 feedback off
col username format a15
col sid format 9999
col serial# format 99999
col sofar format 9,999,999,999
col totalwork format 9,999,999,999
col elapsed for a11
col left for a11
col total for a11
col message for a100
select l.username, l.sid, l.sofar, l.totalwork,
       substr(numtodsinterval(time_remaining+elapsed_seconds,'second'),
              instr(numtodsinterval(time_remaining+elapsed_seconds,'second'),' ')-1, 1)||':'||
       substr(numtodsinterval(time_remaining+elapsed_seconds,'second'),
              instr(numtodsinterval(time_remaining+elapsed_seconds,'second'),' ')+1,
              8) total,
       substr(numtodsinterval(elapsed_seconds,'second'),
              instr(numtodsinterval(elapsed_seconds,'second'),' ')-1, 1)||':'||
       substr(numtodsinterval(elapsed_seconds,'second'),
              instr(numtodsinterval(elapsed_seconds,'second'),' ')+1,
              8) elapsed,
       substr(numtodsinterval(time_remaining,'second'),
              instr(numtodsinterval(time_remaining,'second'),' ')-1, 1)||':'||
       substr(numtodsinterval(time_remaining,'second'),
              instr(numtodsinterval(time_remaining,'second'),' ')+1,
              8) left,
       s.sql_id,
       message
from v\$session_longops l, v\$session s
where l.LAST_UPDATE_TIME>sysdate-30/(24*60)
and l.time_remaining!=0
and s.sid=l.sid
and s.serial#=l.serial#
and opname not like 'RMAN%' and opname not like 'Gather%Statistics'
and (time_remaining+elapsed_seconds)>600
and l.message not like '%WORM.FILE_DETAIL%'
order by username,time_remaining, start_time;
EOF
  )
  [ $DEBUG -eq 1 ] && (echo `date` : $db longops list = $longops_list >> $logfile);
  if [[ $longops_list != '' ]]; then
   echo `date` : Checking $db >> $mailfile;
   echo "$longops_list" >> $mailfile;
   echo -e "\n" >> $mailfile;
  fi
 else
  echo `date` : Could not connect to instance $db >> $logfile;
 fi
}

#----------------------------------------------------------------------------------------
# Send Mail

send_mail () {
 `mailx -s 'ALERT - Check Long-Running Full Scans' $EMAIL_LIST < $mailfile`;
}

#----------------------------------------------------------------------------------------
# MAIN

av_list='';
getAVList;

for av in $av_list; do
 if [ $DEBUG -eq 1 ]; then echo $av; fi
 checkLongOps "$av" &
done
wait;

if [ -s $mailfile ] && [ `date +%M` == '00' ]; then
 send_mail;
 rm $mailfile
fi

rm $lockfile;
