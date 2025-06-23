#!/bin/bash
# Script to backup Nextcloud data

source $(dirname $0)/.env

backupfile="nextcloud_$(date +"%Y-%m-%d_%Hh%Mm%S").tar.gz"

cd ${NC_VOL}

tar cfvz ${BKP_DIR}/${backupfile} data/ config/ custom_apps/

