#!/bin/bash

### LOCK TO ENSURE MULTIPLE SCRAMBLES ARE NOT CALLED SIMULTANEOUSLY ###
exec 100>/var/tmp/scramble.lock || exit 1
flock -n 100 || exit 1
trap 'rm -f /var/tmp/scramble.lock' EXIT
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###  ###


for i in "$@"
do
case $i in
    --overwrite|-o)
    OW=1
    shift # past argument with no value
    ;;
    *)
    ;;
esac
done

if [[ $(ls -A /var/www/html) && $OW -ne 1 ]]; then
	echo "The directory /var/www/html is non-empty. This is unexpected and dangerous for this container."
	echo "To run this script, pass arugment --overwrite to enable overwriting /var/www/html directory."
	exit 1
fi

if [ ! -v PHP_EXEC ]; then
	PHP_EXEC=/usr/local/bin
fi

if [ ! -f "${PHP_EXEC}/s_php" ]; then
    $POLYSCRIPT_PATH/reset.sh
    cp -p $PHP_EXEC/php $POLYSCRIPT_PATH/s_php
fi

if [[ "$MODE" == "merge" ]]; then
    echo "Merging files only."
    export MODE=polyscripted
    merge=true
fi

if [[ "$MODE" == "polyscripted" || -f /polyscripted ]]; then

	echo "===================== POLYSCRIPTING ENABLED =========================="
	if [ -d /wordpress ]; then
	    echo "Copying /wordpress to /var/www/html to be polyscripted in place..."
	    echo "This will prevent changes from being saved back to /wordpress, but will protect"
	    echo "against code injection attacks..."
		cp -Rp /wordpress /var/www/temp
	fi

	echo "Starting polyscripted WordPress"
	cd $POLYSCRIPT_PATH
	sed -i "/#mod_allow/a \define( 'DISALLOW_FILE_MODS', true );" /var/www/temp/wp-config.php

    if ! [[ "$merge" == 'true' && -f scrambled.json ]] ; then
        echo "Build flag found."
        ./build-scrambled.sh
    fi

	if [ -f scrambled.json ] && ./s_php tok-php-transformer.php -p /var/www/temp --replace; then
        rm -rf /var/www/html
		mv /var/www/temp /var/www/html
		echo "Polyscripting enabled."
		echo "done"
	else
		echo "Polyscripting failed."
		cp -p /usr/local/bin/s_php /usr/local/bin/php
		exit 1
	fi

	echo "Removing /var/www/html/wp-content/uploads (since it was deep-copied)..."
	echo "Don't worry it will be mounted properly in a moment."
	rm -rf /var/www/html/wp-content/uploads

else
    echo "Polyscripted mode is off. To enable it, either:"
    echo "  1. Set the environment variable: MODE=polyscripted"
    echo "  2. OR create a file at path: /polyscripted"

    # Symlink the mount so it's editable
    rm -rf /var/www/html
    ln -s /wordpress /var/www/html
fi

if [ -d /var/www/html/wp-content/uploads ]; then
	echo "Directory for uploads /var/www/html/wp-content/uploads exists. Doing nothing."
else
	echo "Directory for uploads /var/www/html/wp-content/uploads does not exist. Looking to mount it..."
	if [ -d /uploads ]; then
		echo "Uploads mounted at /uploads so symlinking that to /var/www/html/wp-content/uploads"
		ln -s /uploads /var/www/html/wp-content/uploads
	else
		if [ ! -d /wordpress/wp-content/uploads ]; then
			echo "Creating a directory for uploads at: /wordpress/wp-content/uploads"
			mkdir /wordpress/wp-content/uploads
		fi

		if [ -d /var/www/html/wp-content/uploads ]; then
			echo "/var/www/html/wp-content/uploads exists now."
			echo "/wordpress is probably already symlinked to /var/www/html (encapsulating /wordpress/wp-content/uploads with it)"
		else
			echo "Symlinking /wordpress/wp-content/uploads to /var/www/html/wp-content/uploads for persistent uploads"
			ln -s /wordpress/wp-content/uploads /var/www/html/wp-content/uploads
		fi

	fi
fi

if [ -f "${POLYSCRIPT_PATH}/s_php" ]; then
    rm  $POLYSCRIPT_PATH/s_php
fi

