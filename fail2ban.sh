#!/bin/bash

#------------------------------------------------------------------------------------
# Params
#------------------------------------------------------------------------------------



#------------------------------------------------------------------------------------
# Install fail2ban
#------------------------------------------------------------------------------------

yum install fail2ban -y
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
#nano /etc/fail2ban/jail.local
service fail2ban restart