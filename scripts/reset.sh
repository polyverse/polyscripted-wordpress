#!/bin/bash
# Copyright (c) 2020 Polyverse Corporation

set -e

echo "RESETTING back to Vanilla PHP"

if [ -d "${POLYSCRIPT_PATH}/vanilla-php" ]; then
    echo "Restoring from vanilla php..."
    rm -rf $PHP_SRC_PATH; cp -ra $POLYSCRIPT_PATH/vanilla-php $PHP_SRC_PATH
fi

echo "Installing restored Vanilla PHP..."
cd $PHP_SRC_PATH; make -o ext/phar/phar.php install -k; cd $POLYSCRIPT_PATH;
