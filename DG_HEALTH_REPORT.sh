#!/bin/bash

. /home/<Locaiton>/config/config.env
cd /home/<Locaiton>/logs
export A1=/home/<Locaiton>/logs/A1.text
export USER=

function fun () {
for i in $DG_HEALTH_LIST; do
echo " Hostname:`hostname`" > $A1
echo "+++++++++++++++++++++++++++++++++++++++++++++++" >> $A1
echo "+++++++++++++++++++++++++++++++++++++++++++++++" >> $A1
echo "           STANDBY  $DG_HEALTH_LIST_STBY       " >> $A1
echo "+++++++++++++++++++++++++++++++++++++++++++++++" >> $A1
export ORACLE_SID=$DG_HEALTH_LIST
$ORACLE_HOME/bin/./dgmgrl <<EOF >> $A1
connect $USER@`for n in $DG_HEALTH_LIST_STBY; done`
show database `for n in $DG_HEALTH_LIST_STBY; done`;
exit;
exit;
EOF
done
}
mailx -s "Data Guard Report:$node `date` " $EMAIL_LIST < $A1

exit 0
