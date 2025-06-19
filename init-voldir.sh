#!/bin/bash
# Script to init docker volumes directories

source .env

if [[ ! -d ${NC_VOL}  ]]; then
    mkdir -p ${NC_VOL}/var-lib-mysql
    mkdir -p ${NC_VOL}/nextcloud

    chmod -R 777 ${NC_VOL}

fi