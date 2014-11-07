#!/usr/bin/env bash

# var init
MARIADB_ROOT_PW=ArbIsKing
MARIADB_VAGRANT_PW=vagrant

# install
debconf-set-selections <<< "mariadb-server-5.5 mysql-server/root_password password $MARIADB_ROOT_PW"
debconf-set-selections <<< "mariadb-server-5.5 mysql-server/root_password_again password $MARIADB_ROOT_PW"
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
add-apt-repository 'deb http://ftp.nluug.nl/db/mariadb/repo/10.1/debian wheezy main'
apt-get update
apt-get install -y --allow-unauthenticated mariadb-server mariadb-client

# config
if [ -f /vagrant/.mysql-passes ]
  then
    rm -f /vagrant/.mysql-passes
fi

echo "root:${MARIADB_ROOT_PW}" >> /vagrant/.mysql-passes
echo "vagrant:${MARIADB_VAGRANT_PW}" >> /vagrant/.mysql-passes

mysql -uroot -p$MARIADB_ROOT_PW -e "CREATE USER 'vagrant'@'localhost' IDENTIFIED BY '$MARIADB_VAGRANT_PW'"

echo "MariaDB Root Passwords has been stored to .mysql-passes in your vagrant directory."
mysql -uroot -p$MARIADB_ROOT_PW -e "CREATE DATABASE vagrant DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
mysql -uroot -p$MARIADB_ROOT_PW -e "GRANT ALL ON vagrant TO 'vagrant'@'localhost';" mysql

