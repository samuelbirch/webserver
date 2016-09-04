#!/bin/bash

#------------------------------------------------------------------------------------
# Vars
#------------------------------------------------------------------------------------

php=7.0.10

#------------------------------------------------------------------------------------
# Install packages
#------------------------------------------------------------------------------------

yum -y install bzip2-devel curl-devel libjpeg-devel libpng-devel freetype-devel libc-client-devel.i686 libc-client-devel libmcrypt-devel openssl-devel

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

./configure --prefix=/usr/local/php --enable-fpm --enable-mbstring --enable-zip --enable-bcmath --enable-ftp --enable-exif --enable-sysvmsg --enable-sysvsem --enable-sysvshm --with-curl --with-mcrypt --with-gd --with-jpeg-dir --with-png-dir --with-zlib-dir --with-freetype-dir --enable-gd-native-ttf --with-pdo-mysql --with-zlib --with-bz2 --with-mysqli --enable-soap --with-xmlrpc --with-kerberos --enable-sockets --with-pcre-regex --enable-calendar --with-imap-ssl --with-mhash --enable-mysqlnd --enable-inline-optimization --enable-mbregex --enable-opcache --with-iconv --with-mysql-sock=/var/lib/mysql/mysql.sock 

make
make install

#------------------------------------------------------------------------------------
# config
#------------------------------------------------------------------------------------

cd /usr/local/php/etc
cp php-fpm.conf.default php-fpm.conf

sed -i "s/^;pid = run\/php-fpm.pid/pid = \/var\/run\/php-fpm.pid/g" /usr/local/php/etc/php-fpm.conf
sed -i "/error_log = /s/^;//g" /usr/local/php/etc/php-fpm.conf


cd php-fpm.d
cp www.conf.default www.conf

sed -i "s/^user = nobody/user = apache/g" /usr/local/php/etc/php-fpm.d/www.conf
sed -i "s/^group = nobody/group = www/g" /usr/local/php/etc/php-fpm.d/www.conf

sed -i "s/^;slowlog.*/slowlog = \/var\/www\/html\/logs\/php-fpm.slow.log/g" /usr/local/php/etc/php-fpm.d/www.conf
sed -i "s/^;request_slowlog_timeout.*/request_slowlog_timeout = 30s/g" /usr/local/php/etc/php-fpm.d/www.conf
sed -i "/catch_workers_output/s/^;//g" /usr/local/php/etc/php-fpm.d/www.conf
sed -i "/[log_errors]/s/^;//g" /usr/local/php/etc/php-fpm.d/www.conf
sed -i "s/^;php_admin_value[memory_limit]/php_admin_value[memory_limit] = 64M/g" /usr/local/php/etc/php-fpm.d/www.conf

#------------------------------------------------------------------------------------
# config php.ini
#------------------------------------------------------------------------------------

cd /usr/local/php/lib
cp ~/sources/php-$php/php.ini-development ./php.ini

sed -i "s/^short_open_tag = Off/short_open_tag = On/g" /usr/local/php/lib/php.ini
sed -i "s/^disable_functions.*/disable_functions = exec,passthru,shell_exec,system,proc_open,popen/g" /usr/local/php/lib/php.ini
sed -i "s/^expose_php = On/expose_php = Off/g" /usr/local/php/lib/php.ini
sed -i "s/^error_reporting = E_ALL/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/g" /usr/local/php/lib/php.ini
sed -i "s/^display_errors = On/display_errors = Off/g" /usr/local/php/lib/php.ini
sed -i "s/^display_startup_errors = On/display_startup_errors = Off/g" /usr/local/php/lib/php.ini
sed -i "s/^upload_max_filesize = 2M/upload_max_filesize = 4M/g" /usr/local/php/lib/php.ini
sed -i "s/^;date.timezone.*/date.timezone = Europe/London/g" /usr/local/php/lib/php.ini

sed -i "s/^;opcache.enable=0/opcache.enable=1/g" /usr/local/php/lib/php.ini
sed -i "/opcache.memory_consumption/s/^;//g" /usr/local/php/lib/php.ini
sed -i "s/^;opcache.interned_strings_buffer.*/opcache.interned_strings_buffer=16/g" /usr/local/php/lib/php.ini
sed -i "s/^;opcache.max_accelerated_files.*/opcache.max_accelerated_files=7000/g" /usr/local/php/lib/php.ini
sed -i "s/^;opcache.validate_timestamps=1/opcache.validate_timestamps=1/g" /usr/local/php/lib/php.ini
sed -i "s/^;opcache.fast_shutdown=0/opcache.fast_shutdown=1/g" /usr/local/php/lib/php.ini

#------------------------------------------------------------------------------------
# config php-fpm
#------------------------------------------------------------------------------------

cd /etc/init.d
cp ~/sources/php-$php/sapi/fpm/init.d.php-fpm php-fpm

sed -i "s/^php_fpm_PID=${prefix}\/var\/run\/php-fpm.pid/php_fpm_PID=\/var\/run\/php-fpm.pid/g /etc/init.d/php-fpm

chmod +x php-fpm
service php-fpm start
echo 'pathmunge /usr/local/php/bin' > /etc/profile.d/php.sh
chkconfig php-fpm on

#------------------------------------------------------------------------------------
# ImageMagick
#------------------------------------------------------------------------------------

yum install php-pear
yum install ImageMagick ImageMagick-devel
pecl install imagick

echo 'extension=imagick.so' >> /usr/local/php/lib/php.ini