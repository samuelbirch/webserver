#!/bin/bash

#------------------------------------------------------------------------------------
# Params
#------------------------------------------------------------------------------------

serverName=$1
if [ -z ${serverName+x} ]; then
	echo -e "What is the server name: \c "
	read serverName
fi

adminEmail=$2
if [ -z ${adminEmail+x} ]; then
	echo -e "What is the admin email: \c "
	read adminEmail
fi

#------------------------------------------------------------------------------------
# vars
#------------------------------------------------------------------------------------

httpd=2.4.23
apr=1.5.2
aprutil=1.5.4
openssl=1.0.2h
nghttp2=1.14.0
mod_http2=1.6.1
mod_security=2.9.1

#------------------------------------------------------------------------------------
# Install packages
#------------------------------------------------------------------------------------

yum -y update
yum -y install epel-release
yum -y install wget gcc pcre-devel openssl-devel nano zlib-devel libxml2-devel automake libtool python-devel lua-devel git

#------------------------------------------------------------------------------------
# Download & unzip sources
#------------------------------------------------------------------------------------

mkdir ~/sources
cd ~/sources

wget http://mirror.ox.ac.uk/sites/rsync.apache.org//httpd/httpd-$httpd.tar.gz
tar -zxvf httpd-$httpd.tar.gz

wget http://mirror.catn.com/pub/apache//apr/apr-$apr.tar.gz
tar -zxvf apr-$apr.tar.gz

wget http://mirror.catn.com/pub/apache//apr/apr-util-$aprutil.tar.gz
tar -zxvf apr-util-$aprutil.tar.gz

wget https://www.openssl.org/source/openssl-$openssl.tar.gz
tar -zxvf openssl-$openssl.tar.gz

wget https://github.com/nghttp2/nghttp2/releases/download/v$nghttp2/nghttp2-$nghttp2.tar.gz
tar -zxvf nghttp2-$nghttp2.tar.gz

wget https://github.com/icing/mod_h2/releases/download/v1.6.1/mod_http2-$mod_http2.tar.gz
tar -zxvf mod_http2-$mod_http2.tar.gz

wget https://www.modsecurity.org/tarball/$mod_security/modsecurity-$mod_security.tar.gz
tar -zxvf modsecurity-$mod_security.tar.gz

wget -O owasp.tar.gz https://github.com/SpiderLabs/owasp-modsecurity-crs/tarball/master
mkdir /usr/local/apache2/conf/crs
tar -zxvf owasp.tar.gz -C /usr/local/apache2/conf/crs --strip 1

#------------------------------------------------------------------------------------
# Install openssl
#------------------------------------------------------------------------------------

cd ~/sources/openssl-$openssl
./config shared zlib-dynamic
make depend
make
make install

#------------------------------------------------------------------------------------
# Install http2
#------------------------------------------------------------------------------------

cd ~/sources/nghttp2-$nghttp2
export OPENSSL_CFLAGS="-I/usr/local/ssl/include"
export OPENSSL_LIBS="-L/usr/local/ssl/lib -lssl -lcrypto"
./configure
make
make install

#------------------------------------------------------------------------------------
# Install apr
#------------------------------------------------------------------------------------

cd ~/sources/apr-$apr
./configure
make
make install

#------------------------------------------------------------------------------------
# Install apr-util
#------------------------------------------------------------------------------------

cd ~/sources/apr-util-$aprutil
./configure --with-apr=/usr/local/apr
make
make install

#------------------------------------------------------------------------------------
# Install apache
#------------------------------------------------------------------------------------

cd ~/sources/httpd-$httpd
cp -r ../apr-$apr srclib/apr
cp -r ../apr-util-$aprutil srclib/apr-util
./configure --with-ssl=/usr/local/ssl --with-pcre=/usr/bin/pcre-config --enable-unique-id --enable-ssl --enable-so --with-included-apr --enable-http2 --with-mpm=event --enable-deflate --enable-proxy --enable-proxy-html --enable-http --enable-expires --enable-unique-id --enable-rewrite --enable-proxy-fcgi
make
make install

#------------------------------------------------------------------------------------
# update mod_http2
#------------------------------------------------------------------------------------

cd ~/sources/mod_http2-$mod_http2
./configure --with-apxs=/usr/local/apache2/bin/apxs
make
make install

#------------------------------------------------------------------------------------
# update apache envvars
#------------------------------------------------------------------------------------

sed -i "s/\/usr\/local\/apache2\/lib/\/usr\/local\/apache2\/lib:\/usr\/local\/lib\/:\/usr\/local\/ssl\/lib/" /usr/local/apache2/bin/envvars

#------------------------------------------------------------------------------------
# install letsencrypt
#------------------------------------------------------------------------------------

git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt
cd /opt/letsencrypt
./letsencrypt-auto

#------------------------------------------------------------------------------------
# install mod security
#------------------------------------------------------------------------------------

cd ~/sources/modsecurity-$mod_security
./autogen.sh
./configure --with-apxs=/usr/local/apache2/bin/apxs --with-apr=/usr/local/apache2/bin/apr-1-config --with-apu=/usr/local/apache2/bin/apu-1-config
make
make install
cp /usr/local/modsecurity/lib/mod_security2.so /usr/local/apache2/modules

#------------------------------------------------------------------------------------
# install owasp
#------------------------------------------------------------------------------------

cd /usr/local/apache2/conf/crs
cp modsecurity_crs_10_setup.conf.example modsecurity_crs_10_setup.conf

#------------------------------------------------------------------------------------
# update httpd-security
#------------------------------------------------------------------------------------

echo 'LoadModule security2_module modules/mod_security2.so

<IfModule security2_module>
      Include conf/crs/modsecurity_crs_10_setup.conf
      Include conf/crs/base_rules/*.conf
      # Include conf/crs/experimental_rules/*.conf
      # Include conf/crs/optional_rules/*.conf

      SecRuleEngine On
      SecRequestBodyAccess On
      SecResponseBodyAccess On 
      SecResponseBodyMimeType text/plain text/html text/xml application/octet-stream
      SecDataDir /tmp

      SecRuleRemoveById 960015 960008 981318 960017 960911 981172 981246 950120 970003
      SecRuleRemoveById 970901 981205 970015

      # Debug log
      SecDebugLog /usr/local/apache2/logs/modsec_debug.log
      SecDebugLogLevel 3

      SecAuditEngine RelevantOnly
      SecAuditLogRelevantStatus ^2-5
      SecAuditLogParts ABCIFHZ
      SecAuditLogType Serial
      SecAuditLog /usr/local/apache2/logs/modsec_audit.log
</IfModule>' > /usr/local/apache2/conf/extra/httpd-security.conf

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

sed -i "/deflate_module/s/^#//g" /usr/local/apache2/conf/httpd.conf
sed -i "/expires_module/s/^#//g" /usr/local/apache2/conf/httpd.conf
sed -i "/unique_id_module/s/^#//g" /usr/local/apache2/conf/httpd.conf
sed -i "/proxy_module/s/^#//g" /usr/local/apache2/conf/httpd.conf
sed -i "/proxy_http_module/s/^#//g" /usr/local/apache2/conf/httpd.conf
sed -i "/proxy_fcgi_module/s/^#//g" /usr/local/apache2/conf/httpd.conf
sed -i "/ssl_module/s/^#//g" /usr/local/apache2/conf/httpd.conf
sed -i "/rewrite_module/s/^#//g" /usr/local/apache2/conf/httpd.conf
sed -i "/http2_module/s/^#//g" /usr/local/apache2/conf/httpd.conf
sed -i "/socache_shmcb_module/s/^#//g" /usr/local/apache2/conf/httpd.conf
sed -i "/log_config_module/s/^#//g" /usr/local/apache2/conf/httpd.conf
sed -i "/setenvif_module/s/^#//g" /usr/local/apache2/conf/httpd.conf

sed -i "s/^User daemon/User apache/g" /usr/local/apache2/conf/httpd.conf
sed -i "s/^Group daemon/Group www/g" /usr/local/apache2/conf/httpd.conf

sed -i "s/^ServerAdmin.*/ServerAdmin $adminEmail/g" /usr/local/apache2/conf/httpd.conf

sed -i "s/^#ServerName.*/ServerName $serverName:80/g" /usr/local/apache2/conf/httpd.conf

sed -i 's/^DocumentRoot "\/usr\/local\/apache2\/htdocs"/DocumentRoot "\/var\/www\/html"/' /usr/local/apache2/conf/httpd.conf

sed -i 's/^<Directory "\/usr\/local\/apache2\/htdocs">/<Directory "\/var\/www\/html">/' /usr/local/apache2/conf/httpd.conf

sed -i 's/Options Indexes FollowSymLinks/Options -Indexes -FollowSymLinks -Includes/' /usr/local/apache2/conf/httpd.conf

sed -i 's/AllowOverride None/AllowOverride All\
    AcceptPathInfo On/' /usr/local/apache2/conf/httpd.conf
    
sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html index.htm/' /usr/local/apache2/conf/httpd.conf


sed -i "/Include conf/extra/httpd-mpm.conf/s/^#//g /usr/local/apache2/conf/httpd.conf
sed -i "/Include conf/extra/httpd-vhosts.conf/s/^#//g /usr/local/apache2/conf/httpd.conf
sed -i "/Include conf/extra/httpd-ssl.conf/s/^#//g /usr/local/apache2/conf/httpd.conf

echo 'Include conf/extra/httpd-security.conf

<IfModule http2_module>
    LogLevel http2:info
</IfModule>

#Enable HTTP/2 support
Protocols h2 http/1.1' >> /usr/local/apache2/conf/httpd.conf

#------------------------------------------------------------------------------------
# update httpd-mpm conf
#------------------------------------------------------------------------------------

sed -i 's/PidFile "logs\/httpd.pid"/PidFile "\/var\/run\/httpd.pid"/' /usr/local/apache2/conf/extra/httpd-mpm.conf

sed -i 's/<IfModule mpm_event_module>
    StartServers             3
    MinSpareThreads         75
    MaxSpareThreads        250
    ThreadsPerChild         25
    MaxRequestWorkers	   400
    MaxConnectionsPerChild   0
</IfModule>/<IfModule mpm_event_module>
    StartServers             2
    MinSpareThreads          2
    MaxSpareThreads          4
    ThreadsPerChild         25
    MaxRequestWorkers	   300
    MaxConnectionsPerChild   0
</IfModule>/' /usr/local/apache2/conf/extra/httpd-mpm.conf

#------------------------------------------------------------------------------------
# update httpd-security conf
#------------------------------------------------------------------------------------

echo '<IfModule mod_headers.c>
    Header unset ETag
    Header edit Set-Cookie ^(.*)$ $1;HttpOnly;Secure
    Header set X-XSS-Protection "1; mode=block"
    Header set X-Content-Type-Options "nosniff"
</IfModule>

ServerTokens Prod
ServerSignature Off
FileETag None
TraceEnable off
KeepAlive off' > /usr/local/apache2/conf/extra/httpd-security.conf


chown -R apache:www /usr/local/apache2

#------------------------------------------------------------------------------------
# update httpd bash
#------------------------------------------------------------------------------------

echo '#!/bin/bash
#
# httpd        Startup script for the Apache HTTP Server
#
# chkconfig: - 85 15
# description: The Apache HTTP Server is an efficient and extensible  \
#              server implementing the current HTTP standards.
# processname: httpd
# config: /etc/httpd/conf/httpd.conf
# config: /etc/sysconfig/httpd
# pidfile: /var/run/httpd/httpd.pid
#
### BEGIN INIT INFO
# Provides: httpd
# Required-Start: $local_fs $remote_fs $network $named
# Required-Stop: $local_fs $remote_fs $network
# Should-Start: distcache
# Short-Description: start and stop Apache HTTP Server
# Description: The Apache HTTP Server is an extensible server
#  implementing the current HTTP standards.
### END INIT INFO

# Source function library.
. /etc/rc.d/init.d/functions

if [ -f /etc/sysconfig/httpd ]; then
        . /etc/sysconfig/httpd
fi

# Start httpd in the C locale by default.
HTTPD_LANG=${HTTPD_LANG-"C"}

# This will prevent initlog from swallowing up a pass-phrase prompt if
# mod_ssl needs a pass-phrase from the user.
INITLOG_ARGS=""

# Set HTTPD=/usr/sbin/httpd.worker in /etc/sysconfig/httpd to use a server
# with the thread-based "worker" MPM; BE WARNED that some modules may not
# work correctly with a thread-based MPM; notably PHP will refuse to start.

# Path to the apachectl script, server binary, and short-form for messages.
apachectl=/usr/local/apache2/bin/apachectl
httpd=${HTTPD-/usr/local/apache2/bin/httpd}
prog=httpd
pidfile=${PIDFILE-/var/run/httpd.pid}
lockfile=${LOCKFILE-/var/lock/subsys/httpd}
RETVAL=0
STOP_TIMEOUT=${STOP_TIMEOUT-10}

# The semantics of these two functions differ from the way apachectl does
# things -- attempting to start while running is a failure, and shutdown
# when not running is also a failure.  So we just do it the way init scripts
# are expected to behave here.
start() {
        echo -n $"Starting $prog: "
        LANG=$HTTPD_LANG daemon --pidfile=${pidfile} $httpd $OPTIONS
        RETVAL=$?
        echo
        [ $RETVAL = 0 ] && touch ${lockfile}
        return $RETVAL
}

# When stopping httpd, a delay (of default 10 second) is required
# before SIGKILLing the httpd parent; this gives enough time for the
# httpd parent to SIGKILL any errant children.
stop() {
        echo -n $"Stopping $prog: "
        killproc -p ${pidfile} -d ${STOP_TIMEOUT} $httpd
        RETVAL=$?
        echo
        [ $RETVAL = 0 ] && rm -f ${lockfile} ${pidfile}
}
reload() {
    echo -n $"Reloading $prog: "
    if ! LANG=$HTTPD_LANG $httpd $OPTIONS -t >&/dev/null; then
        RETVAL=6
        echo $"not reloading due to configuration syntax error"
        failure $"not reloading $httpd due to configuration syntax error"
    else
        # Force LSB behaviour from killproc
        LSB=1 killproc -p ${pidfile} $httpd -HUP
        RETVAL=$?
        if [ $RETVAL -eq 7 ]; then
            failure $"httpd shutdown"
        fi
    fi
    echo
}

# See how we were called.
case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
        status -p ${pidfile} $httpd
        RETVAL=$?
        ;;
  restart)
        stop
        start
        ;;
  condrestart|try-restart)
        if status -p ${pidfile} $httpd >&/dev/null; then
                stop
                start
        fi
        ;;
  force-reload|reload)
        reload
        ;;
  graceful|help|configtest|fullstatus)
        $apachectl $@
        RETVAL=$?
        ;;
  *)
        echo $"Usage: $prog {start|stop|restart|condrestart|try-restart|force-re
load|reload|status|fullstatus|graceful|help|configtest}"
        RETVAL=2
esac

exit $RETVAL' > /etc/init.d/httpd

chmod +x /etc/init.d/httpd

service httpd restart

#------------------------------------------------------------------------------------
# log rotate
#------------------------------------------------------------------------------------

echo '/var/www/html/*/logs/*.log {
    rotate 5
    daily
    size 128M
    compress
    delaycompress
    sharedscripts

    postrotate
	service httpd graceful > /dev/null
    endscript
}' > /etc/logrotate.d/httpd


chkconfig httpd on

#------------------------------------------------------------------------------------
# create cert for server
#------------------------------------------------------------------------------------

service httpd stop
./letsencrypt-auto certonly --standalone --w /var/www/html --email $adminEmail -d $serverName
#service httpd start

sed -i 's/^DocumentRoot.*/DocumentRoot "\/var\/www\/html"/' /usr/local/apache2/conf/extra/httpd-ssl.conf
sed -i 's/^ServerName.*/ServerName $serverName:443/' /usr/local/apache2/conf/extra/httpd-ssl.conf
sed -i 's/^ServerAdmin.*/ServerAdmin $adminEmail/' /usr/local/apache2/conf/extra/httpd-ssl.conf

sed -i 's/^SSLCertificateFile.*/SSLCertificateFile "/etc/letsencrypt/live/$serverName/cert.pem"/' /usr/local/apache2/conf/extra/httpd-ssl.conf
sed -i 's/^SSLCertificateKeyFile.*/SSLCertificateKeyFile "/etc/letsencrypt/live/$serverName/privkey.pem"/' /usr/local/apache2/conf/extra/httpd-ssl.conf
sed -i 's/^#SSLCertificateChainFile.*/SSLCertificateChainFile "/etc/letsencrypt/live/$serverName/chain.pem"/' /usr/local/apache2/conf/extra/httpd-ssl.conf

service httpd restart

