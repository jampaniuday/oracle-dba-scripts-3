#!/bin/bash
#
#Created by jon Delmas  1/9/2018
#
DEBUG=0

#######################Environment_variables#####################################
source ~/.bash_profile
. /home/oracle/nethome/dba/config/config.env
export mail_file=$DBA_LOG/fra_mail_file.log

if [ $DEBUG -eq 1 ]; then export EMAIL_LIST='thanh.nguyen@ldiscovery.com'; fi

cd $DBA_LOG

########################LOOP_throught_databases###################################

if [ `hostname -a|sed 's/-.*//'` == 'ATXP' ]; then db_list=$PRIMARY_DG_DB_LIST
 else db_list=$STANDBY_DG_DB_LIST;
fi

for i in $db_list; do
if [ $DEBUG -eq 1 ]; then echo $i;fi

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
          echo "Threshold is 95 for critical" >> $mail_file
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
          echo "Threshold is 85% for Proactive" >> $mail_file
          echo "Hostname $node" >> $mail_file
          echo "The FRA is current usage >$Q% ---- Please take Action!! ---- " >> $mail_file
          echo "End of email"  >> $mail_file
          echo ""  >> $mail_file
     cat -v $mail_file | mailx -s "Attention!! $i is low space in FRA! " $EMAIL_LIST
fi

rm -f $mail_file

done

exit 0
