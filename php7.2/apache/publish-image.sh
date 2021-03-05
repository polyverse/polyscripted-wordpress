#!/bin/bash
set -e

image="polyverse/polyscripted-wordpress"
echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)

echo "Copying scripts into current directory for docker build context..."
cp -Rp ../../scripts .

#Build and Tage Image
docker build -t $image:apache-7.2-$headsha .
docker tag $image:apache-7.2-$headsha $image:apache-7.2
docker tag $image:apache-7.2-$headsha $image:latest

#Dockerhub Repository
if [[ "$1" == "-p" ]]; then
	echo "Pushing to Docker Hub"
	docker push $image:apache-7.2-$headsha
	docker push $image:apache-7.2
	docker push $image:latest
fi
#Github Container Repository
if [[ "$1" == "-g" ]]; then
	echo "Pushing to Github Container Repository"
	docker tag $image:apache-7.2-$headsha ghcr.io/$image:apache-7.2-$headsha
	docker push ghcr.io/$image:apache-7.2-$headsha
fi

echo "Removing temporary scripts"
rm -rf ./scripts
