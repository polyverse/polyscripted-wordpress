#!/bin/bash

# 80-character wide dashes for intermittent use
# echo "--------------------------------------------------------------------------------"

function startsql() {
	echo "---------------------------POLYSCRIPTING ON/OFF---------------------------------"
	if [[ "$WORDPRESS_SQL_DATADIR" == "" ]]; then
		WORDPRESS_SQL_DATADIR="$PWD/mysql-data"
	fi
	echo "    Starting a SQL container with data directory $WORDPRESS_SQL_DATADIR."
	echo "    you may override the location by specifying \$WORDPRESS_SQL_DATADIR"
	docker run --name mysql-host -e MYSQL_ROOT_PASSWORD=qwerty -v $WORDPRESS_SQL_DATADIR:/var/lib/mysql -d mysql:5.7
	export dblink="--link mysql-host:mysql"
}

echo "---------------------------POLYSCRIPTING ON/OFF---------------------------------"
if [[ "$MODE" == "" ]]; then
	echo "    Under polyscripting, no changes can be made to the wordpress PHP files"
	echo "    such as, installing plugins or updates. We recommend running it in"
	echo "    unpolyscripted mode when making updates, and then restarting it with"
	echo "    polyscripting for maximum defense against code-injections."
	echo ""
	echo "    NOTE: You may automate this step by setting environment variable"
	echo "    \$MODE=polyscripted to enable polyscripting (empy/unset to disable it.)"
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
		[Yy]* ) export WORDPRESSDIR=$PWD/wordpress; break;;
		[Nn]* ) exit;;
		* ) echo "Please answer yes or no.";;
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
	
	if [[ "$wpvars" == "WORDPRESS_DB_HOST" ]]; then
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
fi

echo "-------------------------WORDPRESS STARTUP--------------------------------------"
echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)
wpcmd="docker run --rm -e MODE=$MODE --name wordpress -v $WORDPRESSDIR:/wordpress -p 8000:80  $wpvarparams $dblink polyverse/polyscripted-wordpress:debian-$headsha"
echo "About to run this command (you may copy/store it to run directly):"
echo "$wpcmd"
echo ""
while true; do
    read -p "Do you wish to continue?" yn
    case $yn in
        [Yy]* ) eval $wpcmd; exit;;
        [Nn]* ) echo "Not starting wordpress."; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
