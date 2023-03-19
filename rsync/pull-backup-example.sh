#!/usr/bin/bash

DIR="/home/mm/Backup"
USER="rsync-mc"
SECRET="/home/mm/.rsync-secret"
ENDPOINT="192.168.100.231"
PORT="12000"
SHARE="files"


NEW=$(date '+%Y%m%d%H%M%S')
NEWDIR="${DIR}/${NEW}"
LATEST="${DIR}/latest"

mkdir -p $LATEST
rsync -artLk --password-file=$SECRET rsync://$USER@$ENDPOINT:$PORT/$SHARE $LATEST

mkdir -p $NEWDIR
cp -r $LATEST $NEWDIR

COUNT=$(find $DIR -maxdepth 1 -type d | grep -P "[0-9]{14}")
TOTAL=$(echo $COUNT | wc -w)

for EDIR in $COUNT; do
if [[ $TOTAL -lt 8 ]]
then
 break
fi
 rm -r $EDIR
 ((TOTAL--))
done
