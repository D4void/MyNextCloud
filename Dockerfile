# Dockerfile pour créer une image Nextcloud apache avec samba-client et le module php smbclient
#
# docker build --build-arg NEXTCLOUD_TAG=${NEXTCLOUD_TAG} -t d4void/nextcloud:${NEXTCLOUD_TAG} .

ARG NEXTCLOUD_TAG=latest
FROM nextcloud:${NEXTCLOUD_TAG}

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends procps smbclient libsmbclient-dev; \
    rm -rf /var/lib/apt/lists/*; \
    pecl install smbclient; \
    docker-php-ext-enable smbclient; \
    rm -rf /tmp/pear/