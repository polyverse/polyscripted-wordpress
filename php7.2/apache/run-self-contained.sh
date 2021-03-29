#!/bin/bash
MODE=$1

echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)

echo "Running under mode: $MODE"
docker run --name mysql-host -e MYSQL_ROOT_PASSWORD=qwerty -d mysql:5.7
docker run --rm -e MODE=$MODE --name wordpress -v $PWD/wordpress:/wordpress  --link mysql-host:mysql -p 8000:80  polyverse/polyscripted-wordpress:apache-7.2-$headsha
