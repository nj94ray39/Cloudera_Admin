#!/bin/bash
# David M Walker, Data Management & Warehousing & Worldpay
# hql command line for use with a Kerborised cluster

#rename the script to hql

DATABASE="DEFAULT"
QUERY_FILE=""
HOST="localhost"
PORT="10001"
QUEUE="DEFAULT"
REALM="_HOST@REALM"

while getopts :d:h:p:r:q:f: PARAM
do
   case "${PARAM}" in 
      d) DATABASE="${OPTARG}"
         ;; 
      f) QUERY_FILE="${OPTARG}"
         ;;
      h) HOST="${OPTARG}"
         ;;
      p) PORT="${OPTARG}"
         ;;
      q) QUEUE="${OPTARG}"
         ;;
      r) REALM="${OPTARG}"
         ;;
      ?) echo "Usage: hql [-d DATABASE] [-h HOST] [-p PORT] [-q QUEUE] [-r REALM] [-f QUERY_FILE]" 
         exit 1
         ;;
   esac
done
shift $(($OPTIND - 1))

if [ -z "${QUERY_FILE}" ]
then
   beeline -u "jdbc:hive2://${HOST}:${PORT}/${DATABASE};transportMode=http;httpPath=cliservice;principal=hive/${REALM}" --hiveconf tez.queue.name=${QUEUE}
   exit $?
else
   if [ -r "${QUERY_FILE}" ]
   then
      beeline -u "jdbc:hive2://${HOST}:${PORT}/${DATABASE};transportMode=http;httpPath=cliservice;principal=hive/${REALM}" --hiveconf tez.queue.name=${QUEUE} -f ${QUERY_FILE}
      exit $?
   else
      echo "File ${QUERY_FILE} is not readable"
      exit 1
   fi
fi

exit 0
