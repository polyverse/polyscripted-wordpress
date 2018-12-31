#!/bin/sh

image="polyverse/polyscripted-wordpress"

echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)


docker build -t $image:$headsha .
docker tag $image:alpine-$headsha $image:alpine $image:latest

if [[ "$1" == "-p" ]]; then
	docker push $image:$headsha
	docker push $image:alpine
	docker push $image:latest
fi