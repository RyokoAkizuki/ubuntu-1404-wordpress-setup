#!/bin/bash

usage()
{
    echo "install_lamp_stack.sh [-p | --password] mysql_password"
}

mysql_password=

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while [ "$1" != "" ]; do
    case $1 in
        -p | --password )
            shift # pop out current parameter
            mysql_password=$1
        ;;
        * )
            usage
            exit 1
        ;;
    esac
    shift
done

apt-get update

# the general structure of this script is based on:
# https://www.howtoforge.com/tutorial/install-apache-with-php-and-mysql-on-ubuntu-lamp/
# http://www.liberiangeek.net/2015/10/installing-the-lamp-stack-on-ubuntu-15-10-server/

# http://stackoverflow.com/questions/6212219/passing-parameters-to-a-bash-function
# Automating mysql_secure_installation: https://gist.github.com/Mins/4602864
secure_mysql()
{
    mysql --user=root --password=$mysql_password <<EOF
    UPDATE mysql.user SET Password=PASSWORD('$mysql_password') WHERE User='root';
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
    DELETE FROM mysql.user WHERE User='';
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
    FLUSH PRIVILEGES;
EOF
}

apt-get -y install apache2
systemctl start apache2
systemctl enable apache2

# install mysql
# http://stackoverflow.com/questions/7739645/install-mysql-on-ubuntu-without-password-prompt
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysql_password"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysql_password"
apt-get -y install mysql-server mysql-client
secure_mysql
systemctl start mysql
systemctl enable mysql

# install php
apt-get -y install php7.0 php7.0-mysql libapache2-mod-php7.0 php-apcu

# enable ssl for apache
a2enmod ssl
# enable mod_rewrite for apache
a2enmod rewrite

# update index page search order
cat <<EOF > /etc/apache2/mods-enabled/dir.conf
<IfModule mod_dir.c>
    DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
</IfModule>
EOF

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# disable default site
a2dissite 000-default.conf
systemctl restart apache2

# systemctl status apache2
# systemctl status mysql
