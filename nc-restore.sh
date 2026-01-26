#!/bin/bash
# Script to restore Nextcloud
#   Restore Mariadb dump 
#   Restore Nextcloud data,config,custom_apps
#
# Depends on: plakar-restore.sh (to restore Nextcloud data/config/custom_apps from plakar snapshot)
#

source $(dirname $0)/.env

# Vérification des paramètres
if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 <dump_file_path> <data_directory_path>"
    echo ""
    echo "Expected parameters:"
    echo "  First parameter:  Full path to the MariaDB dump file"
    echo "  Second parameter: Path to a directory containing the Nextcloud data folders (data, config, custom_apps)"
    exit 1
fi

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

DATA_PATH=$2

if [[ -d "$2" ]]; then
    # Verify that required subdirectories exist
    if [[ ! -d "${DATA_PATH}/data" ]] || [[ ! -d "${DATA_PATH}/config" ]] || [[ ! -d "${DATA_PATH}/custom_apps" ]]; then
        echo "Error: ${DATA_PATH} must contain 'data', 'config', and 'custom_apps' directories"
        exit 1
    fi

    # Be sure we have the right ownership and permissions
    chown 33:33 ${DATA_PATH}/{data,config,app,custom_apps}
    chmod 750 ${DATA_PATH}/{data,config,app,custom_apps}
    
    read -p "Are you sure you want to restore Nextcloud data/config/custom apps with the ones in ${DATA_PATH} ? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        
        sleep 3
        echo "Rename existing data,config,custom_apps directories to .old"
        rm -rf ${NC_VOL}/{data.old,config.old,custom_apps.old}
        [[ -d ${NC_VOL}/data ]] && mv ${NC_VOL}/data ${NC_VOL}/data.old
        [[ -d ${NC_VOL}/config ]] && mv ${NC_VOL}/config ${NC_VOL}/config.old
        [[ -d ${NC_VOL}/custom_apps ]] && mv ${NC_VOL}/custom_apps ${NC_VOL}/custom_apps.old
        cd $(dirname "${DATA_PATH}")

        echo "Restore Nextcloud data,config,custom_apps"
        mv ${DATA_PATH}/{data,config,custom_apps} ${NC_VOL} > /dev/null

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
