#!/usr/bin/env bash
set -e

CONTAINER_NAME="burstcoin-simple-plotter"
IMAGE_NAME="burstcoin-simple-plotter-docker"

echo "Building image."
docker build --tag "$IMAGE_NAME" .

echo "Stopping and removing existing container"
docker ps -a --filter "name=$CONTAINER_NAME" --format "{{.ID}}" | xargs -r docker rm -f
