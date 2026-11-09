#!/bin/bash
# Script to init docker volumes host directories, set uid/gid and rights
# 
# docker exec -it nc-nextcloud id www-data
# docker exec -it nc-db id mysql

source .env

if [[ ! -d ${NC_VOL}  ]]; then
    
    mkdir -p ${NC_VOL}/{var-lib-mysql,redis_data,data,config,app,custom_apps,backup,collabora/keys}
    chown -R 999:999 ${NC_VOL}/var-lib-mysql
    chown -R 999:1000 ${NC_VOL}/redis_data
    chown -R 33:33 ${NC_VOL}/{data,config,app,custom_apps}
    
    openssl genrsa -out ${NC_VOL}/collabora/keys/proof_key 4096
    openssl rsa -in ${NC_VOL}/collabora/keys/proof_key -pubout -out ${NC_VOL}/collabora/keys/proof_key.pub
    chown 1001:1001 ${NC_VOL}/collabora/keys/proof_key*
    chmod 600 ${NC_VOL}/collabora/keys/proof_key
    chmod 644 ${NC_VOL}/collabora/keys/proof_key.pub

    chmod -R 750 ${NC_VOL}/{data,config,app,custom_apps}
    chmod -R 700 ${NC_VOL}/{backup,var-lib-mysql,redis_data}
    chmod 755 ${NC_VOL}

fi