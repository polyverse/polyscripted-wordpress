#!/bin/bash
# Copyright (c) 2020 Polyverse Corporation
set -ex

echo "RESETTING back to Vanilla PHP"

echo "Restoring php executable..."
if [ -f "${PHP_EXEC}/s_php" ]; then
    echo "Restore up original s_php to php..."
    cp -p $PHP_EXEC/s_php $PHP_EXEC/php
fi

echo "Restoring Vanilla Save..."
cp -p $POLYSCRIPT_PATH/vanilla-save/zend_language_scanner.l $PHP_SRC_PATH/Zend/zend_language_scanner.l
cp -p $POLYSCRIPT_PATH/vanilla-save/zend_language_parser.y $PHP_SRC_PATH/Zend/zend_language_parser.y
cp -p $POLYSCRIPT_PATH/vanilla-save/phar.php $PHP_SRC_PATH/ext/phar/phar.php

cd $PHP_SRC_PATH; make -o ext/phar/phar.php install -k; cd $POLYSCRIPT_PATH;
