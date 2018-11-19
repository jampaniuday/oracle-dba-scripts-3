#!/bin/bash

###########################################################################################
###### ALERT LOG CHECKING VIA ADRCI #######################################################
######  Author - Jon Delmas       #########################################################
###### Upd: 1/30/2018 (THN) - filtered out non-erroring OH ################################
###### Upd: 3/05/2018 (JON) - ignores some errors          ################################
###########################################################################################
source ~/.bash_profile
. /home/oracle/nethome/dba/config/config.env
export ORACLE_HOME
export LOG_FILE=$DBA_LOG/alert_log_check_daily.text
rm -rf $LOG_FILE

adrci_homes=( $(adrci exec="show homes" | egrep -e rdbms ))
echo '###########################################################################################################' > $LOG_FILE
echo '###########################################ALERT LOG OUTPUT FOR LAST 15 MINUTES ###########################' >> $LOG_FILE
echo '###########################################################################################################' >> $LOG_FILE
echo "Server : ${host}" >> $LOG_FILE

num_errors=0
for adrci_home in ${adrci_homes[@]}; do
#
##### to add items to be ignored use grep -v -e "pattern" -e "pattern"
#
 OUTPUT="$(adrci exec="set home ${adrci_home}; show alert -p \\\"message_text like '%ORA-%' and originating_timestamp > systimestamp-1/90\\\"" -term)"
 errors=`echo $OUTPUT | grep -v -i -e "ORA-SCAN"  \
                                   -e "ORA-00000" \
                                   -e "ORA-03135" \
                                   -e "ORA-00000" \
                      | grep -c  "ORA-" `

 if [ "$errors" -gt 0 ]; then
  echo "${OUTPUT}" >> $LOG_FILE
  num_errors=$((num_errors+1))
 fi

done

if [ "$num_errors" -gt 0 ]; then
 mailx -s "ORA- error in alert Log server:$node Databases with error: $num_errors" $EMAIL_LIST <$LOG_FILE
fi

exit 0
