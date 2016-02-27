#!/bin/sh

SERVER_ADMIN = "user@example.com"
SERVER_NAME = "www.example.com"
SERVER_ALIAS = "example.com"

sed -i "s/SERVER_ADMIN_PLACEHOLDER/$SERVER_ADMIN/g" target-sslsite.conf
sed -i "s/SERVER_NAME_PLACEHOLDER/$SERVER_NAME/g" target-sslsite.conf
sed -i "s/SERVER_ALIAS_PLACEHOLDER/$SERVER_ALIAS/g" target-sslsite.conf

# install LAMP stack
apt-get update
apt-get -y install apache2 mysql-server libapache2-mod-auth-mysql php5-mysql php5 libapache2-mod-php5 php5-mcrypt

mysql_install_db
# secure mysql
/usr/bin/mysql_secure_installation

# enable mod_rewrite for apache
a2enmod rewrite

# update index page search order
cat << EOT > /etc/apache2/mods-enabled/dir.conf
<IfModule mod_dir.c>
    DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
</IfModule>
EOT

# update apache config
cp ./target-apache2.conf /etc/apache2/apache2.conf
cp ./target-sslsite.conf /etc/apache2/sites-enabled/sslsite.conf

apt-get -y install git
cd ~
git clone https://github.com/letsencrypt/letsencrypt.git
cd letsencrypt
./letsencrypt-auto

apt-get -y install p7zip-full 
cd /var/www/html
wget https://wordpress.org/latest.zip
7z x latest.zip
mv ./wordpress/* ./
rmdir wordpress
rm latest.zip

chown -R www-data:www-data /var/www/html

service apache2 restart

# mysql --user=root --password=
# CREATE DATABASE ;
