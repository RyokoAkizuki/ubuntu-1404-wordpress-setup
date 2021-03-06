#!/bin/bash

var_nodename=
var_rootdomain=

usage()
{
    echo "create_manager.sh [-n | --nodename] nodename [-r | --rootdomain] rootdomain"
}

if ! which linode ; then
    echo "deb http://apt.linode.com/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/linode.list
    wget -O- https://apt.linode.com/linode.gpg | sudo apt-key add -
    apt-get update
    apt-get -y install linode-cli
    linode configure
fi

while [ "$1" != "" ]; do
    case $1 in
        -r | --rootdomain )
            shift
            var_rootdomain=$1
        ;;
        -n | --nodename )
            shift
            var_nodename=$1
        ;;
        * )
            usage
            exit 1
        ;;
    esac
    shift
done

# check variables
if [ "$var_nodename" = "" ]; then
    usage
    exit 1
fi
if [ "$var_rootdomain" = "" ]; then
    usage
    exit 1
fi

var_managerdomain="$var_nodename.manager"

linode domain record-create $var_rootdomain A $var_managerdomain [remote_addr]

./create_ssl_site.sh -d $var_managerdomain.$var_rootdomain

cd /var/www/$var_managerdomain.$var_rootdomain/html
wget https://files.phpmyadmin.net/phpMyAdmin/4.5.5.1/phpMyAdmin-4.5.5.1-all-languages.tar.gz
tar xvzf phpMyAdmin-4.5.5.1-all-languages.tar.gz
mv phpMyAdmin-4.5.5.1-all-languages phpmyadmin
rm phpMyAdmin-4.5.5.1-all-languages.tar.gz
chown -R www-data:www-data /var/www/$var_managerdomain.$var_rootdomain
chmod -R 755 /var/www/$var_managerdomain.$var_rootdomain/html
