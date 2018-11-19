#!/bin/bash

export RSYNC=/usr/bin/rsync


$RSYNC --update /home/<Location>/scripts/*sh oracle@AVAR-AV5-ORA01:/home/<Location>/scripts
$RSYNC --update /home/<Location>/scripts/*sh oracle@AVAR-AV5-ORA02:/home/<Location>/scripts
$RSYNC --update /home/<Location>/scripts/*sh oracle@ATXP-AV5-ORA02:/home/<Location>/scripts


exit
