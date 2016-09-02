#!/bin/bash

#------------------------------------------------------------------------------------
# Vars
#------------------------------------------------------------------------------------

php=7.0.10

#------------------------------------------------------------------------------------
# Install packages
#------------------------------------------------------------------------------------

yum -y install bzip2-devel curl-devel libjpeg-devel libpng-devel freetype-devel libc-client-devel.i686 libc-client-devel libmcrypt-devel

#------------------------------------------------------------------------------------
# download source
#------------------------------------------------------------------------------------

cd ~/sources
wget -O php-$php.tar.gz http://uk1.php.net/get/php-$php.tar.gz/from/this/mirror
tar -zxvf php-$php.tar.gz
cd ~/sources/php-$php

#------------------------------------------------------------------------------------
# Install php
#------------------------------------------------------------------------------------

./configure --prefix=/usr/local/php --enable-fpm --enable-mbstring --enable-zip --enable-bcmath --enable-ftp --enable-exif --enable-sysvmsg --enable-sysvsem --enable-sysvshm --with-curl --with-mcrypt --with-gd --with-jpeg-dir --with-png-dir --with-zlib-dir --with-freetype-dir --enable-gd-native-ttf --with-openssl --with-pdo-mysql --with-zlib --with-bz2 --with-mysqli --enable-soap --with-xmlrpc --with-kerberos --enable-sockets --with-pcre-regex --enable-calendar --with-imap-ssl --with-mhash --enable-mysqlnd --enable-inline-optimization --enable-mbregex --enable-opcache --with-iconv --with-mysql-sock=/var/lib/mysql/mysql.sock 

make
make install

#------------------------------------------------------------------------------------
# config
#------------------------------------------------------------------------------------

cd /usr/local/php/etc
cp php-fpm.conf.default php-fpm.conf













#------------------------------------------------------------------------------------
# ImageMagick
#------------------------------------------------------------------------------------

yum install php-pear
yum install ImageMagick ImageMagick-devel
pecl install imagick

echo 'extension=imagick.so' >> /usr/local/php/lib/php.ini