#!/bin/bash

set -e

cd var/www/html

# Espera a que MariaDB acepte conexiones
until mysqladmin ping -h mariadb -u "${MTSQL_USER}" -p "${MYSQL_PASSWORD}" --silent 2>/dev/null; do
    echo "esperando MariaDB"
    sleep 2
done

# Solo instala wordpress la primera vez que se jecuta este archivo
if[ ! -f wp-config.php]; then
    wp core download --allow-root

    wp config create --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbupass="${MYSQL_PASSWORD}" \
        --dbhost=mariadb

    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_pasword="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"
    
    wp user create --allow-root \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass = "${WP_USER_PASSWORD}" \
        --role=author

    chown -R www-data:www-data /var/www/gtml
fi

mkdir -p /run/php

# Proceso principal (PID 1)
# -F mantiene php en el primer plano y usamos 8.2 porque es el que trae bookworm.
exec php-fpm8.2 -F