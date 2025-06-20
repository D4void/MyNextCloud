#!/bin/bash
# Script to restore a dump of a Mariadb Nextcloud database running in a docker container
# The dump is accessible via the volume mounted on /backup

source $(dirname $0)/.env

if [[ -f "$1" ]]; then
    read -p "Are you sure you want to restore ${MARIADB_DATABASE} with dump $1 ? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        #echo "Mise en maintenance Nextcloud"
        #

        echo "Restoring backup $1 into Mariadb"
        docker exec nc-db mariadb-dump -u ${MARIADB_USER} -p {MARIADB_PASSWORD} ${MARIADB_DATABASE} < /backup/$1

        #echo "Fin maintenance Nextcloud"
        #

    fi
else
    echo "$1 doesn't exist!"
fi

echo "End."