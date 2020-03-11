#!/bin/sh

image="polyverse/polyscripted-wordpress"

echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)


docker build -t $image:debian-$headsha .
docker tag $image:debian-$headsha $image:debian
docker tag $image:debian-$headsha $image:latest

if [[ "$1" == "-p" ]]; then
	docker push $image:debian-$headsha
	docker push $image:debian
	docker push $image:latest
fi
