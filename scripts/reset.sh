#!/bin/bash
# Copyright (c) 2020 Polyverse Corporation

set -e

echo "RESETTING back to Vanilla PHP"

if [ -d "${POLYSCRIPT_PATH}/vanilla-save" ]; then
    echo "Restoring Vanilla Save..."
    cp -p $POLYSCRIPT_PATH/vanilla-save/zend_language_scanner.l $PHP_SRC_PATH/Zend/zend_language_scanner.l
    cp -p $POLYSCRIPT_PATH/vanilla-save/zend_language_parser.y $PHP_SRC_PATH/Zend/zend_language_parser.y
    cp -p $POLYSCRIPT_PATH/vanilla-save/phar.php $PHP_SRC_PATH/ext/phar/phar.php
fi

echo "RESTORING Vanilla PHP: Running the first build of two"
cd $PHP_SRC_PATH; make -o ext/phar/phar.php install -k; cd $POLYSCRIPT_PATH;
