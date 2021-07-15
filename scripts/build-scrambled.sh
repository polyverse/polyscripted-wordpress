#!/bin/bash
# Copyright (c) 2020 Polyverse Corporation
set -e

if [ ! -f "${PHP_EXEC}/s_php" ]; then
    echo "Backing up original php executable to s_php..."
    cp -p $PHP_EXEC/php $PHP_EXEC/s_php
fi

if [ ! -d "${POLYSCRIPT_PATH}/vanilla-php" ]; then
    echo "Backing up to Vanilla PHP directory before scrambling..."
    cp -ra $PHP_SRC_PATH $POLYSCRIPT_PATH/vanilla-php
else
    echo "Restoring from vanilla php before scrambling..."
    rm -rf $PHP_SRC_PATH; cp -ra $POLYSCRIPT_PATH/vanilla-php $PHP_SRC_PATH
fi

echo "Creating a new PHP scramble..."
$POLYSCRIPT_PATH/php-scrambler

cp -p $PHP_SRC_PATH/ext/phar/phar.php .

$PHP_EXEC/s_php tok-php-transformer.php -p $POLYSCRIPT_PATH/phar.php --replace
mv $POLYSCRIPT_PATH/phar.php $PHP_SRC_PATH/ext/phar/phar.php

cd $PHP_SRC_PATH
# Ingore errors in building PHP
make -o ext/phar/phar.php install -k || true
cd $POLYSCRIPT_PATH;
