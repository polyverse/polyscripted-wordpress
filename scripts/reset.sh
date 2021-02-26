#!/bin/bash
# Copyright (c) 2020 Polyverse Corporation

cd $PHP_SRC_PATH; make -o ext/phar/phar.php install -k; cd $POLYSCRIPT_PATH;
