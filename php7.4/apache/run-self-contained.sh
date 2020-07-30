#!/bin/bash

MODE=$1

echo "Running under mode: $MODE"

echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)

docker run --name mysql-host -e MYSQL_ROOT_PASSWORD=qwerty -d mysql:5.7
docker run -p 8080:80 -e MODE=$MODE --name wordpress -v $PWD/wordpress:/wordpress  --link mysql-host:mysql -t -d polyverse/polyscripted-wordpress:apache-7.4-$headsha bash

docker start mysql-host
docker start wordpress 

docker exec --workdir /usr/local/bin  wordpress ./docker-entrypoint.sh apache2-foreground
