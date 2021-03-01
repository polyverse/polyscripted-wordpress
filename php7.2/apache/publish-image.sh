#!/bin/bash

image="polyverse/polyscripted-wordpress"

echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)


echo "Copying scripts into current directory for docker build context..."
cp -Rp ../../scripts .


docker build -t $image:apache-7.2-$headsha .
docker tag $image:apache-7.2-$headsha $image:apache-7.2
docker tag $image:apache-7.2-$headsha $image:latest

if [[ "$1" == "-p" ]]; then
	docker push $image:apache-7.2-$headsha
	docker push $image:apache-7.2
	docker push $image:latest
fi

if [[ "$1" == "-g" ]]; then
	docker tag $image:apache-7.2-$headsha ghcr.io/$image:apache-7.2-$headsha
	docker push ghcr.io/$image:apache-7.2-$headsha
fi

echo "Removing temporary scripts"
rm -rf ./scripts
