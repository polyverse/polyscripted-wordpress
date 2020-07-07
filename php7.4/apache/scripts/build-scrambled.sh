#!/bin/bash
# Copyright (c) 2020 Polyverse Corporation

if [ ! -v PHP_EXEC ]; then
	PHP_EXEC=/usr/local/bin
fi

if [ ! -f "${PHP_EXEC}/s_php" ]; then
     cp $PHP_EXEC/php $PHP_EXEC/s_php
fi  

if [ ! -d "${POLYSCRIPT_PATH}/vanilla-save" ]; then
    mkdir $POLYSCRIPT_PATH/vanilla-save
    cp $PHP_SRC_PATH/Zend/zend_language_scanner.l /usr/local/bin/polyscripting/vanilla-save/zend_language_scanner.l
    cp $PHP_SRC_PATH/Zend/zend_language_parser.y /usr/local/bin/polyscripting/vanilla-save/zend_language_parser.y
    cp $PHP_SRC_PATH/ext/phar/phar.php /usr/local/bin/polyscripting/vanilla-save/phar.php
fi

./php-scrambler

cp $PHP_SRC_PATH/ext/phar/phar.php .

$PHP_EXEC/s_php tok-php-transformer.php -p ./phar.php --replace
mv ./phar.php $PHP_SRC_PATH/ext/phar/phar.php

cd $PHP_SRC_PATH; make -o ext/phar/phar.php install -k; cd $POLYSCRIPT_PATH;
