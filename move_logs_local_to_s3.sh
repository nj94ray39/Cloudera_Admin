#!/bin/bash
set -x
set -e

date_today=`date +'%d-%m-%Y'`

mkdir -p /app/var/log/cronlogs/$date_today

cd /app/var/log/cronlogs/$date_today

exec 1>log.out 2>&1

# run common environment file


source /arturo/config/s3_config.env
source /arturo/config/cdh_config.env

host=`hostname -a`

echo "max old days logs"
days=78
team=dexter

LogDIR=/app/var/log

date_today=`date +'%d-%m-%Y'`

used=`df | grep app |awk '{print $5}' | tr -cd "[0-9A-Za-z]\n"`

echo "loging the script run stats into splunk"

touch stats

echo $date_today >> /app/var/log/cronlogs/stats
echo $used >> /app/var/log/cronlogs/stats

touch movefiles

ls $LogDIR/$team/$env/ | head -1

find $LogDIR/$team/$env/* -maxdepth 1 -type d -mtime +$days | cut -d'/' -f 7 | uniq > movefiles

less /app/var/log/cronlogs/$date_today/movefiles
echo $movefiles >> /app/var/log/cronlogs/$date_today/stats

while read date; do
      echo "$date"
      echo "logs to be moved"
      ls -R $LogDIR/$team/$env/$date >> /app/var/log/cronlogs/$date_today/stats
      echo "copy files from local to s3"
      aws s3 cp $LogDIR/$team/$env/$date $s3_S3BucketAndPrefix/cdh/logs/$team/$host/$date/ --recursive
      echo "do reconciliation"
      if [ $(diff <(ls -R $LogDIR/$team/$env/$date | grep "raw-to-structure.log"| wc -l) <(aws s3 ls $s3_S3BucketAndPrefix/cdh/logs/$team/$host/$date/ --recursive | grep "raw-to-structure.log"|wc -l) | wc -l) -ne 0 ]; then
        numFiles=`ls -R $LogDIR/$team/$env/$date | grep "raw-to-structure.log"| wc -l`
        echo "Reconciliation of Number of files moved $numFiles and files in the s3"
        echo "Exiting..."
        exit 0
      fi
      echo "removing logs from local"
      rm -rf "/app/var/log/$team/$env/$date"
done <movefiles
echo "removing the list of logs"

rm -f /app/var/log/cronlogs/$date_today/movefiles
