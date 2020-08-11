#!/bin/bash
# Copyright (c) 2020 Polyverse Corporation
 
test -n "$1" || { echo "$0 <port>"; exit 1; }
port=$1

function poly-dispatcher () {
    while true ; do
    read -d ' ' msg
        case $msg in
            1 )
		    echo "1" >> dispatcher-in.logs
		    export MODE=polyscripted ;;
            2 )
		    echo "2" >> dispatcher-in.logs
		    export MODE=polyscripted ;;
            3 )
		    echo "3" >> dispatcher-in.logs
		    export MODE=off ;;
            * )
	    	    err='true'
		    echo "err" >> dispatcher-in.logs
                echo "Commands: 1, scramble; 2, rescramble; 3, reset;"
                echo "    ctrl-c to exit"
        esac
	if ! [[ $err = 'true'  ]]; then
		scramble.sh > dispatcher-out.logs
		service apache2 restart >> dispatcher-in.logs
		err='false'
	fi
	echo "done" >> dispatcher-in.logs
        echo -n "> "
    done
    echo "complete" >> dispatcher-in.logs
}
 
coproc proc_dispatcher { poly-dispatcher; }
 
nc -v -l -p $port -k <&${proc_dispatcher[0]} >&${proc_dispatcher[1]}
