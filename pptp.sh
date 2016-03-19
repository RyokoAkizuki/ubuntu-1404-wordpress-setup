#!/bin/bash

var_username=
var_password=

usage()
{
    echo "pptp.sh [-i | --install] | [-a | --adduser] username password | [-r | --removeuser] username | [-g | --getuser] username"
}

install_pptp()
{
    apt-get update
    apt-get -y install pptpd

    echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
    sysctl -p

    echo localip 192.168.0.1 >> /etc/pptpd.conf
    echo remoteip 192.168.0.234-238,192.168.0.245 >> /etc/pptpd.conf

    echo ms-dns 8.8.8.8 >> /etc/ppp/pptpd-options
    echo ms-dns 8.8.4.4 >> /etc/ppp/pptpd-options

    # http://askubuntu.com/questions/621820/pptpd-failed-after-upgrading-ubuntu-server-to-15
    sed -i 's/^logwtmp\d*/#&/g' /etc/pptpd.conf
    
    iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o eth0 -j MASQUERADE
    iptables -A FORWARD -p tcp --syn -s 192.168.0.0/24 -j TCPMSS --set-mss 1356

    perl -plne 'print "iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o eth0 -j MASQUERADE\niptables -A FORWARD -p tcp --syn -s 192.168.0.0/24 -j TCPMSS --set-mss 1356" if(/^exit 0$/);' /etc/rc.local > temp.rc.local
    mv temp.rc.local /etc/rc.local
    chmod +x /etc/rc.local

    systemctl enable pptpd
    systemctl restart pptpd
}

add_user()
{
    if [ "$var_username" = "" ]; then
        echo "username may not be empty"
        exit 1
    fi
    if [ "$var_password" = "" ]; then
        echo "password may not be empty"
        exit 1
    fi
    echo "$var_username pptpd $var_password *" >> /etc/ppp/chap-secrets
    echo "user added: $var_username:$var_password"
}

remove_user()
{
    if [ "$var_username" = "" ]; then
        echo "username may not be empty"
        exit 1
    fi
    sed -i "/^$var_username /d" /etc/ppp/chap-secrets
}

get_user()
{
    if [ "$var_username" = "" ]; then
        echo "username may not be empty"
        exit 1
    fi
    grep "^$var_username " /etc/ppp/chap-secrets
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while [ "$1" != "" ]; do
    case $1 in
        -i | --install )
            install_pptp
        ;;
        -a | --adduser )
            shift
            var_username=$1
            shift
            var_password=$1
            add_user
            exit 0
        ;;
        -r | --removeuser )
            shift
            var_username=$1
            remove_user
            exit 0
        ;;
        -g | --getuser )
            shift
            var_username=$1
            get_user
            exit 0
        ;;
        * )
            usage
            exit 1
        ;;
    esac
    shift
done
