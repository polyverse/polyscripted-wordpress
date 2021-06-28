#!/bin/bash
set -e
port=$1
host='localhost'


### LOCK CRON JOB ###
scriptname=$(basename $0)
lock="/var/run/${scriptname}"
exec 201>lock
flock -n 201 || exit 1
pid=$$
echo $pid 1>&201
### LOCK CRON JOB ###

echo "Modification to wordpress directory caught at: $(date +"%T")"
sleep 30m
echo "Sending merge request at: $(date +"%T")"
echo "4 " | nc $host $port
