#!/bin/ksh
#rman_level1_backup.sh

. $HOME/.bash_profile

LOG_DIR=/home/oracle/log

find $LOG_DIR/rman_level1*.log -mtime +30 -exec rm -f {} \;

export NLS_DATE_FORMAT='DD-MON-YY HH24:MI:SS'
TIMESTAMP=`date '+%C%y%m%d'`
HOST=`hostname`

RET=`$ORACLE_HOME/bin/sqlplus -s "/ as sysdba"<<!
set heading off
select count(1)
from v\\$session
where substr(program,1,instr(program,'(')-1) like '%rman@||${ORACLE_SID}%';
!`

if [ $RET -gt 1 ]
then
echo RMAN backup already running...
exit 0
else
rman <<! | tee $LOG_DIR/rman_level1_backup_${TIMESTAMP}.log

connect target /;

run
{
        backup
                as compressed backupset
                format '/opt/oracle/backup/rman_backups/${ORACLE_SID}_${TIMESTAMP}_%U'
                incremental level 1
                database plus archivelog
                delete all input;
                sql 'alter system archive log current';
}

#Enable these commands at a later date when backups are centralized
#allocate channel for maintenance device type disk;
#crosscheck backup;
#delete force noprompt obsolete;
!

#Check exit status of above routine. Exit status of 0 is good.
RES=$?

if [[ $RES != "0" ]]; then
  echo "Backup failed" >> $LOG_DIR/rman_level1_backup_${TIMESTAMP}.log
  exit $RES
fi

if [ `cat $LOG_DIR/rman_level1_backup_${TIMESTAMP}.log | egrep 'ORA-|RMAN-|failed' | wc -l` -gt 0 ]; then
  mailx -s "EMRECP Level 1 Backup Failed" keo.vongkaseum@enkitec.com jadams@enkitec.com < $LOG_DIR/rman_level1_backup_${TIMESTAMP}.log
else
  mailx -s "EMRECP Level 1 Backup Succeeded" keo.vongkaseum@enkitec.com jadams@enkitec.com < $LOG_DIR/rman_level1_backup_${TIMESTAMP}.log
fi

RES=`$ORACLE_HOME/bin/sqlplus -s "/ as sysdba"<<!
set termout off
set feedback off
set echo off
set heading off
set verify off
select count(1)
from v\\$database_block_corruption;
exit;
!`

if [ $RES != '0' ]; then
  echo "Backup Corruption Detected in ${ORACLE_SID} backup on ${HOST}" | mail -s "Error" keo.vongkaseum@enkitec.com jadams@enkitec.com
fi

fi
