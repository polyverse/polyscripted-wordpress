#!/bin/bash

image="polyverse/polyscripted-wordpress"

echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)


echo "Copying scripts into current directory for docker build context..."
cp -Rp ../../scripts .

docker build -t $image:alpine-7.2-$headsha . --no-cache
docker tag $image:alpine-7.2-$headsha $image:alpine-7.2
docker tag $image:alpine-7.2-$headsha $image:latest

if [[ "$1" == "-p" ]]; then
	docker push $image:alpine-7.2-$headsha
	docker push $image:alpine-7.2-latest
	docker push $image:latest
fi

echo "Removing temporary scripts"
rm -rf ./scripts
