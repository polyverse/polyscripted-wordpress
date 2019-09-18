echo "Running under mode: $MODE"

echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)
#headsha=73c14657d70afae3b87de99d263eb3e87e2f681a

echo "Starting wordpress with docker compose"
headsha=$headsha MODE=$1 docker-compose up
