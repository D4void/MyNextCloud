#!/bin/bash
# Script to backup Nextcloud
#   make a dump of a Mariadb Nextcloud database running in a Docker container
#   make a plakar snapshot of nextcloud data and mariadb dump
# 
# Ref
# https://plakar.io/
# https://github.com/D4void/plakarbackup.git


source $(dirname $0)/.env

PLAKAR=/usr/local/bin/plakarbackup.sh

# Check if plakar script exists
if [[ ! -f "$PLAKAR" ]]; then
    echo "Error: plakar script not found at ${PLAKAR}"
    echo "Please install plakar or update the PLAKAR variable with the correct path"
    exit 1
fi

TEMPDIR="Mariadb-dump-$(date +'%Y-%m-%d_%Hh%Mm%S')"
BACKUPDUMPFILE="${MARIADB_DATABASE}_dump_$(date +'%Y-%m-%d_%Hh%Mm%S').dump"

mkdir ${BKP_DIR}/${TEMPDIR}
LOGFILE="${BKP_DIR}/${TEMPDIR}/$(basename "$0" .sh)-$(date '+%Y_%m_%d-%Hh%M').log"


############################################################
# FUNCTIONS
############################################################

__error() {
	__log "$1"
	set +o pipefail
	exit 1
}

__log() {
	echo $(date '+%Y/%m/%d-%Hh%Mm%Ss:') "$1" | tee -a $LOGFILE
}

############################################################
# MAIN
############################################################
set -o pipefail 1

__log "Begin Nextcloud maintenance"
docker exec nc-nextcloud php occ maintenance:mode --on
if [[ $? -ne 0 ]]; then
	__error "/!\\ Error setting maintenance." 1
fi

sleep 3

# Dump Mariadb
__log "Dump Mariadb ${MARIADB_DATABASE} database to ${BKP_DIR}/${TEMPDIR}/${BACKUPDUMPFILE}"
docker run --rm \
  --name mariadb-dump \
  --network MyNCnet \
  -e MYSQL_PWD=${MARIADB_PASSWORD} \
  mariadb:${MARIA_TAG} \
  sh -c "mariadb-dump --single-transaction --default-character-set=utf8mb4 -h nc-db -u ${MARIADB_USER} ${MARIADB_DATABASE}" \
  > ${BKP_DIR}/${TEMPDIR}/${BACKUPDUMPFILE}
if [[ $? -ne 0 ]]; then
	__error "/!\\ Mariadb dump error." 1
fi

# Plakar snapshot Nextcloud data, config, custom_apps and mariadb dump
__log "Make a Plakar snapshot Nextcloud data and mariadb dump to ${REPONAME}"
$PLAKAR ${OPTS:-} ${REPONAME} ${BKP_DIR}/${TEMPDIR} ${NC_VOL}/data ${NC_VOL}/config ${NC_VOL}/custom_apps
rm -rf ${BKP_DIR}/${TEMPDIR}/*.dump

__log "End Nextcloud maintenance"
docker exec nc-nextcloud php occ maintenance:mode --off
if [[ $? -ne 0 ]]; then
	__error "/!\\ Remove maintenance error." 1
fi

set +o pipefail
rm -rf ${BKP_DIR}/*
exit 0
