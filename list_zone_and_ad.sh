#!/bin/bash
set -x



source /arturo/config/s3_config.env
source /arturo/config/cdh_config.env

cd /root/
>acls_read
>acls_write
>acls_system
>dir.txt


hdfs dfs -ls /data/*/*/ |awk '{print $8}'|ex -s +'v/\S/d' +%p +q! /dev/stdin > dir.txt
hdfs dfs -ls /collab/*/ |awk '{print $8}'|ex -s +'v/\S/d' +%p +q! /dev/stdin >> dir.txt
while read dir; do
        set -x
        echo "$dir"
                s3DataSize=`aws s3 ls --summarize --human-readable --recursive $s3_S3BucketAndPrefix/cdh$dir| grep "Total Size" | awk -F"[::]" '{print $2}'| awk '{$1=$1;print}'`
        zone=`echo $dir | awk 'BEGIN {FS="/"} {print $2}'`
        if [ "$zone" = "data" ]
        then
                echo "Data Directory"
                dataset="`echo $dir | awk 'BEGIN {FS="/"} {print $4}'`_`echo $dir | awk 'BEGIN {FS="/"} {print $5}'`"
                zone="`echo $zone`_`echo $dir | awk 'BEGIN {FS="/"} {print $3}'`"
                                list=`echo $dir | cut -f1-4 -d"/"`
                                search=`echo $dir | awk 'BEGIN {FS="/"} {print $5}'`
        else
                echo "Collab Directory"
                dataset="`echo $dir | awk 'BEGIN {FS="/"} {print $3}'`_`echo $dir | awk 'BEGIN {FS="/"} {print $4}'`"
                                list=`echo $dir | cut -f1-3 -d"/"`
                                search=`echo $dir | awk 'BEGIN {FS="/"} {print $4}'`
        fi
        hdfs dfs -getfacl $dir | grep "read:r-x" | awk -F"[::]" '{print $2}' | grep "acg-cog-for-cdh-" > acls_read
                hdfsDataSize=`hdfs dfs -du $list | grep "/$search$" |awk '{print $2}'|awk '{ foo = $1 / 1024 / 1024 / 1024; print foo "" }'`
                actualDataSize=`hdfs dfs -du $list | grep "/$search$" |awk '{print $1}'|awk '{ foo = $1 / 1024 / 1024 / 1024; print foo "" }'`
        if [ -s acls_read ]
        then
                echo "File not empty"
        else
                echo "File empty"
                echo "non" > acls_read
        fi
        while read acl_read; do
                set -x
                echo "$acl_read"
                hdfs dfs -getfacl $dir | grep "write:rwx" | awk -F"[::]" '{print $2}' | grep "acg-cog-for-cdh-" > acls_write
                if [ -s acls_write ]
                then
                        echo "File not empty"
                else
                        echo "File empty"
                        echo "non" > acls_write
                fi
                while read acl_write; do
                        set -x
                        echo "$acl_write"
                        hdfs dfs -getfacl $dir | grep "system:rwx" | awk -F"[::]" '{print $2}' | grep "acg-cog-for-cdh-" > acls_system
                        if [ -s acls_system ]
                        then
                                echo "File not empty"
                        else
                                echo "File empty"
                                echo "non" > acls_system
                        fi
                        while read acl_system; do
                                set -x
                                echo "$acl_system"
                                echo "$dataset,$zone,$dir,$hdfsDataSize,$actualDataSize,$s3DataSize,$acl_read,$acl_write,$acl_system">>dir_acl_map.csv
                        done <acls_system
                done <acls_write
        done <acls_read
done <dir.txt

echo "done"
