#!/bin/bash

set -e

cd /var/www/html

# Waits for mariaDb to accept connections
until mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent 2>/dev/null; do
    echo "esperando MariaDB"
    sleep 2
done

# Installs wordpress only the first time this file is executed
if [ ! -f wp-config.php ]; then
    wp core download --allow-root

    wp config create --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost=mariadb

    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"
    
    wp user create --allow-root \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author

    chown -R www-data:www-data /var/www/html
fi

mkdir -p /run/php

# Main process (PID 1)
# -F keep php in foreground mode and we use 8.2 version because is the one that comes by default in debian bookworm.
exec php-fpm8.2 -F