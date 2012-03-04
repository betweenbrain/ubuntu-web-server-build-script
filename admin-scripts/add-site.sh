#!/bin/bash
# ================================================================== #
# Shell script to add a new site (virtual host)
# ================================================================== #
# Parts copyright (c) 2012 Matt Thomas http://betweenbrain.com
# This script is licensed under GNU GPL version 2.0 or above
# ================================================================== #
#
read -p "Enter new site domain: " DOMAIN
echo
read -p "Enter user under which new site will run under: " USER
echo
echo
echo
echo "Creating directories for $DOMAIN in $USER's home directory"
echo "--------------------------------------------------------------"
#
mkdir -p /home/$USER/public_html/$DOMAIN/{cgi-bin,log,log/old,www}
echo "<?php echo '<h1>$DOMAIN works!</h1>'; ?>" > /home/$USER/public_html/$DOMAIN/www/index.php
#
echo
echo
echo
echo "Setting correct ownership and permissions for $DOMAIN"
echo "--------------------------------------------------------------"
#
chown -R $USER:$USER /home/$USER/public_html
find /home/$USER/public_html/$DOMAIN/ -type d -exec chmod 755 {} \;
find /home/$USER/public_html/$DOMAIN/ -type f -exec chmod 644 {} \;
#
echo
echo
echo
echo "Creating VirtualHost for $DOMAIN"
# http://www.howtoforge.com/how-to-set-up-apache2-with-mod_fcgid-and-php5-on-ubuntu-8.10
echo "--------------------------------------------------------------"
#
echo "<VirtualHost *:80>
    DocumentRoot /home/$USER/public_html/$DOMAIN/www

    ServerName  $DOMAIN
    ServerAlias www.$DOMAIN
    ServerAdmin webmaster@$DOMAIN
    ServerSignature Off

    LogLevel warn
    ErrorLog  /home/$USER/public_html/$DOMAIN/log/error.log
    CustomLog /home/$USER/public_html/$DOMAIN/log/access.log combined

    <Directory /home/$USER/public_html/$DOMAIN/www>
        Options FollowSymLinks
        AllowOverride All
        Order allow,deny
        Allow from all
        DirectoryIndex index.php index.html
    </Directory>
</VirtualHost>
" > /etc/apache2/sites-available/$DOMAIN
#
echo "
# suPHP_ConfigPath directives - see http://php.net/ini.core
post_max_size = 20M
upload_max_filesize = 20M
max_execution_time = 90
max_input_time = 90
memory_limit = 48M
output_buffering = off
display_errors = off
magic_quotes_gpc = off
" >> /home/$USER/public_html/$DOMAIN/php.ini
#
echo
echo
echo
echo "Adding logrotate conf for $DOMAIN"
echo "--------------------------------------------------------------"
#
echo "/home/$USER/public_html/$DOMAIN/log/*.log {
    weekly
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 655 $USER $USER
    olddir /home/$USER/public_html/$DOMAIN/log/old/
}
" > /etc/logrotate.d/$DOMAIN
#
echo
echo
echo
echo "Adding mod_security monitoring to fail2ban for $DOMAIN"
# based on http://www.fail2ban.org/wiki/index.php/HOWTO_fail2ban_with_ModSecurity2.5
echo "---------------------------------------------------------------"
#
echo "
[modsecurity-$DOMAIN]

enabled  = true
filter   = modsecurity
action   = iptables-multiport[name=ModSecurity-$DOMAIN, port="http,https"]
           sendmail-buffered[name=ModSecurity, lines=10, dest=webmaster@$DOMAIN]
logpath  = /home/$USER/public_html/$DOMAIN/log/*error.log
bantime  = 600
maxretry = 3
" >> /etc/fail2ban/jail.local
#
echo
echo
echo
echo "Enabling site $DOMAIN, restarting apache"
echo "--------------------------------------------------------------"
#
a2ensite $DOMAIN
/etc/init.d/apache2 restart
#

