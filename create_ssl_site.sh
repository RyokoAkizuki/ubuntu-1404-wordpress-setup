#!/bin/bash

var_domain=
var_alias=
var_admin=

usage()
{
    echo "create_ssl_site.sh [-d | --domain] sitedomain ([-a | --alias] alias | \"alias1 alias2 ...\")"
    echo "([-m | --mail] adminmail) | [-r | --remove] sitedomain"
}

remove()
{
    a2dissite $var_domain
    rm /etc/apache2/sites-available/$var_domain.conf
    rm -r /var/www/$var_domain
    service apache2 reload
    echo "site $var_domain is removed"
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while [ "$1" != "" ]; do
    case $1 in
        -d | --domain )
            shift # pop out current parameter
            var_domain=$1
        ;;
        -a | --alias )
            shift
            var_alias=$1
        ;;
        -m | --mail )
            shift
            var_admin=$1
        ;;
        -r | --remove )
            shift
            var_domain=$1
            remove
            exit 0
        ;;
        * )
            usage
            exit 1
        ;;
    esac
    shift
done

# check variables
if [ "$var_domain" = "" ]; then
    usage
    exit 1
fi

mkdir /var/www/$var_domain
mkdir /var/www/$var_domain/html
mkdir /var/www/$var_domain/log

cat <<EOF > /etc/apache2/sites-available/$var_domain.conf
<VirtualHost *:80>
    ServerName $var_domain
EOF
if [ ! "$var_alias" = "" ]; then
    echo "    ServerAlias $var_alias" >> /etc/apache2/sites-available/$var_domain.conf
fi
if [ ! "$var_admin" = "" ]; then
    echo "    ServerAdmin $var_admin" >> /etc/apache2/sites-available/$var_domain.conf
fi
cat <<EOF >> /etc/apache2/sites-available/$var_domain.conf
    DocumentRoot /var/www/$var_domain/html

    <Directory /var/www/$var_domain/html>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/www/$var_domain/log/error.log
    CustomLog /var/www/$var_domain/log/access.log combined
</VirtualHost>
EOF

chown -R www-data:www-data /var/www/$var_domain
chmod -R 755 /var/www/$var_domain/html

a2ensite $var_domain

if ! git --version ; then
    apt-get update
    apt-get -y install git
fi

if cd /opt/letsencrypt ; then
    git pull
else
    git clone https://github.com/letsencrypt/letsencrypt.git /opt/letsencrypt
    cd /opt/letsencrypt
fi

./letsencrypt-auto --agree-tos --redirect --apache -d $var_domain # todo: alias

service apache2 reload
