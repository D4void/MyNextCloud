#!/bin/bash
# Script to make a dump of a Mariadb Nextcloud database running in a Docker container
# The dump is dropped via a volume mounted on /backup

source $(dirname $0)/.env

backupfile="${MARIADB_DATABASE}_dump_$(date +"%Y-%m-%d_%Hh%Mm%S").dump"

echo "Mise en maintenance Nextcloud"
docker exec nc-nextcloud php occ maintenance:mode --on

echo "Backuping Mariadb ${MARIADB_DATABASE} database"
#docker exec nc-db mariadb-dump -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} > /backup/${backupfile}

docker run --rm \
  --name mariadb-dump \
  --network MyNCnet \
  -e MYSQL_PWD=${MARIADB_PASSWORD} \
  mariadb:11.4-noble \
  sh -c "mariadb-dump -h nc-db -u ${MARIADB_USER} ${MARIADB_DATABASE}" \
  > backup/${backupfile}

echo "Fin maintenance Nextcloud"
docker exec nc-nextcloud php occ maintenance:mode --off


echo "End."
