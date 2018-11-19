#!/bin/bash

. /home/<Location>/.bash_profile
. /home/<Location>/config/config.env


check_DB_Connect () {
 status=`sqlplus -L -s $DBAREPOPASS@$1 <<EOF
EOF`
 echo $?;
}

check_sysdba_Connect () {
 status=`sqlplus -L -s $SYSPASS@$1 as sysdba <<EOF
EOF`
 echo $?;
}

Insert_Last_Time () {
 status=`sqlplus -L -s $DBAREPOPASS@oemrep <<EOF
insert into dbarepo.standbyarchivelogstatus (oracle_sid, currenttime, status, lastrecoverytime)
values ('$1', sysdate, 'Success', to_date('$2','YYYYMMDDHH24MISS'));
EOF`
}


for dbinstance in $CHK_SBY_DB_LIST; do

 [[ `check_sysdba_Connect ${dbinstance}dg` -ne 0 ]] && ( echo "ERROR: Instance ${dbinstance}dg is unavailable"; exit 1 )

lastrecoverytime=$(sqlplus -L -s $SYSPASS@${dbinstance}dg as sysdba << EOF
set heading off feedback off
select to_char(sysdate-1/24-to_number(substr(value,2,2))-to_number(substr(value,5,2))/24-to_number(substr(value,8,2))/24/60-to_number(substr(value,11,2))/24/60/60,'YYYYMMDDHH24MISS') lastrecoverytime from v\$dataguard_stats where name='apply lag';
EOF
)

Insert_Last_Time $dbinstance $lastrecoverytime
done

