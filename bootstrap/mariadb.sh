#!/usr/bin/env bash

# prepare for an unattended installation
export DEBIAN_FRONTEND=noninteractive

# var init
MARIADB_ROOT_PW=ArbIsKing
MARIADB_USER_NAME=vagrant
MARIADB_USER_PW=vagrant

# common stuff
apt-get update && apt-get upgrade -y 
apt-get install -y wget curl apache2 php5 libapache2-mod-php5 php5-mysql php5-curl software-properties-common python-software-properties vim logrotate memcached php5-memcached php-pear

# apache2 config
VHOST=$(cat <<EOF
<VirtualHost *:80>
  DocumentRoot "/vagrant"
  ServerName localhost
  <Directory "/vagrant">
    AllowOverride All
  </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-enabled/000-default
sudo a2enmod rewrite
service apache2 restart

# composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# mariadb - install
debconf-set-selections <<< "mariadb-server-5.5 mysql-server/root_password password $MARIADB_ROOT_PW"
debconf-set-selections <<< "mariadb-server-5.5 mysql-server/root_password_again password $MARIADB_ROOT_PW"
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
add-apt-repository 'deb http://ftp.nluug.nl/db/mariadb/repo/10.1/debian wheezy main'
apt-get update
apt-get install -y --allow-unauthenticated mariadb-server mariadb-client

# mariadb - config
if [ -f /vagrant/.mysql-passes ]
  then
    rm -f /vagrant/.mysql-passes
fi

echo "root:${MARIADB_ROOT_PW}" >> /vagrant/.mysql-passes
echo "$MARIADB_USER_NAME:${MARIADB_USER_PW}" >> /vagrant/.mysql-passes

mysql -uroot -p$MARIADB_ROOT_PW -e "CREATE USER '$MARIADB_USER_NAME'@'localhost' IDENTIFIED BY '$MARIADB_USER_PW'"

echo "MariaDB Root Passwords has been stored to .mysql-passes in your vagrant directory."
mysql -uroot -p$MARIADB_ROOT_PW -e "CREATE DATABASE Vagrant DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
mysql -uroot -p$MARIADB_ROOT_PW -e "CREATE DATABASE VagrantDev DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
mysql -uroot -p$MARIADB_ROOT_PW -e "GRANT ALL ON Vagrant.* TO '$MARIADB_USER_NAME'@'%';" mysql
mysql -uroot -p$MARIADB_ROOT_PW -e "GRANT ALL ON Vagrant.* TO '$MARIADB_USER_NAME'@'localhost';" mysql
mysql -uroot -p$MARIADB_ROOT_PW -e "GRANT ALL ON VagrantDev.* TO '$MARIADB_USER_NAME'@'%';" mysql
mysql -uroot -p$MARIADB_ROOT_PW -e "GRANT ALL ON VagrantDev.* TO '$MARIADB_USER_NAME'@'localhost';" mysql
echo "Created database"
mysql -uroot -p$MARIADB_ROOT_PW < /vagrant/bootstrap.sql
echo "Created schema from bootstrap.sql"
# make webroot symlink to vagrant dir
rm -rf /var/www
ln -fs /vagrant /var/www