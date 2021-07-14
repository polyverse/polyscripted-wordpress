#!/bin/bash
# Copyright (c) 2020 Polyverse Corporation

if [ ! -v PHP_EXEC ]; then
	PHP_EXEC=/usr/local/bin
fi

if [ ! -f "${PHP_EXEC}/s_php" ]; then
    echo "Backing up original php to s_php..."
    cp -p $PHP_EXEC/php $PHP_EXEC/s_php
fi

if [ ! -d "${POLYSCRIPT_PATH}/vanilla-save" ]; then
    echo "Generating a Vanilla Save of the original PHP's lexx, yacc and phar.php files..."
    mkdir $POLYSCRIPT_PATH/vanilla-save
    cp -p $PHP_SRC_PATH/Zend/zend_language_scanner.l $POLYSCRIPT_PATH/vanilla-save/zend_language_scanner.l
    cp -p $PHP_SRC_PATH/Zend/zend_language_parser.y $POLYSCRIPT_PATH/vanilla-save/zend_language_parser.y
    cp -p $PHP_SRC_PATH/ext/phar/phar.php $POLYSCRIPT_PATH/vanilla-save/phar.php
fi

echo "Creating a new PHP scramble..."
$POLYSCRIPT_PATH//php-scrambler

cp -p $PHP_SRC_PATH/ext/phar/phar.php .

$PHP_EXEC/s_php tok-php-transformer.php -p $POLYSCRIPT_PATH//phar.php --replace
mv $POLYSCRIPT_PATH//phar.php $PHP_SRC_PATH/ext/phar/phar.php

cd $PHP_SRC_PATH; make -o ext/phar/phar.php install -k; cd $POLYSCRIPT_PATH;
