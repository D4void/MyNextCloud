#!/bin/bash
# Script to backup Nextcloud
#   make a dump of a Mariadb Nextcloud database running in a Docker container
#   make an archive of nextcloud data

source $(dirname $0)/.env

TEMPDIR="Backup-MyNextcloud-$(date +'%Y-%m-%d_%Hh%Mm%S')"
BACKUPDUMPFILE="${MARIADB_DATABASE}_dump_$(date +'%Y-%m-%d_%Hh%Mm%S').dump"

mkdir ${BKP_DIR}/${TEMPDIR}


echo "Begin Nextcloud maintenance"
docker exec nc-nextcloud php occ maintenance:mode --on

sleep 3

# Dump Mariadb

echo "Backuping Mariadb ${MARIADB_DATABASE} database"
docker run --rm \
  --name mariadb-dump \
  --network MyNCnet \
  -e MYSQL_PWD=${MARIADB_PASSWORD} \
  mariadb:11.4-noble \
  sh -c "mariadb-dump --single-transaction --default-character-set=utf8mb4 -h nc-db -u ${MARIADB_USER} ${MARIADB_DATABASE}" \
  > ${BKP_DIR}/${TEMPDIR}/${BACKUPDUMPFILE}


# Archive des données Nextcloud

echo "Backuping Nextcloud data,config,custom_apps"
BACKUPDATAFILE="nextcloud_data_$(date +"%Y-%m-%d_%Hh%Mm%S").tar.gz"
cd ${NC_VOL}
tar cfvz ${BKP_DIR}/${TEMPDIR}/${BACKUPDATAFILE} data/ config/ custom_apps/ > /dev/null

echo "End Nextcloud maintenance"
docker exec nc-nextcloud php occ maintenance:mode --off

chmod ugo+rwx ${BKP_DIR}/${TEMPDIR}/
chmod ugo+rw ${BKP_DIR}/${TEMPDIR}/*

echo "Backup success. End."
