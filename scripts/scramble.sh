#!/bin/bash

set -e

if [ "$1" == "FIRST_CALL" ] && [ "$(ls -A /var/www/html)" ]; then
	echo "The directory /var/www/html is non-empty. This is unexpected and dangerous for this container."
	echo "This container expects Wordpress (or the PHP app) at location '/wordpress' which will then be"
	echo "properly provided at /var/www/html either directly or polyscripted."
	echo ""
	echo "To avoid destroying your code, aboring this container."

	exit 1
fi

if [[ "$MODE" == "polyscripted" || -f /polyscripted ]]; then

	echo "===================== POLYSCRIPTING ENABLED =========================="
	if [ -d /wordpress ]; then
		echo "Copying /wordpress to /var/www/temp to be polyscripted in place..."
		echo "This will prevent changes from being saved back to /wordpress, but will protect"
		echo "against code injection attacks..."
		cp -nRp /wordpress /var/www/temp
	fi

	echo "Starting polyscripted WordPress"
	cd $POLYSCRIPT_PATH

	if [[ -f /var/www/html/wp-config.php ]]; then
		sed -i "/#mod_allow/a \define( 'DISALLOW_FILE_MODS', true );" /var/www/html/wp-config.php
	fi

	./build-scrambled.sh

	# Set transformer memory limit
	if [[ $TRANSFORMER_MEMORY_LIMIT != "" ]]; then
		memory_limit_params="--memory_limit=$TRANSFORMER_MEMORY_LIMIT"
	fi

	echo "About to scramble files in /var/www/temp..."
	if [ -f scrambled.json ] && s_php tok-php-transformer.php $memory_limit_params -d scrambled.json -p /var/www/temp --replace; then
		echo "Removing existing /var/www/html"
		rm -rf /var/www/html
		echo "Moving /var/www/temp->/var/www/html"
		mv /var/www/temp /var/www/html
		echo "Polyscripting enabled."
		echo "done"
	else
		echo "Polyscripting failed."
		cp -np /usr/local/bin/s_php /usr/local/bin/php
		exit 1
	fi

	echo "Removing /var/www/html/wp-content/uploads (since it was deep-copied)..."
	echo "Don't worry it will be mounted properly in a moment."
	rm -rf /var/www/html/wp-content/uploads

else
	echo "Polyscripted mode is off. To enable it, either:"
	echo "  1. Set the environment variable: MODE=polyscripted"
	echo "  2. OR create a file at path: /polyscripted"

	$POLYSCRIPT_PATH/reset.sh

	echo "Removing /var/www/html..."
	rm -rf /var/www/html

	echo "Symlink the mounted /wordpress -> /var/www/html so it's editable"
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
			chown www-data:www-data /wordpress/wp-content/uploads
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
