#!/bin/bash
 
# Weird little TCP server
# Tells time and uptime; can list and dump files in an "docs" subdir
 
# Takes a port parameter, just so you know which one you're running on.
test -n "$1" || { echo "$0 <port>"; exit 1; }
port=$1
dir=`dirname $0`
docs=$dir/docs
 
function wtf_server () {
    while true ; do
        read msg
        case $msg in
            i | index )
                ls $docs ;;
            get\ * )
                f=${msg#get }
                cat $docs/$f ;;
            t | time )
                date ;;
            u | uptime )
                uptime ;;
            * )
                echo "Commands: t, time; u, uptime; i, index; get <file>"
                echo "    ctrl-c to exit"
        esac
        echo -n "> "
    done
}
 
# Start wtf_server as a background coprocess named WTF
# Its stdin filehandle is ${WTF[1]}, and its stdout is ${WTF[0]}
coproc WTF { wtf_server; }
 
# Start a netcat server, with its stdin redirected from WTF's stdout,
# and its stdout redirected to WTF's stdin
nc -l -p $port -k <&${WTF[0]} >&${WTF[1]}
