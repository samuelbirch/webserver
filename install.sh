#!/bin/bash

#------------------------------------------------------------------------------------
# Params
#------------------------------------------------------------------------------------

echo -e "What is the server name: \c "
read serverName

echo -e "What is the admin email: \c "
read adminEmail

echo -e "What is the default user: \c "
read USER

#------------------------------------------------------------------------------------
# Vars
#------------------------------------------------------------------------------------

MYSQL_DEFAULT_PASS=a

#------------------------------------------------------------------------------------
# Setup
#------------------------------------------------------------------------------------

yum -y update
yum -y install wget

[ ! -d ~/scripts  ] && mkdir ~/scripts

cd ~/scripts

#------------------------------------------------------------------------------------
# Install apache
#------------------------------------------------------------------------------------

wget https://raw.githubusercontent.com/samuelbirch/webserver/master/apache.sh
#chmod +x apache.sh
#./apache.sh
bash apache.sh $serverName $adminEmail

#------------------------------------------------------------------------------------
# Install php
#------------------------------------------------------------------------------------

wget https://raw.githubusercontent.com/samuelbirch/webserver/master/php.sh
#chmod +x php.sh
#./php.sh
bash php.sh

#------------------------------------------------------------------------------------
# Install db
#------------------------------------------------------------------------------------

wget https://raw.githubusercontent.com/samuelbirch/webserver/master/db.sh
#chmod +x db.sh
#./db.sh
MYSQL_DEFAULT_PASS=$(bash db.sh $USER)


echo "All done! Your MYSQL password is $MYSQL_DEFAULT_PASS"