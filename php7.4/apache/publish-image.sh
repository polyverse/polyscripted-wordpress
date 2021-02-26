#!/bin/bash

image="polyverse/polyscripted-wordpress"

echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)

echo "Copying scripts into current directory for docker build context..."
cp -Rp ../../scripts .

docker build -t $image:apache-7.4-$headsha .
docker tag $image:apache-7.4-$headsha $image:apache-7.4
docker tag $image:apache-7.4-$headsha $image:latest

if [[ "$1" == "-p" ]]; then
	docker push $image:apache-7.4-$headsha
	docker push $image:apache-7.4
	docker push $image:latest
fi

echo "Removing temporary scripts"
rm -rf ./scripts
