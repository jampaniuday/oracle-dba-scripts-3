#!/bin/bash
#
# find trace, xml files and compresses moves to HNAS then retains desired days
#
# find audit files
#
. /<location>/config/config.env
export H=/database_backups/<location>/trace
export R=/u01/app/oracle/diag/rdbms
export G=/database_backups/<location>/grid_trace



for d in $TEST_LOG_DB_LIST
do
find $R/$d/ -type f \( -name '*.tr?'    -o -name '*.xml' \)    -mtime +1  -exec gzip -f9 {} \;
find $R/$d/ -type f \( -name '*.tr?.gz' -o -name '*.xml.gz' \) -exec mv -t $H/$d {} \;
find $H/$d/ -type f \( -name '*.tr?.gz' -o -name '*.xml.gz' \) -mtime +3 -exec rm {} \;
done

#---------------------------PRODUCTION DATA BASES---------------------------------#

for d in $PROD_LOG_DB_LIST
do
find $R/$d/ -type f \( -name '*.tr?'    -o -name '*.xml' \)    -mtime +7  -exec gzip -f9 {} \;
find $R/$d/ -type f \( -name '*.tr?.gz' -o -name '*.xml.gz' \) -exec mv -t $H/$d {} \;
find $H/$d/ -type f \( -name '*.tr?.gz' -o -name '*.xml.gz' \) -mtime +90 -exec rm {} \;
done

#---------------------------CATALOG LOGS  ---- -----------------------------------#
find /database_backups/<location> -type f \( -name '*.log' -o -name '*.dmp' \) -mtime +30 -exec rm {} \;

#---------------------------AUDIT LOGS  ------------------------------------------#
find /u01/<location>/av*   -name "*.aud"    -type f -mtime +7 | xargs gzip -f9
find /u01/<location>/av*   -name "*.aud.gz" -type f -mtime +90 -exec rm {} \;
find /u01/<location>/worm* -name "*.aud"    -type f -mtime +7 | xargs gzip -f9
find /u01/<location>/worm* -name "*.aud.gz" -type f -mtime +90 -exec rm {} \;
find /u01/<location>/oem*  -name "*.aud"    -type f -mtime +7 | xargs gzip -f9
find /u01/<location>/oem*  -name "*.aud.gz" -type f -mtime +90 -exec rm {} \;
find /u01/<location>/t*    -name "*.aud"    -type f -mtime +1 -exec rm {} \;


find $R/database -type f \( -name '*.tr?'    -o -name '*.xml' \)    -mtime +1  -exec gzip -f9 {} \;
find $R/database -type f \( -name '*.tr?.gz' -o -name '*.xml.gz' \) -exec mv -t $H/database {} \;
find $H/database -type f \( -name '*.tr?.gz' -o -name '*.xml.gz' \) -mtime +90  -exec rm {} \;


exit 0
