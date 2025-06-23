#!/bin/bash
# Script to make a dump of a Mariadb Nextcloud database running in a Docker container

source $(dirname $0)/.env

backupfile="${MARIADB_DATABASE}_dump_$(date +"%Y-%m-%d_%Hh%Mm%S").dump"

echo "Begin Nextcloud maintenance"
docker exec nc-nextcloud php occ maintenance:mode --on

sleep 5

echo "Backuping Mariadb ${MARIADB_DATABASE} database"
docker run --rm \
  --name mariadb-dump \
  --network MyNCnet \
  -e MYSQL_PWD=${MARIADB_PASSWORD} \
  mariadb:11.4-noble \
  sh -c "mariadb-dump --single-transaction --default-character-set=utf8mb4 -h nc-db -u ${MARIADB_USER} ${MARIADB_DATABASE}" \
  > ${BKP_DIR}/${backupfile}


sleep 5

echo "End Nextcloud maintenance"
docker exec nc-nextcloud php occ maintenance:mode --off


echo "End."
