#!/bin/bash

if [[ "$MODE" == "" ]]; then
	MODE="unpolyscripted"
fi

WORDPRESSDIR=$PWD/wordpress


echo "Running under mode: $MODE."
echo "==> You must specify \$MODE=polyscripted to enable polyscripting."
echo ""
echo "Using wordpress installation from directory: $WORDPRESSDIR"
echo "==> You may override this by specifying \$WORDPRESSDIR=/your/preferred/directory"
echo "==> A new installation will be created if one does not already exist."

echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)

docker run --rm -e MODE=$MODE --name wordpress -v $WORDPRESSDIR:/wordpress -p 8000:80  polyverse/polyscripted-wordpress:debian-$headsha
