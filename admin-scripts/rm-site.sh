#!/bin/bash
# ================================================================== #
# Shell script to remove a site (virtual host)
# ================================================================== #
# Parts copyright (c) 2012 Matt Thomas http://betweenbrain.com
# This script is licensed under GNU GPL version 2.0 or above
# ================================================================== #
#
read -p "Enter site to remove: " DOMAIN
echo
read -p "Enter user under which site exists: " USER
echo
echo
echo
echo "Removing directories for $DOMAIN in $USER's home directory"
echo "--------------------------------------------------------------"
#
rm -r /home/$USER/public_html/$DOMAIN/
#
echo
echo
echo
echo "Removing VirtualHost for $DOMAIN"
echo "--------------------------------------------------------------"
#
rm /etc/apache2/sites-available/$DOMAIN
#
echo
echo
echo
echo "Removing fcgi wrapper for $DOMAIN, making it executable and setting owner"
echo "--------------------------------------------------------------"
#
rm -r /var/www/php-fcgi-scripts/$DOMAIN/
#
echo
echo
echo
echo "Removing logrotate conf for $DOMAIN"
echo "--------------------------------------------------------------"
#
rm -r /etc/logrotate.d/$DOMAIN
#
echo
echo
echo
echo "Disabling site $DOMAIN, restarting apache"
echo "--------------------------------------------------------------"
#
a2dissite $DOMAIN
/etc/init.d/apache2 restart
#

