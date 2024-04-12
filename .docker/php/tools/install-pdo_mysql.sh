#!/bin/sh

set -ex

apk add --no-cache --virtual .build-deps $PHPIZE_DEPS oniguruma-dev
docker-php-ext-install pdo pdo_mysql
apk add --no-cache mariadb-client=${MYSQL_VERSION}
apk del -f .build-deps