#Script to delete old log files 

#!/bin/bash

#This script clears the service logs which are older than two months(60days) and move them to HDFS backup dir

#NOTE

#Create "/log-backup" directory on hdfs if does not exist or change destination location in below code

#create backup dir in tmp location

mkdir /tmp/logbackup_$(date +%Y%m%d)

#Services and their log locations

#You can add more log locations below

HDFS="/var/opt/teradata/log/hadoop/hdfs"	#do not put "/" at end of log directoryYARN="/var/opt/teradata/log/hadoop/yarn"

MAPREDUCE="/var/opt/teradata/log/hadoop-mapreduce/mapred"

AMBARI_SERVER="/var/opt/teradata/log/ambari-server"

AMBARI_AGENT="/var/opt/teradata/log/ambari-agent"

AMBARI_METRICS_COLLECTOR="/var/opt/teradata/log/ambari-metrics-collector"

AMBARI_METRICS_MONITOR="/var/opt/teradata/log/ambari-metrics-monitor"

FALCON="/var/opt/teradata/log/falcon"

HBASE="/var/opt/teradata/log/hbase"

HIVE="/var/opt/teradata/log/hive"

OOZIE="/var/opt/teradata/log/oozie"

WEBHCAT="/var/opt/teradata/log/webhcat"

ZOOKEEPER="/var/opt/teradata/log/zookeeper"

for i in $HDFS $YARN $MAPREDUCE $AMBARI_SERVER $AMBARI_AGENT $AMBARI_METRICS_COLLECTOR $AMBARI_METRICS_MONITOR $FALCON $HBASE $HIVE $OOZIE $WEBHCAT $ZOOKEEPER

do

 ServiceDirName=`echo $i | rev | cut -d '/' -f1 | rev | tr -d '.'`

 mkdir /tmp/logbackup_$(date +%Y%m%d)/$ServiceDirName

 find $i -type f -mtime +60 -execdir mv -- '{}' /tmp/logbackup_$(date +%Y%m%d)/$ServiceDirName \;

done

#Create tar

cd /tmp

tar -czvf /tmp/Hadoop_logs.bkp.$(date +%Y%m%d).tar.gz logbackup_$(date +%Y%m%d)

#Backup tar file on HDFS

echo "Moving files to HDFS"

hadoop fs -put /tmp/Hadoop_logs.bkp.$(date +%Y%m%d).tar.gz /log-backup/

[22/05, 2:19 PM] +91 90211 27855: Modify the locations and no.of days

Sent from Yahoo Mail for iPhone
