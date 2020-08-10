#!/bin/bash

# Takes a port parameter
test -n "$1" || { echo "$0 <port>"; exit 1; }
port=$1
dir=`dirname $0`
docs=$dir/docs

echo "$(date) - start" >> txt.txt

function wtf_server () {
	echo "$(date) - Enter" >> txt.txt
    while true ; do
	    echo "$(date) - While" >> txt.txt
    read -d ' ' msg
        case $msg in
            1 )
		    echo "$(date) - 1" >> txt.txt
                echo "$(date) - " >> last.txt
                ./plugin-scramble.sh >> last.txt ;;
            2 )
		    echo "$(date) - 2" >> txt.txt
                echo "$(date) - " >> last.txt
                ./plugin-rescramble.sh >> last.txt ;;
            3 )
		    echo "$(date) - 3" >> txt.txt
                echo "$(date) - " >> last.txt
                ./plugin-reset.sh >> last.txt ;;
            * )
		    echo "$(date) - err" >> txt.txt
                echo "Commands: 1, scramble; 2, rescramble; 3, reset;"
                echo "    ctrl-c to exit"
        esac
	echo "$(date) - done" >> txt.txt
        echo -n "> "
    done
    echo "$(date) - complete" >> txt.txt
}
 
# Start wtf_server as a background coprocess named WTF
# Its stdin filehandle is ${WTF[1]}, and its stdout is ${WTF[0]}
coproc WTF { wtf_server; }
 
# Start a netcat server, with its stdin redirected from WTF's stdout,
# and its stdout redirected to WTF's stdin
nc -v -l -p $port -k <&${WTF[0]} >&${WTF[1]}

