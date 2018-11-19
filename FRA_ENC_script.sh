#!/bin/bash
#
#Created   1/9/2018
#
DEBUG=0

#######################Environment_variables#####################################
source ~/.bash_profile
#. /home/<Location>/config/config.env
export NLS_DATE_FORMAT='dd-mon-rrrr hh24:mi:ss'
export DBA_LOG=/home/<Location>/logs
export mail_file=$DBA_LOG/fra_mail_file.log
export FRA_CRITICAL=60
export FRA_PROACTIVE=40
export db_list='pord01'
export ORACLE_SID=prod01_1
export ORACLE_HOME=/u01/<Location>/11.2.0.4/dbhome
export DBA_DIR=/home/<Location>;
export SYSPASS=`cat $DBA_DIR/security/sys`
export EMAIL_LIST=jon@gmail.com
#if [ $DEBUG -eq 1 ]; then export EMAIL_LIST='jon@gmail.com'; fi
if [ $DEBUG -eq 1 ]; then export EMAIL_LIST='jon@gmail.com'; fi
cd $DBA_LOG
########################LOOP_throught_databases###################################

#if [ `hostname -a|sed 's/-.*//'` == 'ATXP' ]; then db_list=$PRIMARY_DG_DB_LIST
# else db_list=$STANDBY_DG_DB_LIST;
#fi

for i in $db_list; do
if [ $DEBUG -eq 1 ]; then echo $i;fi

#DELETES EVERYTHING EXCEPT THE LAST MINUTES SO THAT DATAGUARD HAS TIME TO RECEIVE LOGS
$ORACLE_HOME/bin/./rman target / <<EOF
set echo on
run {
backup archivelog all;
delete noprompt archivelog all completed before 'sysdate - 1/24/60';
}
exit;
EOF


function fun(){
sqlplus -s $SYSPASS@$i as sysdba <<EOF
SET head off PAGES 0
SET LINESIZE 10
SET FEEDBACK OFF
SET ECHO OFF
select round((SPACE_USED/SPACE_LIMIT)*100) from V\$RECOVERY_FILE_DEST;
exit;
EOF
}
Q=`fun`

if
   [ $Q -ge $FRA_CRITICAL ]; then
          echo "==============Attention======================" >> $mail_file
          echo "Database $i FRA has low diskspace" >> $mail_file
          echo "Severity: Critical" >> $mail_file
          echo "Threshold is $FRA_CRITICAL for critical" >> $mail_file
          echo "Hostname $node" >> $mail_file
          echo "The FRA is current usage >>$Q% ---- Please take Action!! ---- " >> $mail_file
          echo "End of email"  >> $mail_file
          echo ""  >> $mail_file
     cat -v $mail_file | mailx -s "Attention!! $i is low space in FRA! " $EMAIL_LIST
 elif
   [ $Q  -ge $FRA_PROACTIVE ]; then
          echo "==============Attention======================" >> $mail_file
          echo "Database $i FRA has low diskspace" >> $mail_file
          echo "Severity: Proactive" >> $mail_file
          echo "Threshold is $FRA_PROACTIVE for Proactive" >> $mail_file
          echo "Hostname $node" >> $mail_file
          echo "The FRA is current usage >$Q% ---- Please take Action!! ---- " >> $mail_file
          echo "End of email"  >> $mail_file
          echo ""  >> $mail_file
     cat -v $mail_file | mailx -s "Attention!! $i is low space in FRA! " $EMAIL_LIST
fi

rm -f $mail_file

done

exit 0
