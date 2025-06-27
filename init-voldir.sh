#!/bin/bash
# Script to init docker volumes host directories, set uid/gid and rights
# 
# docker exec -it nc-nextcloud id www-data
# docker exec -it nc-db id mysql

source .env

if [[ ! -d ${NC_VOL}  ]]; then
    
    mkdir -p ${NC_VOL}/{var-lib-mysql,data,config,app,custom_apps,backup}
    chown -R 999:999 ${NC_VOL}/var-lib-mysql
    chown -R 33:33 ${NC_VOL}/{data,config,app,custom_apps}

    chmod -R 750 ${NC_VOL}/{data,config,app,custom_apps}
    chmod -R 777 ${NC_VOL}/backup
    chmod -R 700 ${NC_VOL}/var-lib-mysql
    chmod 755 ${NC_VOL}

fi