#!/bin/bash

#------------------------------------------------------------------------------------
# Params
#------------------------------------------------------------------------------------

MYSQL_USER=$1
if [ -z ${MYSQL_USER+x} ]; then
	echo -e "What is the default MYSQL user: \c "
	read MYSQL_USER
fi

touch ~/.rnd
set RANDFILE=~/.rnd

ROOT_PASSWORD=$(openssl rand -base64 16)
DEFAULT_PASSWORD=$(openssl rand -base64 16)

#------------------------------------------------------------------------------------
# Install
#------------------------------------------------------------------------------------

yum -y install mariadb-server mariadb
service mariadb start

#------------------------------------------------------------------------------------
# auto secure install
#------------------------------------------------------------------------------------

echo -e "\n\n$ROOT_PASSWORD\n$ROOT_PASSWORD\n\n\nn\n\n " | mysql_secure_installation 2>/dev/null

#------------------------------------------------------------------------------------
# add login so loot doesn't have too remember password
#------------------------------------------------------------------------------------

echo "[client]
user=root
password=$ROOT_PASSWORD" > ~/.my.cnf


#------------------------------------------------------------------------------------
# Create default user
#------------------------------------------------------------------------------------

mysql << EOF
GRANT ALL ON *.* TO "$MYSQL_USER"@'%' IDENTIFIED BY "$DEFAULT_PASSWORD";
FLUSH PRIVILEGES;
EOF
exit

#echo 'You password for user $MYSQL_USER is $DEFAULT_PASSWORD'

chkconfig mariadb on

echo $DEFAULT_PASSWORD