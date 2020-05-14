#!/bin/bash

image="polyverse/polyscripted-wordpress"

echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)


docker build -t $image:debian-$headsha .
docker tag $image:debian-$headsha $image:debian

if [[ "$1" == "-p" ]]; then
	docker push $image:debian-$headsha
	docker push $image:debian
fi
