#!/bin/bash
MODE=$1
echo "Running under mode: $MODE"

echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)

echo "Starting wordpress with docker compose"
MODE=$MODE headsha=$headsha docker-compose up
