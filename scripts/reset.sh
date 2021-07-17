#!/bin/bash
# Copyright (c) 2020 Polyverse Corporation

set -e

echo "RESETTING back to Vanilla PHP"

if [ -d "${POLYSCRIPT_PATH}/vanilla-php" ]; then
    echo "Restoring from vanilla php..."
    rm -rf $PHP_SRC_PATH
    cp -nra $POLYSCRIPT_PATH/vanilla-php $PHP_SRC_PATH
fi

echo "Installing restored Vanilla PHP..."
cd $PHP_SRC_PATH
# Ingore errors in building PHP
make -o ext/phar/phar.php install -k || true
cd $POLYSCRIPT_PATH
