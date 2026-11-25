#!/bin/bash
set -e

# It creates the folder where mariaDB store it's sockcet (The socket helps it communicate with other containers)
mkdir -p /run/mysqld
# It gives permission to the user over mariaDB
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# It checks if the data base exists so that it is incialized only once
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    # It creates the data base tables
    mysql_install_db --user=mysql --datadir=/var/lib/mysql >/dev/null
    # It launchs MariaDB temporarily to configure it
    mysqld --user=mysql --skip-networking &
    pid=$!
    # It waits for the server to respond
    until mysqladmin ping --silent 2>/dev/null; do
        sleep 1
    done
    # It sends commands to the data base to create the wordpress user and gives permission to root, it also creates root password 
    # Le da permisos a sobre la base de datos y pone contraseña a root
    mysql -u root << EOSQL
CREATE DATABASE IF  NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF  NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOSQL
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait $pid
fi
# Launchs server
exec mysqld --user=mysql