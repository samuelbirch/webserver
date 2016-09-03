#!/bin/bash

#------------------------------------------------------------------------------------
# Params
#------------------------------------------------------------------------------------

echo -e "What is the default FTP user: \c "
read FTP_USER

#------------------------------------------------------------------------------------
# Install vsFTPd
#------------------------------------------------------------------------------------

yum -y install vsftpd

#------------------------------------------------------------------------------------
# Configure
#------------------------------------------------------------------------------------

useradd -s /sbin/nologin -d /var/www/html vsftpd
chown -R vsftpd:vsftpd /var/www/html

cp /etc/vsftpd/vsftpd.conf{,.original}
 
sed -i "s/^.*anonymous_enable.*/anonymous_enable=NO/g" /etc/vsftpd/vsftpd.conf
sed -i "/^xferlog_std_format*a*/ s/^/#/" /etc/vsftpd/vsftpd.conf
sed -i "s/#idle_session_timeout=600/idle_session_timeout=900/" /etc/vsftpd/vsftpd.conf
sed -i "s/#nopriv_user=ftpsecure/nopriv_user=vsftpd/" /etc/vsftpd/vsftpd.conf
sed -i "/#chroot_list_enable=YES/i\chroot_local_user=YES" /etc/vsftpd/vsftpd.conf
sed -i 's/listen=NO/listen=YES/' /etc/vsftpd/vsftpd.conf
sed -i 's/listen_ipv6=YES/listen_ipv6=NO/' /etc/vsftpd/vsftpd.conf
 
echo 'allow_writeable_chroot=YES
guest_enable=YES
guest_username=vsftpd
local_root=/var/www/html
user_sub_token=$USER
virtual_use_local_privs=YES
user_config_dir=/etc/vsftpd/vconf' >> /etc/vsftpd/vsftpd.conf

#------------------------------------------------------------------------------------
# Configure pam
#------------------------------------------------------------------------------------
 
cp /etc/pam.d/vsftpd{,.original}
 
echo '#%PAM-1.0
auth required pam_userdb.so db=/etc/vsftpd/password crypt=crypt
account required pam_userdb.so db=/etc/vsftpd/password crypt=crypt
session required pam_loginuid.so' > /etc/pam.d/vsftpd

#------------------------------------------------------------------------------------
# Create default user
#------------------------------------------------------------------------------------

# /etc/vsftpd/vconf/defaultuser
echo 'dirlist_enable=YES
download_enable=YES
local_root=/var/www/html
write_enable=YES' > /etc/vsftpd/vconf/$FTP_USER
 
echo '$FTP_USER' | tee /etc/vsftpd/password{,-nocrypt} > /dev/null
 
myval=$(openssl rand -base64 6)
echo $myval >> /etc/vsftpd/password-nocrypt
echo $(openssl passwd -crypt $myval) >> /etc/vsftpd/password
 
# /etc/vsftpd/password.db
db_load -T -t hash -f /etc/vsftpd/password /etc/vsftpd/password.db