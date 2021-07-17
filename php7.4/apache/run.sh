#!/bin/bash

# 80-character wide dashes for intermittent use
# echo "--------------------------------------------------------------------------------"

CONTAINER_NAME=wordpress

function getContainerHealth {
	docker inspect --format "{{.State.Health.Status}}" $1
}

function waitContainer {
	while
		STATUS=$(getContainerHealth $1)
		[[ ! $STATUS == "healthy" ]]
	do
		if [[ $STATUS == "unhealthy" ]]; then
			echo "Failed to start mySql container. Exiting."
			exit -1
		fi
		printf .
		lf=$'\n'
		sleep 1
	done
	printf "$lf"
}

function checksql() {
	if [[ "$MYSQL_HOST_NAME" == "" ]]; then
		export MYSQL_HOST_NAME=mysql-host
	fi
}

function startsql() {
	checksql
	echo "------------------------------MYSQL START------------------------------------"
	if [[ "$WORDPRESS_SQL_DATADIR" == "" ]]; then
		WORDPRESS_SQL_DATADIR="$PWD/mysql-data"
	fi
	echo "    Starting a SQL container with data directory $WORDPRESS_SQL_DATADIR."
	echo "    you may override the location by specifying \$WORDPRESS_SQL_DATADIR."
	echo "    Starting a SQL container with name $MYSQL_HOST_NAME."
	echo "    you may override this name by specifying \$MYSQL_HOST_NAME."

	#Run mysql container
	if [[ $(docker ps -aq -f status=exited -f name=$MYSQL_HOST_NAME) ]]; then
		echo "Existing container found, but it is stopped. Starting now."
		docker start $MYSQL_HOST_NAME
	elif [[ $(docker ps -q -f status=running -f name=$MYSQL_HOST_NAME) ]]; then
		echo "Container already running."
	else
		docker run --name $MYSQL_HOST_NAME --health-cmd='   mysqladmin ping --silent' -e MYSQL_ROOT_PASSWORD=qwerty -v $WORDPRESS_SQL_DATADIR:/var/lib/mysql -d mysql:5.7
	fi
	export dblink="--link $MYSQL_HOST_NAME:mysql"
	if [[ ! $(getContainerHealth $MYSQL_HOST_NAME) == "healthy" ]]; then
		echo "Starting mysql container this may take a few moments."
		waitContainer $MYSQL_HOST_NAME
	fi
}

echo "---------------------------POLYSCRIPTING ON/OFF---------------------------------"
if [[ "$MODE" == "" ]]; then
	echo "    Under polyscripting, no changes can be made to the wordpress PHP files"
	echo "    such as, installing plugins or updates. We recommend running it in"
	echo "    unpolyscripted mode when making updates, and then restarting it with"
	echo "    polyscripting for maximum defense against code-injections."
	echo ""
	echo "    NOTE: You may automate this step by setting environment variable"
	echo "    \$MODE=polyscripted to enable polyscripting (empty/unset to disable it.)"
	echo ""
	while true; do
		read -p "Do you wish to run Polyscripted?" yn
		case $yn in
		[Yy]*)
			export MODE=polyscripted
			break
			;;
		[Nn]*)
			export MODE=unpolyscripted
			break
			;;
		*) echo "Please answer yes or no." ;;
		esac
	done
else
	echo "Running under mode: $MODE."
fi

echo "---------------------------WORDPRESS DIRECTORY---------------------------------"
if [[ "$WORDPRESSDIR" == "" ]]; then
	echo "    A Wordpress directory was not specified. Using a default directory"
	echo "    under the current path: $PWD/wordpress."
	echo ""
	echo "    NOTE: You may skip this by specifying \$WORDPRESSDIR=<path>"
	echo "    A new installation will be created if one does not already exist."
	echo ""
	while true; do
		read -p "Do you wish to use this wordpress directory?" yn
		case $yn in
		[Yy]*)
			export WORDPRESSDIR=$PWD/wordpress
			break
			;;
		[Nn]*) exit ;;
		*) echo "Please answer yes or no." ;;
		esac
	done
else
	echo "Using wordpress installation from directory: $WORDPRESSDIR"
fi

echo "-------------------------WORDPRESS CONFIGURATION--------------------------------"
echo ""
echo "Passing all WORDPRESS_* prefixed environment variables to container..."
wpvarparams=""

wpvars=${!WORDPRESS_@}
for wpvar in $wpvars; do
	echo "$wpvar=${!wpvar}"
	wpvarparams="$wpvarparams -e $wpvar=\"${!wpvar}\""

	if [[ "$WORDPRESS_DB_HOST" != "" ]]; then

		dbfound=true
	fi
done

echo "--------------------------DATABASE CONFIGURATION--------------------------------"
if [[ "$dbfound" != "true" ]]; then
	echo "No Database configuration found (WORDPRESS_DB_HOST environment variable empty.)"
	echo "To use an existing SQL server please specify the following variables:"
	echo "  WORDPRESS_DB_HOST - what host should the container connect to?"
	echo "  WORDPRESS_DB_USER - what username to connect as?"
	echo "  WORDPRESS_DB_PASSWORD - authenticate the user."
	echo "  WORDPRESS_DB_NAME - Database to use"
	echo "  WORDPRESS_DB_CHARSET"
	echo "  WORDPRESS_DB_COLLATE"
	echo "  WORDPRESS_TABLE_PREFIX"
	echo "Setting the WORDPRESS_DB_HOST variable, will skip this step automatically."
	echo ""
	echo "Wordpress probably will not work without a database. You can continue without"
	echo "a database, or a SQL instance can be started for you."
	while true; do
		read -p "Do you want a SQL instance launched for you?" yn
		case $yn in
		[Yy]*)
			startsql
			break
			;;
		[Nn]*)
			echo "Proceeding to run wordpress without a SQL connection."
			break
			;;
		*) echo "Please answer yes or no." ;;
		esac
	done
else
	echo "Found existing database configuration."
fi

echo "-------------------------WORDPRESS STARTUP--------------------------------------"
echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)
if [[ "$CONTAINERPORT" == "" ]]; then
	echo "No override container port found, using default exposed port 80."
	CONTAINERPORT=80
fi
if [[ "$HOSTPORT" == "" ]]; then
	echo "No host port env variable found, defaulting to port 8000."
	HOSTPORT=8000
fi
wpcmd="docker run -t -d -e MODE=$MODE --name $CONTAINER_NAME -v $WORDPRESSDIR:/wordpress -p $HOSTPORT:$CONTAINERPORT  $wpvarparams $dblink polyverse/polyscripted-wordpress:apache-7.4-${headsha} bash"
if [[ "$*" == "-f" ]]; then
	echo "YES"
else
	echo "NO"
fi

function startBackgroundTasks() {
	if [[ $PLUGIN != "true" ]]; then
		while true; do
			read -p "Do you want to start dispatcher for the polyscripting plugin to allow scrambling from the wordpress plugin?"
			case $yn in
			[Yy]*)
				docker exec -d $CONTAINER_NAME ./dispatch.sh 2323
				echo "Set PLUGIN to true to skip this prompt."
				break
				;;
			[Nn]*)
				echo "To enable dispatcher in the future run: docker exec -d $CONTAINER_NAME ./dispatch.sh 2323; break;;"
				break
				;;
			*) echo "Please answer yes or no." ;;
			esac
		done
	else
		docker exec -d $CONTAINER_NAME ./dispatch.sh 2323
	fi
	echo "Starting apache server inside $CONTAINER_NAME"
	docker exec -e MODE=$MODE --workdir /usr/local/bin $CONTAINER_NAME ./docker-entrypoint.sh apache2-foreground
}

function startContainer() {
	if [[ $(docker ps -aq -f status=exited -f name=$CONTAINER_NAME) ]]; then
		echo "Existing container found, but it is stopped. Starting now."
		docker start $CONTAINER_NAME
		startBackgroundTasks
	elif [[ $(docker ps -q -f status=running -f name=$CONTAINER_NAME) ]]; then
		echo "Container already running."
		echo "To start dispatcher run: 'docker exec -d $CONTAINER_NAME ./dispatch.sh 2323'"
		echo "To start apache run: 'docker exec -e MODE=$MODE  --workdir /usr/local/bin $CONTAINER_NAME ./docker-entrypoint.sh apache2-foreground;'"
	else
		eval $wpcmd
		startBackgroundTasks
	fi
}

echo "About to run this command (you may copy/store it to run directly):"
echo "$wpcmd"
echo ""
while true; do
	read -p "Do you wish to continue?" yn
	case $yn in
	[Yy]*)
		startContainer
		exit
		;;
	[Nn]*)
		echo "Not starting wordpress."
		exit
		;;
	*) echo "Please answer yes or no." ;;
	esac
done
