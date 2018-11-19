#!/bin/sh

source ~/.bash_profile
. /home/<Location>/config/config.env

mv $DBA_DIR/scripts/crontab.bak $DBA_LOG/crontab.prev
crontab -l > $DBA_DIR/scripts/crontab.bak

diff $DBA_LOG/crontab.prev $DBA_DIR/scripts/crontab.bak > $DBA_LOG/crontab.diff
if [ $? = 1 ]; then
 mailx -s "Crontab on $HOSTNAME has been updated" $EMAIL_LIST < $DBA_LOG/crontab.diff
fi

