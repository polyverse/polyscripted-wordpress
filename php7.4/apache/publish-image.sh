#!/bin/bash

image="polyverse/polyscripted-wordpress"
name="polyscripted-wordpress"
tag="7.4-apache"
gpr="docker.pkg.github.com/"$image"/"$name":"$tag
echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)

echo "Building and tagging image"
docker build -t $image:$tag-$headsha .

echo "Pushing images"
if [[ "$1" == "-p" ]]; then
	docker tag $image:$tag-$headsha $image:$tag-latest
	docker push $image:$tag-$headsha
        docker push $image:$tag-latest
fi

if [[ "$1" == "-g" ]]; then
        docker tag $image:$tag-latest $gpr-latest
        docker tag $image:$tag-latest $gpr
        docker push $gpr
        docker push $gpr-latest
fi
