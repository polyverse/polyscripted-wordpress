#!/bin/bash

image="polyverse/polyscripted-wordpress"

echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)

echo "Copying scripts into current directory for docker build context..."
cp -nRp ../../scripts .

docker build -t ${image}:apache-8.0-${headsha} .
docker tag ${image}:apache-8.0-${headsha} ${image}:apache-8.0
docker tag ${image}:apache-8.0-${headsha} ${image}:latest

if [[ "$1" == "-p" ]]; then
	docker push ${image}:apache-8.0-${headsha}
	docker push ${image}:apache-8.0
	docker push ${image}:latest
fi
if [[ "$1" == "-g" ]]; then
        echo "Pushing to Github Container Repository"

	# Push specific sha
        docker tag ${image}:apache-8.0-${headsha} ghcr.io/${image}:apache-8.0-${headsha}
        docker push ghcr.io/${image}:apache-8.0-${headsha}

	# push latest
        docker tag ${image}:apache-8.0-${headsha} ghcr.io/${image}:apache-8.0
        docker push ghcr.io/${image}:apache-8.0
fi

echo "Removing temporary scripts"
rm -rf ./scripts
