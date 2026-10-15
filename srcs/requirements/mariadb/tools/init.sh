#!/bin/bash
set -e

# Crea la carpeta donde MariaDB guarda su socket 
# (que es lo que le ayuda a comuncarse  con otros contenedores)
mkdir -p /run/mysqld
# Da permisos al usuario mysql sobre MariaDB
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Comprueba si la base de datos existe para que solo inicialice una vez
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    # Crea todas las tablas de datos internas del sistema
    mysql_install_db --user=mysql --datadir=/var/lib/mysql >/dev/null
    # Arranca MariaDB temporalmente para poder configurarlo
    mysqld --user=mysql --skip-networking &
    pid=$!
    # Espera hasta que el servidor responda
    until mysqladmin ping --silent 2>/dev/null; do
        sleep 1
    done
    # Envia comandos a la base de datos, crea el usuario wordpress
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
# Arranca el servidor definitivo
exec mysqld --user=mysql