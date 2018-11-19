#!/bin/bash
source ~/.bash_profile
cd /database_backups/<Location>/rman_catalog
export ORACLE_SID=oemrep_1
export ORACLE_BASE=/u01/<Location>
export ORACLE_HOME=/u01/<Location>
export HOUR=$(date +%Y%m%d%H)

expdp `cat /home/<Location>/rman`  DIRECTORY=EXP_DIR DUMPFILE=exp_catalog-$HOUR.dmp LOGFILE=exp_catalog-$HOUR.log SCHEMAS=RMAN

grep ORA-* exp_catalog-$HOUR.log && echo "******Catalog backup failed*****" | mailx -s "!!!Check catalog backup!!!" jon@gmail.com

###compress
gzip exp_catalog-$HOUR.dmp

###remove old files
find /database_backups/<Location>/rman_catalog . -name "*.gz" -type f -mtime +30 -exec rm -f {} \;
find /database_backups/<Location>/rman_catalog . -name "*.log" -type f -mtime +30 -exec rm -f {} \;

exit 0
