#!/bin/sh
if [ `id -u` -ne 0 ]; then
    echo "please run it as super user"
    exit 0
fi

# set PKM (package manager)
if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
    PKM="yum"
elif  grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
    PKM="apt-get"
elif  grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
    PKM="apt-get"
else
    echo "This Script must be running at the CentOS or Ubuntu or Debian!"
    exit 1
fi

echo "Installing pip with $PKM ..."

$PKM update
$PKM -y install python-pip && pip install shadowsocks || {
    echo "install shadowsocks failed"
    exit 1
}

read -p "shadowsocks port (default is 8388):" port
read -p "shadowsocks password (default is password):" password
if [ -z "$port" ]; then
    port=8388
fi
if [ -z "$password" ]; then
    password="password"
fi

cat >/etc/shadowsocks.json <<END
{
    "server":"::",
    "server_port":$port,
    "local_port":1080,
    "password":"$password",
    "timeout":600,
    "method":"aes-256-cfb"
}
END

ssserver -c /etc/shadowsocks.json -d start

cat >>/etc/rc.local <<END
ssserver -c /etc/shadowsocks.json -d start
END

echo "install success"
echo "port is $port, password is $password"
exit 0
