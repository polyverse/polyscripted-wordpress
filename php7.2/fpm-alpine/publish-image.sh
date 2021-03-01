#!/bin/bash

image="polyverse/polyscripted-wordpress"

echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)


echo "Copying scripts into current directory for docker build context..."
cp -Rp ../../scripts .

docker build -t $image:alpine-7.2-$headsha .
docker tag $image:alpine-7.2-$headsha $image:alpine-7.2
docker tag $image:alpine-7.2-$headsha $image:latest

if [[ "$1" == "-p" ]]; then
	docker push $image:alpine-7.2-$headsha
	docker push $image:alpine-7.2-latest
	docker push $image:latest
fi
if [[ "$1" == "-g" ]]; then
        echo "Pushing to Github Container Repository"
        docker tag $image:alpine-7.2-$headsha ghcr.io/$image:alpine-7.2-$headsha
        docker push ghcr.io/$image:alpine-7.2-$headsha
fi

echo "Removing temporary scripts"
rm -rf ./scripts
