#!/bin/bash
# Script to launch the docker image build 

source .env

# Check NEXTCLOUD_TAG is defined 
if [ -z "${NEXTCLOUD_TAG}" ]; then
  echo "Error : NEXTCLOUD_TAG variable is not defined in .env file"
  exit 1
fi

echo "Build Nextcloud image with tag : ${NEXTCLOUD_TAG}"
docker build --build-arg NEXTCLOUD_TAG="${NEXTCLOUD_TAG}" -t d4void/nextcloud:"${NEXTCLOUD_TAG}" .

# Push the Docker image to Docker Hub
docker push "d4void/nextcloud:${NEXTCLOUD_TAG}"