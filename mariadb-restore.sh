#!/bin/bash
# Script to restore a dump of a Mariadb Nextcloud database running in a docker container


source $(dirname $0)/.env

if [[ -f "$1" ]]; then
    read -p "Are you sure you want to restore ${MARIADB_DATABASE} with dump $1 ? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "Begin Nextcloud maintenance"
        docker exec nc-nextcloud php occ maintenance:mode --on

        sleep 5

        echo "Delete and create Nextcloud database"
        docker run --rm \
            --name mariadb \
            --network MyNCnet \
            -e MYSQL_PWD=${MARIADB_PASSWORD} \
            mariadb:11.4-noble \
            sh -c "mariadb -h nc-db -u ${MARIADB_USER} -e 'DROP DATABASE ${MARIADB_DATABASE}; \
                CREATE DATABASE ${MARIADB_DATABASE} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci' "

        echo "Restoring backup $1 into Mariadb"
        docker run --rm \
            --name mariadb-dump \
            --network MyNCnet \
            -- volume $1:/backup/$1
            -e MYSQL_PWD=${MARIADB_PASSWORD} \
            mariadb:11.4-noble \
            sh -c "mariadb -h nc-db -u ${MARIADB_USER} ${MARIADB_DATABASE} < /backup/$1"

        echo "End Nextcloud maintenance"
        docker exec nc-nextcloud php occ maintenance:mode --off

    fi
else
    echo "$1 doesn't exist!"
fi

echo "End."
