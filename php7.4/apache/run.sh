#!/bin/bash
# 80-character wide dashes for intermittent use
# echo "--------------------------------------------------------------------------------"

php_version=apache-7.4

if [[ "$CONTAINER_NAME" == "" ]]; then
    echo "No container name env variable found, defaulting to wordpress."
    CONTAINER_NAME=wordpress
fi
if [[ "$CONTAINER_PORT" == "" ]]; then
	echo "No override container port found, using default exposed port 80."
	CONTAINER_PORT=80
fi
if [[ "$HOST_PORT" == "" ]]; then
    echo "No host port env variable found, defaulting to port 8000."
    HOST_PORT=8000
fi
if [[ "$CONTAINER_ADDRESS" == "" ]]; then
    echo "Defaulting to localhost for cron."
    CONTAINER_ADDRESS="http://localhost:$CONTAINER_PORT"
fi

function getContainerHealth {
  docker inspect --format "{{.State.Health.Status}}" $1
}

function waitContainer {
  while STATUS=$(getContainerHealth $1); [[ ! $STATUS == "healthy" ]]; do
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
		[Yy]* ) export MODE=polyscripted; break;;
		[Nn]* ) export MODE=unpolyscripted; break;;
		* ) echo "Please answer yes or no.";;
	    esac
	done
else
	echo "Running under mode: $MODE."
fi


echo "---------------------------WORDPRESS DIRECTORY---------------------------------"
if [[ "$WORDPRESS_DIR" == "" ]]; then
	echo "    A Wordpress directory was not specified. Using a default directory"
	echo "    under the current path: $PWD/wordpress."
	echo ""
	echo "    NOTE: You may skip this by specifying \$WORDPRESSDIR=<path>"
	echo "    A new installation will be created if one does not already exist."
	echo ""
	while true; do
	    read -p "Do you wish to use this wordpress directory?" yn
	    case $yn in
		[Yy]* ) export WORDPRESS_DIR=$PWD/wordpress; break;;
		[Nn]* ) exit;;
		* ) echo "Please answer yes or no.";;
	    esac
	done
else
	echo "Using wordpress installation from directory: $WORDPRESS_DIR"
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
		[Yy]* ) startsql; break;;
		[Nn]* ) echo "Proceeding to run wordpress without a SQL connection."; break;;
		* ) echo "Please answer yes or no.";;
	    esac
	done
else
    echo "Found existing database configuration."
fi

echo "-------------------------SYSTEM CRON ----------------------------------------"
echo "For optimization a system cron is utilized for the plugin."
echo "Set CONTAINER_ADDRESS to configure this cron."
echo "To disable cron jobs set WP_DISABLE_CRON and WP_DISABLE_INCRON to true."
echo ""

echo "-------------------------WORDPRESS STARTUP--------------------------------------"
echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)

wpcmd="docker run -t -e MODE=$MODE -e CONTAINER_ADDRESS=$CONTAINER_ADDRESS --name $CONTAINER_NAME -v $WORDPRESS_DIR:/wordpress -p $HOST_PORT:$CONTAINER_PORT  $wpvarparams $dblink polyverse/polyscripted-wordpress:$php_version-$headsha"

function startContainer() {
    if [[ $(docker ps -aq -f status=exited -f name=$CONTAINER_NAME) ]]; then
        echo "Existing container found, but it is stopped."
        echo "Restart, rename, or delete existing container."
    elif [[ $(docker ps -q -f status=running -f name=$CONTAINER_NAME) ]]; then
        echo "Container already running."
    else
            eval $wpcmd;
    fi
}

echo "About to run this command (you may copy/store it to run directly):"
echo "$wpcmd"
echo ""
while true; do
    read -p "Do you wish to continue?" yn
    case $yn in
        [Yy]* ) startContainer; exit;;
        [Nn]* ) echo "Not starting wordpress."; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
