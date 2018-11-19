#!/bin/bash
#
# TO TEST THIS SCRIPT COMMENT OUT THE LINE PRD=`expr $PRD - $SYNC_NUM `
#
. ~/.bash_profile
. /home/<location>config/config.env

export SYNC_NUM=6
export mail_file=$DBA_LOG/dg_sync_mailfile.txt
rm -f $mail_file
num_errors=0

echo "===================Attention======================"           >> $mail_file

for ORACLE_SID in $AV5_DB_LIST; do

v_seq_diff=$(sqlplus -L -s $ZABBIXPASS@$ORACLE_SID << EOF
set feedback off heading off pages 0
select (select max(sequence#) from v\$archived_log) --
 (select max(sequence#) from v\$archived_log where applied='YES')
from dual;
EOF
)

if [[ $v_seq_diff -ge $SYNC_NUM ]]; then
 echo " STANDBY DATABASE $ORACLE_SID IS OUT OF SYNC WITH PRODUCTION">> $mail_file
 echo "They are more that $SYNC_NUM archivelogs out of sync "       >> $mail_file
 echo ""                                                            >> $mail_file
 num_errors=$((num_errors+1))
fi

done

echo "Please look into this issue. "                                >> $mail_file
echo "HOST____: $node"                                              >> $mail_file
echo "IP______: $IP"                                                >> $mail_file
echo "Date____: $DAY"                                               >> $mail_file
echo "End of email                                                " >> $mail_file
echo ""                                                             >> $mail_file

if [[ $num_errors -gt 0 ]]; then
 mailx -s "Attention!! Standby instance(s) out of sync with Production " $EMAIL_LIST < $mail_file
fi

exit 0
