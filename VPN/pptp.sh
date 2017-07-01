#!/bin/sh
if [ `id -u` -ne 0 ]; then
    echo "please run it as super user"
    exit 0
fi

apt-get -y install pptpd || {
    apt-get -y update
    apt-get -y install pptpd
} || {
    echo "install pptpd failed"
    echo "Note: Ubuntu only"
    exit 1
}

cat >/etc/ppp/options.pptpd <<END
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
lock
nobsdcomp
novj
novjccomp
nologfd
END

cat >/etc/pptpd.conf <<END
option /etc/ppp/options.pptpd
logwtmp
localip 192.168.2.1
remoteip 192.168.2.10-100
END

cat >> /etc/sysctl.conf <<END
net.ipv4.ip_forward=1
END

sysctl -p

iptables-save > /etc/iptables.down.rules

iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -o eth0 -j MASQUERADE

iptables -I FORWARD -s 192.168.2.0/24 -p tcp --syn -i ppp+ -j TCPMSS --set-mss 1300

iptables-save > /etc/iptables.up.rules

cat >>/etc/ppp/pptpd-options<<EOF
pre-up iptables-restore < /etc/iptables.up.rules
post-down iptables-restore < /etc/iptables.down.rules
EOF

read -p "pptp username (default is test):" username
read -p "pptp password (default is test):" password
if [ -z "$username" ]; then
    username=test
fi
if [ -z "$password" ]; then
    password=test
fi

cat >/etc/ppp/chap-secrets <<END
$username pptpd $password *
END

service pptpd restart

echo "install success"
echo "username is $username, password is $password"
exit 0
