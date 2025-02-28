#!/bin/bash
# ONLY WORKS WITH DIRECTORYS CONTAINING FILES!! NO DIR
if [ $# -z ];then
    DIRECTORY='.'
else
    DIRECTORY=$1
fi

#DIR ALSO LISTET; SDCARD SHUT NOT HAVE A SUBDIR
FIRST=$(/usr/bin/ls -1t $DIRECTORY | head -n1)
LAST=$(/usr/bin/ls -1rt $DIRECTORY | head -n1)


# Having files like img_01.01.1970.png
# Only filtering for DAY
START=$(stat -c %x $FIRST | awk '{print $1}')
END=$(stat -c %x $END | awk '{print $1}')

tar -cf ./backup_$START-$END.tar.pigz --use-compress-program=pigz $DIRECTORY