#!/bin/bash
echo "Enter new site domain"
read DOMAIN
echo
echo "Enter new site email"
read EMAIL
echo
echo "Enter user under which new site will run under"
read USER
echo
echo "
<VirtualHost *:80>
  ServerName  $DOMAIN
  ServerAlias www.$DOMAIN
  ServerAdmin $EMAIL
  Options FollowSymLinks MultiViews
  DirectoryIndex index.php index.html
  DocumentRoot /home/$USER/www/$DOMAIN/public/
  LogLevel warn
  ErrorLog  /home/$USER/www/$DOMAIN/log/error.log
  CustomLog /home/$USER/www/$DOMAIN/log/access.log combined
</VirtualHost>
" >> /etc/apache2/sites-available/$DOMAIN

echo "Creating web directory structure"
mkdir -p /home/$USER/www/$DOMAIN/{cgi-bin,log,private,public}
chown -R $USER:webmasters /home/$USER/www && chmod -R g+w /home/$USER/www
find /home/$USER/www -type d -exec chmod g+s {} \;

echo "<h1>$DOMAIN works!</h1>" >> /home/$USER/www/$DOMAIN/public/index.php

echo "Enabling site, reloading apache"
a2ensite $DOMAIN
/etc/init.d/apache2 restart

