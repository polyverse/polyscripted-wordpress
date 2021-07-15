#!/bin/bash

image="polyverse/polyscripted-wordpress"
echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)

echo "Copying scripts into current directory for docker build context..."
cp -nRp ../../scripts .

#Build and Tag
docker build -t ${image}:apache-7.4-${headsha} .
docker tag ${image}:apache-7.4-${headsha} ${image}:apache-7.4
docker tag ${image}:apache-7.4-${headsha} ${image}:latest

#Dockerhub Repository
if [[ "$1" == "-p" ]]; then
	docker push ${image}:apache-7.4-${headsha}
	docker push ${image}:apache-7.4
	docker push ${image}:latest
fi
#Github Container Repository
if [[ "$1" == "-g" ]]; then
        echo "Pushing to Github Container Repository"

	# Push specific sha
        docker tag ${image}:apache-7.4-${headsha} ghcr.io/${image}:apache-7.4-${headsha}
        docker push ghcr.io/${image}:apache-7.4-${headsha}

	# Push latest
        docker tag ${image}:apache-7.4-${headsha} ghcr.io/${image}:apache-7.4
        docker push ghcr.io/${image}:apache-7.4
fi

echo "Removing temporary scripts"
rm -rf ./scripts
