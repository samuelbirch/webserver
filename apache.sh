#!/bin/bash

#------------------------------------------------------------------------------------
# Params
#------------------------------------------------------------------------------------


#------------------------------------------------------------------------------------
# Install packages
#------------------------------------------------------------------------------------

yum -y update
yum -y install epel-release
yum -y install wget gcc pcre-devel openssl-devel nano zlib-devel libxml2-devel automake libtool python-devel lua-devel

#------------------------------------------------------------------------------------
# Download & unzip sources
#------------------------------------------------------------------------------------

mkdir ~/sources
cd ~/sources

wget http://mirror.ox.ac.uk/sites/rsync.apache.org//httpd/httpd-2.4.23.tar.gz
tar -zxvf httpd-2.4.23.tar.gz

wget http://mirror.catn.com/pub/apache//apr/apr-1.5.2.tar.gz
tar -zxvf apr-1.5.2.tar.gz

wget http://mirror.catn.com/pub/apache//apr/apr-util-1.5.4.tar.gz
tar -zxvf apr-util-1.5.4.tar.gz

wget https://www.openssl.org/source/openssl-1.0.2h.tar.gz
tar -zxvf openssl-1.0.2h.tar.gz

wget https://github.com/nghttp2/nghttp2/releases/download/v1.14.0/nghttp2-1.14.0.tar.gz
tar -zxvf nghttp2-1.14.0.tar.gz

wget https://github.com/icing/mod_h2/releases/download/v1.6.1/mod_http2-1.6.1.tar.gz
tar -zxvf mod_http2-1.6.1.tar.gz

#------------------------------------------------------------------------------------
# Install openssl
#------------------------------------------------------------------------------------

cd ~/sources/openssl-1.0.2h
./config shared zlib-dynamic
make
make install

#------------------------------------------------------------------------------------
# Install http2
#------------------------------------------------------------------------------------

cd ~/sources/nghttp2-1.14.0
export OPENSSL_CFLAGS="-I/usr/local/ssl/include"
export OPENSSL_LIBS="-L/usr/local/ssl/lib -lssl -lcrypto"
./configure
make
make install

#------------------------------------------------------------------------------------
# Install apr
#------------------------------------------------------------------------------------

cd ~/sources/apr-1.5.2
./configure
make
make install

#------------------------------------------------------------------------------------
# Install apr-util
#------------------------------------------------------------------------------------

cd ~/sources/apr-util-1.5.4
./configure --with-apr=/usr/local/apr
make
make install

#------------------------------------------------------------------------------------
# Install apache
#------------------------------------------------------------------------------------

cd ~/sources/httpd-2.4.23
cp -r ../apr-1.5.2 srclib/apr
cp -r ../apr-util-1.5.4 srclib/apr-util
./configure --with-ssl=/usr/local/ssl --with-pcre=/usr/bin/pcre-config --enable-unique-id --enable-ssl --enable-so --with-included-apr --enable-http2 --with-mpm=event --enable-deflate --enable-proxy --enable-proxy-html --enable-http --enable-expires --enable-unique-id --enable-rewrite --enable-proxy-fcgi
make
make install

#------------------------------------------------------------------------------------
# update mod_http2
#------------------------------------------------------------------------------------

cd ~/sources/mod_http2-1.6.1
./configure --with-apxs=/usr/local/apache2/bin/apxs
make
make install

#------------------------------------------------------------------------------------
# update apache envvars
#------------------------------------------------------------------------------------

sed -i "s/\/usr\/local\/apache2\/lib/\/usr\/local\/apache2\/lib:\/usr\/local\/lib\/:\/usr\/local\/ssl\/lib/" /usr/local/apache2/bin/envvars


#------------------------------------------------------------------------------------
# create user & groups
#------------------------------------------------------------------------------------

groupadd www
useradd -G www -r apache
chown -R apache:www /usr/local/apache2

#------------------------------------------------------------------------------------
# make base directory
#------------------------------------------------------------------------------------

mkdir /var/www
mkdir /var/www/html
chown -R apache:www /var/www/html
chmod -R 775 /var/www/html

#------------------------------------------------------------------------------------
# update apache conf
#------------------------------------------------------------------------------------




