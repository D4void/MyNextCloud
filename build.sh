#!/bin/bash
# Script to launch the docker image build 

source .env

# Vérifier que NEXTCLOUD_TAG est bien défini
if [ -z "$NEXTCLOUD_TAG" ]; then
  echo "Erreur : la variable NEXTCLOUD_TAG n'est pas définie dans le fichier .env"
  exit 1
fi

echo "Build de l'image nextcloud avec tag : $NEXTCLOUD_TAG"
docker build --build-arg NEXTCLOUD_TAG="$NEXTCLOUD_TAG" -t d4void/nextcloud:"$NEXTCLOUD_TAG" .
