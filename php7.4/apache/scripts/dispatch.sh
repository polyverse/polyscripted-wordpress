#!/bin/bash
 
# Weird little TCP server
# Tells time and uptime; can list and dump files in an "docs" subdir
 
# Takes a port parameter, just so you know which one you're running on.
test -n "$1" || { echo "$0 <port>"; exit 1; }
port=$1
dir=`dirname $0`
docs=$dir/docs

echo "start" >> txt.txt

function wtf_server () {
	echo "Enter" >> txt.txt
    while true ; do
	    echo "While" >> txt.txt
    read -d ' ' msg
        case $msg in
            1 )
		    echo "1" >> txt.txt
		    export MODE=polyscripted ;;
            2 )
		    echo "2" >> txt.txt
		    ./reset.sh >> txt.txt
		    export MODE=polyscripted ;;
            3 )
		    echo "3" >> txt.txt
		    export MODE=off ;;
            * )
	    	    err='true'
		    echo "err" >> txt.txt
                echo "Commands: 1, scramble; 2, rescramble; 3, reset;"
                echo "    ctrl-c to exit"
        esac
	if ! [ $err = 'true'  ]; then
		scramble.sh > last.txt
		service apache2 restart >> txt.txt
		$err='false'
	fi
	echo "done" >> txt.txt
        echo -n "> "
    done
    echo "complete" >> txt.txt
}
 
# Start wtf_server as a background coprocess named WTF
# Its stdin filehandle is ${WTF[1]}, and its stdout is ${WTF[0]}
coproc WTF { wtf_server; }
 
# Start a netcat server, with its stdin redirected from WTF's stdout,
# and its stdout redirected to WTF's stdin
nc -v -l -p $port -k <&${WTF[0]} >&${WTF[1]}
