#!/bin/bash
# Script to restore a dump of a Mariadb Nextcloud database running in a docker container


source $(dirname $0)/.env

DUMP_PATH=$1
DUMP_FILE=$(basename "$DUMP_PATH")

if [[ -f "$1" ]]; then
    read -p "Are you sure you want to restore ${MARIADB_DATABASE} with dump ${DUMP_PATH} ? " -n 1 -r
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
            --volume "$(dirname "$DUMP_PATH")":/backup \
            -e MYSQL_PWD=${MARIADB_PASSWORD} \
            mariadb:11.4-noble \
            sh -c "echo 'Dump dans /backup:'; ls -l /backup; echo 'Restore Mariadb dump'; mariadb -h nc-db -u ${MARIADB_USER} ${MARIADB_DATABASE} < /backup/$DUMP_FILE "

        echo "End Nextcloud maintenance"
        docker exec nc-nextcloud php occ maintenance:mode --off

    fi
else
    echo "$1 doesn't exist!"
fi

echo "End."
