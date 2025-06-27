#!/bin/bash
# Script to restore Nextcloud
#   Restore Mariadb dump 
#   Restore Nextcloud data,config,custom_apps


source $(dirname $0)/.env

DUMP_PATH=$1
DUMP_FILE=$(basename "$DUMP_PATH")

echo "Stop Nextcloud"
docker stop nc-cron
docker stop nc-nextcloud

if [[ -f "$1" ]]; then
    read -p "Are you sure you want to restore ${MARIADB_DATABASE} with dump ${DUMP_PATH} ? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        
        sleep 3
        echo "Delete and create Nextcloud database"
        docker run --rm \
            --name mariadb \
            --network MyNCnet \
            -e MYSQL_PWD=${MARIADB_PASSWORD} \
            mariadb:11.4-noble \
            sh -c "mariadb -h nc-db -u ${MARIADB_USER} -e 'DROP DATABASE ${MARIADB_DATABASE}; \
                CREATE DATABASE ${MARIADB_DATABASE} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci' "

        echo "Restore backup $1 into Mariadb"
        docker run --rm \
            --name mariadb-dump \
            --network MyNCnet \
            --volume "$(dirname "$DUMP_PATH")":/backup \
            -e MYSQL_PWD=${MARIADB_PASSWORD} \
            mariadb:11.4-noble \
            sh -c "echo 'Dump dans /backup:'; ls -l /backup; echo 'Restore Mariadb dump'; \
                mariadb -h nc-db -u ${MARIADB_USER} ${MARIADB_DATABASE} < /backup/$DUMP_FILE "

    fi
else
    echo "$1 doesn't exist!"
    exit 1
fi

TAR_PATH=$2
TAR_FILE=$(basename "${TAR_PATH}")

if [[ -f "$2" ]]; then
    read -p "Are you sure you want to restore Nextcloud data/config/custom apps with ${TAR_PATH} ? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        
        sleep 3
        echo "Delete data,config,custom_apps directories"
        rm -rf ${NC_VOL}/{data,config,custom_apps}
        cd $(dirname "${TAR_PATH}")

        echo "Restore Nextcloud data,config,custom_apps"
        tar zxvf ${TAR_FILE} -C ${NC_VOL} > /dev/null

    fi
else
    echo "$2 doesn't exist!"
    exit 1
fi

echo "Start Nextcloud"
docker start nc-nextcloud
docker start nc-cron

echo "End Nextcloud maintenance"
docker exec nc-nextcloud php occ maintenance:mode --off

echo "Restore success. End."
