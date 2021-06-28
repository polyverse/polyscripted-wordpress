#!/bin/bash
# Copyright (c) 2020 Polyverse Corporation

test -n "$1" || { echo "$0 <port>"; exit 1; }
port=$1
volume="/wordpress"

LOGFILE="/var/log/dispatcher-in.logs"

#Cron job to curl wp-crons -- updated health of container every hour.
if [[ '$WP_DISABLE_CRON' != 'true' ]]; then
    (crontab -l 2>/dev/null | grep -v '^[a-zA-Z]'; echo "*/15 * * * * curl $CONTAINER_ADDRESS/wp-cron.php >> /var/log/wp-cron.log 2>&1") | sort - | uniq - | crontab -
    echo "Starting Cron job for Polyscripting Plugin"
    /etc/init.d/cron start
fi

#Cron job to watch for mounted volume changes.
if [[ '$WP_DISABLE_INCRON' != 'true' ]]; then
    (incrontab -l 2>/dev/null | grep -v '^[a-zA-Z]'; echo "$volume IN_MODIFY,loopable=true /usr/local/bin/polyscripting/wp-incron.sh $port >> /var/log/wp-incron.log 2>&1") | sort - | uniq - | incrontab -
    echo "Starting incron job for Polyscripting Plugin"
    /etc/init.d/incron start
fi


function poly-dispatcher () {
    while true ; do
    read -d ' ' msg
        now=$(date +"%T")
        case $msg in
            1 )
		    echo "Recieved code 1, scrambling. $now" >> $LOGFILE
		    export MODE=polyscripted ;;
            2 )
		    echo "Recieved code 2, rescrambling. $now" >> $LOGFILE
		    export MODE=polyscripted ;;
            3 )
		    echo "Recieved code 3, disabling. $now" +  >> $LOGFILE
		    export MODE=off ;;
		    4 )
		    echo "Recieved code 4, merging. $now" +  >> $LOGFILE
		    if [ "$MODE" ==  "polyscripted" ]; then
		    	echo "Polyscripting enabled, merging changes from mounted directory."
		        export MODE=merge
		        merge='true'
		    else
		        echo "Polyscripting not enabled, merge not necessary."
		        no_action='true'
		    fi
		  	;;
            * )
		        no_action='true'
		        echo "err $now" >> $LOGFILE
                echo "Commands: 1, scramble; 2, rescramble; 3, merge 4, reset;"
                echo "    ctrl-c to exit"
        esac
	if ! [[ $no_action == 'true'  ]]; then
		echo "Calling scramble script"
	    scramble.sh -o >& /usr/local/bin/polyscripting/to_main_process
		if ! [[ $merge == 'true' ]]; then
		    echo "Restarting services"
		    service apache2 stop >& /usr/local/bin/polyscripting/to_main_process
		    /usr/local/bin/tini -s -- "apache2-foreground" >& /usr/local/bin/polyscripting/to_main_process &
		else
			echo "Merge complete. Not restarting services."
		    export MODE=polyscripted
		    export merge='false'
		fi
		no_action='false'
	fi
	    no_action='false'
	    echo "Message read complete. Waiting for next." >> $LOGFILE
        echo -n "> "
    done
    echo "complete dispatcher process ending." >> $LOGFILE
}

coproc proc_dispatcher { poly-dispatcher; }

nc -v -l -p $port -k <&${proc_dispatcher[0]} >&${proc_dispatcher[1]}

