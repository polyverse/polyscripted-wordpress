#!/bin/bash
if [ -d /var/www/html ]; then
	echo "A mounted/previous directory /var/www/html exists. We will be replacing it with polyscripted code,"
	echo "at least once if not more. Moving the directory to /var/www/html.original to avoid touching it."
	echo "As of the building of this image, moving a mounted directory in a Docker Container still kept it"
	echo "mounted so this should be okay."

	mv /var/www/html /var/www/html.original
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
	sed -i "/#mod_allow/a \define( 'DISALLOW_FILE_MODS', true );" /var/www/html/wp-config.php
    	./build-scrambled.sh
	if [ -f scrambled.json ] && s_php tok-php-transformer.php -p /var/www/temp --replace; then
		rm -rf /var/www/html
		mv /var/www/temp /var/www/html
		echo "Polyscripting enabled."
		echo "done"
	else
		echo "Polyscripting failed."
		cp -p /usr/local/bin/s_php /usr/local/bin/php
		exit 1
	fi

	rm  -rf /var/www/html/wp-content/uploads
	if [ -d /uploads ]; then
		ln -s /uploads /var/www/html/wp-content/uploads
	else
		ln -s /wordpress/wp-content/uploads /var/www/html/wp-content/uploads
	fi
else
    echo "Polyscripted mode is off. To enable it, either:"
    echo "  1. Set the environment variable: MODE=polyscripted"
    echo "  2. OR create a file at path: /polyscripted"

    if [ -d vanilla-save ]; then
	    reset.sh
    fi
    # Symlink the mount so it's editable
    rm -rf /var/www/html
    ln -s /wordpress /var/www/html
fi

