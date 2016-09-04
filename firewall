#!/bin/bash

#------------------------------------------------------------------------------------
# Params
#------------------------------------------------------------------------------------



#------------------------------------------------------------------------------------
# Config firewall
#------------------------------------------------------------------------------------

service firewalld start
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ftp
firewall-cmd --reload
chkconfig firewalld on