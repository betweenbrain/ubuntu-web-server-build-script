#!/bin/bash
# ================================================================== #
# Ubuntu 10.04 web server build shell script
# ================================================================== #
# Parts copyright (c) 2012 Matt Thomas http://betweenbrain.com
# This script is licensed under GNU GPL version 2.0 or above
# ================================================================== #
#
#
#
# ================================================================== #
#          Define system specific details in this section            #
# ================================================================== #
#
HOSTNAME=
SYSTEMIP=
DOMAIN=
LANGUAGE=
CHARSET=
SSHPORT=
IGNOREIP=
USER=
ADMINEMAIL=
PUBLICKEY="ssh-rsa ... foo@bar.com"
# ================================================================== #
#                      End system specific details                   #
# ================================================================== #
#
echo
echo "System updates and basic setup"
echo "==============================================================="
echo
echo
echo
echo "First things first, let's make sure we have the latest updates."
echo "---------------------------------------------------------------"
#
aptitude update && aptitude -y safe-upgrade
#
echo
echo "Setting the hostname."
# http://library.linode.com/getting-started
echo "---------------------------------------------------------------"
echo
echo
#
echo "$HOSTNAME" > /etc/hostname
hostname -F /etc/hostname
#
echo
echo
echo
echo "Updating /etc/hosts."
echo "---------------------------------------------------------------"
#
mv /etc/hosts /etc/hosts.bak
#
echo "
127.0.0.1       localhost
$SYSTEMIP       $HOSTNAME.$DOMAIN     $HOSTNAME
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
" >> /etc/hosts
#
echo
echo
echo
echo "Setting the proper timezone."
echo "---------------------------------------------------------------"
#
dpkg-reconfigure tzdata
#
echo
echo
echo
echo "Synchronize the system clock with an NTP server"
echo "---------------------------------------------------------------"
#
aptitude install -y ntp
#
echo
echo
echo
echo "Setting the language and charset"
echo "---------------------------------------------------------------"
#
locale-gen $LANGUAGE.$CHARSET
/usr/sbin/update-locale LANG=$LANGUAGE.$CHARSET
#
# ================================================================== #
#                             SSH Security                           #
#      https://help.ubuntu.com/community/SSH/OpenSSH/Configuring     #
# ================================================================== #
#
echo
echo
echo
echo "Change SSH port"
echo "---------------------------------------------------------------"
#
sed -i "s/Port 22/Port $SSHPORT/g" /etc/ssh/sshd_config
#
echo
echo
echo
echo "Instruct sshd to listen only on a specific IP address."
echo "---------------------------------------------------------------"
echo
#
sed -i "s/#ListenAddress 0.0.0.0/ListenAddress $SYSTEMIP/g" /etc/ssh/sshd_config
#
echo
echo
echo
echo "Ensure that sshd starts after eth0 is up, not just after filesystem"
# http://blog.roberthallam.org/2010/06/sshd-not-running-at-startup/
echo "---------------------------------------------------------------"
#
sed -i "s/start on filesystem/start on filesystem and net-device-up IFACE=eth0/g" /etc/init/ssh.conf
#
echo
echo
echo
echo
echo "Disabling root ssh login"
echo "---------------------------------------------------------------"
#
sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
#
echo
echo
echo
echo "Disabling password authentication"
echo "---------------------------------------------------------------"
#
sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
#
echo
echo
echo
echo "Disabling X11 forwarding"
echo "---------------------------------------------------------------"
#
sed -i "s/X11Forwarding yes/X11Forwarding no/g" /etc/ssh/sshd_config
#
echo
echo
echo
echo "Disabling sshd DNS resolution"
echo "---------------------------------------------------------------"
#
echo "UseDNS no" >> /etc/ssh/sshd_config
#
echo
echo
echo
echo "Creating new primary user"
echo "---------------------------------------------------------------"
# -------------------------------------------------------------------------
# Script to add a user to Linux system
# -------------------------------------------------------------------------
# Copyright (c) 2007 nixCraft project <http://bash.cyberciti.biz/>
# This script is licensed under GNU GPL version 2.0 or above
# Comment/suggestion: <vivek at nixCraft DOT com>
# -------------------------------------------------------------------------
# See url for more info:
# http://www.cyberciti.biz/tips/howto-write-shell-script-to-add-user.html
# -------------------------------------------------------------------------
if [ $(id -u) -eq 0 ]; then
	# read -p "Enter username of who can connect via SSH: " USER
	read -s -p "Enter password of user who can connect via SSH: " PASSWORD
	egrep "^$USER" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$USER exists!"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $PASSWORD)
		useradd -s /bin/bash -m -d /home/$USER -U -p $pass $USER
		[ $? -eq 0 ] && echo "$USER has been added to system!" || echo "Failed to add a $USER!"
	fi
else
	echo "Only root may add a user to the system"
	exit 2
fi
# -------------------------------------------------------------------------
# End script to add a user to Linux system
# -------------------------------------------------------------------------
#
echo
echo
echo
echo "Adding $USER to SSH AllowUsers"
echo "---------------------------------------------------------------"
#
echo "AllowUsers $USER" >> /etc/ssh/sshd_config
#
echo
echo
echo
echo "Adding $USER to sudoers"
echo "---------------------------------------------------------------"
#
cp /etc/sudoers /etc/sudoers.tmp
chmod 0640 /etc/sudoers.tmp
echo "$USER    ALL=(ALL) ALL" >> /etc/sudoers.tmp
chmod 0440 /etc/sudoers.tmp
mv /etc/sudoers.tmp /etc/sudoers
#
echo
echo
echo
echo "Adding ssh key"
echo "---------------------------------------------------------------"
#
mkdir /home/$USER/.ssh
touch /home/$USER/.ssh/authorized_keys
echo $PUBLICKEY >> /home/$USER/.ssh/authorized_keys
chown -R $USER:$USER /home/$USER/.ssh
chmod 700 /home/$USER/.ssh
chmod 600 /home/$USER/.ssh/authorized_keys
#
sed -i "s/#AuthorizedKeysFile/AuthorizedKeysFile/g" /etc/ssh/sshd_config
#
/etc/init.d/ssh restart
#
# ================================================================== #
#                               IPtables                             #
# ================================================================== #
#
echo "Installing IPTables firewall"
echo "---------------------------------------------------------------"
#
aptitude install -y iptables
#
echo
echo
echo
echo "Setting up basic(!) rules for IPTables. Modify as needed, with care :)"
# http://www.thegeekstuff.com/scripts/iptables-rules
# http://wiki.centos.org/HowTos/Network/IPTables
# https://help.ubuntu.com/community/IptablesHowTo
echo "---------------------------------------------------------------"
#
# Flush old rules
iptables -F

# Allow SSH connections on tcp port $SSHPORT
# This is essential when working on remote servers via SSH to prevent locking yourself out of the system
#
iptables -A INPUT -p tcp --dport $SSHPORT -j ACCEPT

# Set default chain policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Accept packets belonging to established and related connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow loopback access
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow incoming HTTP
iptables -A INPUT -i eth0 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

# Allow outgoing HTTPS
iptables -A OUTPUT -o eth0 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

# Allow incoming HTTPS
iptables -A INPUT -i eth0 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT

# Allow outgoing HTTPS
iptables -A OUTPUT -o eth0 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT

# Ping from inside to outside
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

# Ping from outside to inside
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT

# Allow packets from internal network to reach external network.
# if eth1 is external, eth0 is internal
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT

# Allow Sendmail or Postfix
iptables -A INPUT -i eth0 -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT

# Help prevent DoS attack
iptables -A INPUT -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT

# Log dropped packets
iptables -N LOGGING
iptables -A INPUT -j LOGGING
iptables -I INPUT 5 -m limit --limit 5/min -j LOG --log-prefix "Iptables denied: " --log-level 7
iptables -A LOGGING -j DROP

# Create the script to load the rules
echo "#!/bin/sh
iptables-restore < /etc/iptables.rules
" > /etc/network/if-pre-up.d/iptablesload

# Create the script to save current rules
echo "#!/bin/sh
iptables-save > /etc/iptables.rules
if [ -f /etc/iptables.downrules ]; then
   iptables-restore < /etc/iptables.downrules
fi
" > /etc/network/if-post-down.d/iptablessave

# Ensure they are executible
chmod +x /etc/network/if-post-down.d/iptablessave
chmod +x /etc/network/if-pre-up.d/iptablesload
#
/etc/init.d/networking restart
#
echo
echo
echo
echo "Establish IPTables logging, and rotation of logs"
# http://ubuntuforums.org/showthread.php?t=668148
# https://wiki.ubuntu.com/LucidLynx/ReleaseNotes#line-178
echo "---------------------------------------------------------------"
#
echo "#IPTables logging
kern.debug;kern.info /var/log/firewall.log
" > /etc/rsyslog.d/firewall.conf
#
/etc/init.d/rsyslog restart
#
mkdir /var/log/old/
#
echo "/var/log/firewall.log {
    weekly
    missingok
    rotate 13
    compress
    notifempty
    create 655 syslog adm
    olddir /var/log/old/
}
" > /etc/logrotate.d/firewall
#
echo
echo
echo
echo "Adding a bit of color and formatting to the command prompt"
# http://ubuntuforums.org/showthread.php?t=810590
echo "---------------------------------------------------------------"
#
echo '
export PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
' >> /home/$USER/.bashrc
source /home/$USER/.bashrc
#
echo
echo
echo
echo "Installing debconf utilities"
echo "---------------------------------------------------------------"
#
aptitude install -y debconf-utils
#
echo
echo
echo
echo "Install and configure postfix as email gateway (send only)"
# http://library.linode.com/email/postfix/gateway-ubuntu-10.04-lucid
echo "---------------------------------------------------------------"
#
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAME.$DOMAIN" | debconf-set-selections
echo "postfix postfix/destinations string localhost.localdomain, localhost" | debconf-set-selections
#
aptitude -y install postfix mailutils
#
ln -s /usr/bin/mail /bin/mail
#
sed -i "s/myhostname =/#myhostname =/g" /etc/postfix/main.cf
echo "myhostname = $HOSTNAME" >> /etc/postfix/main.cf
sed -i "s/#myorigin = \/etc\/mailname/myorigin = $DOMAIN/g" /etc/postfix/main.cf
#
echo
echo
echo
echo "Configure postfix to send email addressed to $USER@$HOSTNAME.$DOMAIN to $ADMINEMAIL."
# http://www.postfix.org/STANDARD_CONFIGURATION_README.html#some_local
echo "---------------------------------------------------------------"
#
echo "$USER@$HOSTNAME.$DOMAIN $ADMINEMAIL" > /etc/postfix/virtual
postmap /etc/postfix/virtual
#
/etc/init.d/postfix restart
#
# ================================================================== #
#                              Web Server                            #
# ================================================================== #
#
echo
echo
echo
echo "Installing Apache threaded server (MPM Worker)"
echo "---------------------------------------------------------------"
#
aptitude -y install apache2-mpm-worker apache2-suexec
echo "ServerName $HOSTNAME" > /etc/apache2/conf.d/servername.conf
sed -i "s/Timeout 300/Timeout 30/g" /etc/apache2/apache2.conf
#
/etc/init.d/apache2 restart
#
echo
echo
echo
echo "Disabling default site"
echo "---------------------------------------------------------------"
#
a2dissite default
#
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

    <IfModule mod_fcgid.c>
        SuexecUserGroup $USER $USER
        <Directory /home/$USER/public_html/$DOMAIN/www>
            Options FollowSymLinks +ExecCGI
            AddHandler fcgid-script .php
            FCGIWrapper /var/www/php-fcgi-scripts/$DOMAIN/php-fcgi-starter .php
            AllowOverride All
            Order allow,deny
            Allow from all
            DirectoryIndex index.php index.html
        </Directory>
    </IfModule>
</VirtualHost>
" > /etc/apache2/sites-available/$DOMAIN
#
echo
echo
echo
echo "Creating fcgi wrapper for $DOMAIN, making it executable and setting owner"
echo "--------------------------------------------------------------"
#
mkdir /var/www/php-fcgi-scripts/
mkdir /var/www/php-fcgi-scripts/$DOMAIN/
#
echo "#!/bin/sh
PHPRC=/etc/php5/cgi/
export PHPRC
export PHP_FCGI_MAX_REQUESTS=5000
export PHP_FCGI_CHILDREN=1
exec /usr/lib/cgi-bin/php
" > /var/www/php-fcgi-scripts/$DOMAIN/php-fcgi-starter
#
chmod 755 /var/www/php-fcgi-scripts/$DOMAIN/php-fcgi-starter
#
chown -R $USER:$USER /var/www/php-fcgi-scripts/$DOMAIN
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
echo
echo
echo
echo "Enable Apache modules"
echo "---------------------------------------------------------------"
echo
#
a2enmod rewrite headers expires deflate ssl suexec
#
echo
echo
echo
echo "Disable Apache modules"
echo "---------------------------------------------------------------"
echo
#
a2dismod status cgid
#
#
echo
echo
echo
echo "Add mod_expires configuration. WARNING: May cause issues with pages that change content dynamically."
# https://akeeba.assembla.com/code/master-htaccess/git/nodes/htaccess.txt
echo "---------------------------------------------------------------"
#
echo "<IfModule mod_expires.c>
    # Enable expiration control
    ExpiresActive On

    # Default expiration: 1 hour after request
    ExpiresDefault "now plus 1 hour"

    # CSS and JS expiration: 1 week after request
    ExpiresByType text/css "now plus 1 week"
    ExpiresByType application/javascript "now plus 1 week"
    ExpiresByType application/x-javascript "now plus 1 week"

    # Image files expiration: 1 month after request
    ExpiresByType image/bmp "now plus 1 month"
    ExpiresByType image/gif "now plus 1 month"
    ExpiresByType image/jpeg "now plus 1 month"
    ExpiresByType image/jp2 "now plus 1 month"
    ExpiresByType image/pipeg "now plus 1 month"
    ExpiresByType image/png "now plus 1 month"
    ExpiresByType image/svg+xml "now plus 1 month"
    ExpiresByType image/tiff "now plus 1 month"
    ExpiresByType image/vnd.microsoft.icon "now plus 1 month"
    ExpiresByType image/x-icon "now plus 1 month"
    ExpiresByType image/ico "now plus 1 month"
    ExpiresByType image/icon "now plus 1 month"
    ExpiresByType text/ico "now plus 1 month"
    ExpiresByType application/ico "now plus 1 month"
    ExpiresByType image/vnd.wap.wbmp "now plus 1 month"
    ExpiresByType application/vnd.wap.wbxml "now plus 1 month"
    ExpiresByType application/smil "now plus 1 month"

    # Audio files expiration: 1 month after request
    ExpiresByType audio/basic "now plus 1 month"
    ExpiresByType audio/mid "now plus 1 month"
    ExpiresByType audio/midi "now plus 1 month"
    ExpiresByType audio/mpeg "now plus 1 month"
    ExpiresByType audio/x-aiff "now plus 1 month"
    ExpiresByType audio/x-mpegurl "now plus 1 month"
    ExpiresByType audio/x-pn-realaudio "now plus 1 month"
    ExpiresByType audio/x-wav "now plus 1 month"

    # Movie files expiration: 1 month after request
    ExpiresByType application/x-shockwave-flash "now plus 1 month"
    ExpiresByType x-world/x-vrml "now plus 1 month"
    ExpiresByType video/x-msvideo "now plus 1 month"
    ExpiresByType video/mpeg "now plus 1 month"
    ExpiresByType video/mp4 "now plus 1 month"
    ExpiresByType video/quicktime "now plus 1 month"
    ExpiresByType video/x-la-asf "now plus 1 month"
    ExpiresByType video/x-ms-asf "now plus 1 month"
</IfModule>
" >> /etc/apache2/conf.d/mod-expires.conf
#
echo
echo
echo
echo "Add mod_deflate configuration"
# https://akeeba.assembla.com/code/master-htaccess/git/nodes/htaccess.txt
echo "---------------------------------------------------------------"
#
echo "<IfModule mod_deflate.c>
    <Location />
        # Insert filter
        AddOutputFilterByType DEFLATE text/plain text/html text/xml text/css application/xml application/xhtml+xml application/rss+xml application/javascript application/x-javascript

        # Netscape 4.x has some problems...
        BrowserMatch ^Mozilla/4 gzip-only-text/html

        # Netscape 4.06-4.08 have some more problems
        BrowserMatch ^Mozilla/4\.0[678] no-gzip

        # MSIE masquerades as Netscape, but it is fine
        # BrowserMatch \bMSIE !no-gzip !gzip-only-text/html

        # NOTE: Due to a bug in mod_setenvif up to Apache 2.0.48
        # the above regex won't work. You can use the following
        # workaround to get the desired effect:
        BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html

        # Don't compress images
        SetEnvIfNoCase Request_URI \
        \.(?:gif|jpe?g|png)$ no-gzip dont-vary

        # Make sure proxies don't deliver the wrong content
        Header append Vary User-Agent env=!dont-vary
    </Location>
</IfModule>
" >> /etc/apache2/conf.d/mod-deflate.conf
#
echo
echo
echo
echo "Custom Apache2 settings"
echo "---------------------------------------------------------------"
#
echo "# Keep connections alive for only a few seconds
KeepAlive On
KeepAliveTimeout 3
" >> /etc/apache2/conf.d/apache2-custom.conf
#
echo
echo
echo
echo "Installing Apache2 Utils"
echo "---------------------------------------------------------------"
#
aptitude install -y apache2-utils
#
echo
echo
echo
echo "Install MySQL and MySQL modules"
# https://help.ubuntu.com/community/ApacheMySQLPHP
echo "--------------------------------------------------------------"
#
aptitude -y install mysql-server && mysql_secure_installation
#
aptitude -y install libapache2-mod-auth-mysql
#
echo
echo
echo
echo "Install fcgid, PHP, and PHP modules"
# https://help.ubuntu.com/community/ApacheMySQLPHP
echo "--------------------------------------------------------------"
#
aptitude -y install libapache2-mod-fcgid php5-cgi php5-cli php5-mysql php5-curl php5-gd php5-mcrypt php5-memcache php5-mhash php5-suhosin php5-xmlrpc php5-xsl
#
a2enmod fcgid
#
/etc/init.d/apache2 restart
#
echo
echo
echo
echo "Configuring fcgid"
echo "--------------------------------------------------------------"
#
echo "<IfModule mod_fcgid.c>
  AddHandler fcgid-script .fcgi .php

  # Where to look for the php.ini file?
  DefaultInitEnv PHPRC        "/etc/php5/cgi"

  # Maximum number of PHP processes
  # Default 1000
  FcgidMaxProcesses         10

  # Number of seconds of idle time before a process is terminated
  # Default 40
  FcgidIOTimeout            30
  # Default 300
  FcgidIdleTimeout          120

  #Or use this if you use the file above
  FCGIWrapper /usr/bin/php-cgi .php
</IfModule>
" > /etc/apache2/conf.d/php-fcgid.conf
#
echo
echo
echo
echo "Configuring apach mpm worker module"
echo "--------------------------------------------------------------"
#
echo "<IfModule mpm_worker_module>
    # Combined with ThreadLimit to set maximum configured value for MaxClients
    # Default 16
    # ServerLimit           16

    # Sets the maximum configured value for ThreadsPerChild
    # Default 64
    # ThreadLimit           64

    # Number of child server processes created on startup
    # Default 3
    StartServers            2

    # Minimum number of idle child server processes
    # Default 5
    MinSpareServers         5

    # Maximum number of idle child server processes
    # Default 10
    MaxSpareServers         10

    # Minimum number of idle threads to handle request spikes
    # Default 75
    MinSpareThreads         5

    # Minimum number of idle threads to handle request spikes
    # Default 250
    MaxSpareThreads         10

    # Number of threads created by each child process
    # Default 25
    ThreadsPerChild         10

    # Number of simultaneous requests that will be served, integer multiple of ThreadsPerChild
    # Default 16
    # Linode 512: MaxClients 25 or less
    # Linode 1024: MaxClients 50 or less
    # Linode 1536: MaxClients 75 or less
    # Linode 2048: MaxClients 100 or less
    MaxClients              20

    # Number of requests that an individual child server process will handle
    # Default 1000
    # 0 = process will never expire
    MaxRequestsPerChild     100
</IfModule>
"  > /etc/apache2/conf.d/mpm-worker.conf
#
echo
echo
echo
echo "Tweaking PHP settings"
echo "--------------------------------------------------------------"
#
sed -i "s/memory_limit = 128M/memory_limit = 48M/g" /etc/php5/cgi/php.ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 20M/g" /etc/php5/cgi/php.ini
sed -i "s/output_buffering = 4096/output_buffering = off/g" /etc/php5/cgi/php.ini
#
# ================================================================== #
#                           Server Security                          #
# ================================================================== #
#
echo
echo
echo
echo "Installing mod_evasive"
# http://library.linode.com/web-servers/apache/mod-evasive
echo "---------------------------------------------------------------"
#
aptitude install -y libapache2-mod-evasive
mkdir /var/log/mod_evasive
chown www-data:www-data /var/log/mod_evasive/
echo "<ifmodule mod_evasive20.c>
    DOSHashTableSize 3097
    DOSPageCount 5
    DOSSiteCount 50
    DOSPageInterval 1
    DOSSiteInterval 1
    DOSBlockingPeriod 10
    DOSLogDir /var/log/mod_evasive
    DOSEmailNotify $ADMINEMAIL
    DOSWhitelist 127.0.0.1
    DOSWhitelist $IGNOREIP
</ifmodule>
" > /etc/apache2/conf.d/modevasive
#
echo
echo
echo
echo "Installing Fail2ban"
# http://library.linode.com/security/fail2ban
echo "---------------------------------------------------------------"
#
aptitude -y install fail2ban
#
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
#
sed -i "s/ignoreip = 127.0.0.1/ignoreip = 127.0.0.1 $IGNOREIP/g" /etc/fail2ban/jail.local
sed -i "s/destemail = root@localhost/destemail = $ADMINEMAIL/g" /etc/fail2ban/jail.local
sed -i "s/action = %(action_)s/action = %(action_mw)s/g" /etc/fail2ban/jail.local
#
echo
echo
echo
echo "Adding mod_security monitoring to fail2ban"
# based on http://www.fail2ban.org/wiki/index.php/HOWTO_fail2ban_with_ModSecurity2.5
echo "---------------------------------------------------------------"
#
echo "
[modsecurity]

enabled  = true
filter   = modsecurity
action   = iptables-multiport[name=ModSecurity, port="http,https"]
           sendmail-buffered[name=ModSecurity, lines=10, dest=$ADMINEMAIL]
logpath  = /var/log/apache*/*error.log
bantime  = 600
maxretry = 3
" >> /etc/fail2ban/jail.local
#
echo "# Fail2Ban configuration file
#
# Author: Matt Thomas

[Definition]
# Match entries like [Mon Feb 13 10:47:12 2012] [error] [client 192.168.0.66] ModSecurity: Access denied
failregex = [[]client\s<HOST>[]]\sModSecurity\:\sAccess\sdenied*
ignoreregex =
" > /etc/fail2ban/filter.d/modsecurity.conf
#
echo
echo
echo
echo "Basic Apache security"
echo "---------------------------------------------------------------"
#
sed -i "s/ServerTokens OS/ServerTokens Prod/g" /etc/apache2/conf.d/security
sed -i "s/ServerSignature On/ServerSignature off/g" /etc/apache2/conf.d/security
#
echo
echo
echo
echo "Installing mod_security"
# http://library.linode.com/web-servers/apache/mod-security
echo "---------------------------------------------------------------"
#
aptitude -y install libxml2 libxml2-dev libxml2-utils
aptitude -y install libaprutil1 libaprutil1-dev
aptitude -y install libapache-mod-security
#
echo
echo
echo
echo "Fetching OWASP rules for mod_security"
# https://www.owasp.org/index.php/Category:OWASP_ModSecurity_Core_Rule_Set_Project
echo "---------------------------------------------------------------"
#
wget http://downloads.sourceforge.net/project/mod-security/modsecurity-crs/0-CURRENT/modsecurity-crs_2.2.3.tar.gz
tar xzf modsecurity-crs_2.2.3.tar.gz
mv modsecurity-crs_2.2.3 /etc/apache2/modsecurity-crs
rm -r modsecurity-crs_2.2.3.tar.gz
#
echo
echo
echo
echo "Enabling OWASP example configuration"
echo "---------------------------------------------------------------"
#
mv /etc/apache2/modsecurity-crs/modsecurity_crs_10_config.conf.example /etc/apache2/modsecurity-crs/modsecurity_crs_10_config.conf
#
echo
echo
echo
echo "Adding custom OWASP configuration"
# http://permalink.gmane.org/gmane.comp.apache.mod-security.user/8735
# https://ppmts.custhelp.com/app/answers/detail/a_id/92
echo "---------------------------------------------------------------"
#
echo "# Whitelisting notify.paypal.com(IPN)
SecRule REMOTE_ADDR \"@streq 216.113.188.202\" \"phase:1,allow,ctl:ruleEngine=off,msg:'Disabling rule-engine for IP %{REMOTE_ADDR}'\"
SecRule REMOTE_ADDR \"@streq 216.113.188.203\" \"phase:1,allow,ctl:ruleEngine=off,msg:'Disabling rule-engine for IP %{REMOTE_ADDR}'\"
SecRule REMOTE_ADDR \"@streq 216.113.188.204\" \"phase:1,allow,ctl:ruleEngine=off,msg:'Disabling rule-engine for IP %{REMOTE_ADDR}'\"
SecRule REMOTE_ADDR \"@streq 66.211.170.66\" \"phase:1,allow,ctl:ruleEngine=off,msg:'Disabling rule-engine for IP %{REMOTE_ADDR}'\"
" > /etc/apache2/modsecurity-crs/modsecurity_crs_15_custom.conf
#
echo
echo
echo
echo "Activating additonal select rulesets"
echo "---------------------------------------------------------------"
#
for f in $(ls /etc/apache2/modsecurity-crs/optional_rules/ | grep comment_spam) ; do ln -s /etc/apache2/modsecurity-crs/optional_rules/$f /etc/apache2/modsecurity-crs/activated_rules/$f ; done
for f in $(ls /etc/apache2/modsecurity-crs/slr_rules/ | grep joomla) ; do ln -s /etc/apache2/modsecurity-crs/slr_rules/$f /etc/apache2/modsecurity-crs/activated_rules/$f ; done
for f in $(ls /etc/apache2/modsecurity-crs/slr_rules/ | grep rfi) ; do ln -s /etc/apache2/modsecurity-crs/slr_rules/$f /etc/apache2/modsecurity-crs/activated_rules/$f ; done
for f in $(ls /etc/apache2/modsecurity-crs/slr_rules/ | grep lfi) ; do ln -s /etc/apache2/modsecurity-crs/slr_rules/$f /etc/apache2/modsecurity-crs/activated_rules/$f ; done
for f in $(ls /etc/apache2/modsecurity-crs/slr_rules/ | grep xss) ; do ln -s /etc/apache2/modsecurity-crs/slr_rules/$f /etc/apache2/modsecurity-crs/activated_rules/$f ; done
chown -R root:root /etc/apache2/modsecurity-crs
#
echo
echo
echo
echo "Enabling security rules engine with default setting of DetectionOnly. Possible settings are On|Off|DetectionOnly. Before changing to On, ensure that no false positives occur. For more information about SecRuleEngine, see http://www.modsecurity.org/documentation/modsecurity-apache/2.1.3/html-multipage/03-configuration-directives.html#N106E7"
# http://sourceforge.net/apps/mediawiki/mod-security/index.php?title=FAQ#Should_I_initially_set_the_SecRuleEngine_to_On.3F
echo "---------------------------------------------------------------"
#
sed -i "s/#SecRuleEngine DetectionOnly/SecRuleEngine DetectionOnly/g" /etc/apache2/modsecurity-crs/modsecurity_crs_10_config.conf





#
echo
echo
echo
echo "Setting up logs for mod_security"
echo "---------------------------------------------------------------"
#
mkdir /var/log/mod_security/
chown www-data:www-data -R /var/log/mod_security/
#
echo "
SecTmpDir /tmp
SecDataDir /var/log/mod_security
# SecDebugLog /var/log/mod_security/debug.log
# SecDebugLogLevel 3
" >> /etc/apache2/modsecurity-crs/modsecurity_crs_10_config.conf
#
echo
echo
echo
echo "Enabling mod_security"
echo "---------------------------------------------------------------"
#
echo "<IfModule security2_module>
    Include modsecurity-crs/modsecurity_crs_10_config.conf
    Include modsecurity-crs/modsecurity_crs_15_custom.conf
    Include modsecurity-crs/base_rules/*.conf
    Include modsecurity-crs/activated_rules/*.conf
</IfModule>
" > /etc/apache2/conf.d/modsecurity
#
echo
echo
echo
echo "Disabling macro support for numeric operators in ModSecurity CRS v2.2.3. We need ModSecurity 2.5.12 for their support, Lucid uses 2.5.11-1"
echo "---------------------------------------------------------------"
#
sed -i "s/SecAction \"phase:1,id:'981211',t:none,nolog,pass,setvar:tx.max_num_args=255\"/#SecAction \"phase:1,id:'981211',t:none,nolog,pass,setvar:tx.max_num_args=255\"/g" /etc/apache2/modsecurity-crs/modsecurity_crs_10_config.conf
#
echo
echo
echo
echo "Hardcoding a numeric value in place of disabled tx.max_num_args operator"
echo "---------------------------------------------------------------"
#
sed -i "s/%{tx.max_num_args}/255/g" /etc/apache2/modsecurity-crs/base_rules/modsecurity_crs_23_request_limits.conf
#
echo
echo
echo
echo "Fixing backward compatability issue in ModSecurity CRS v2.2.3. REQBODY_ERROR renamed to  REQBODY_PROCESSOR_ERROR in ModSecurity 2.6.0"
# http://permalink.gmane.org/gmane.comp.apache.mod-security.owasp-crs/411
echo "---------------------------------------------------------------"
#
sed -i "s/REQBODY_ERROR/REQBODY_PROCESSOR_ERROR/g" /etc/apache2/modsecurity-crs/base_rules/modsecurity_crs_20_protocol_violations.conf
#
echo
echo
echo
echo "One final hurrah"
echo "--------------------------------------------------------------"
echo
#
aptitude update && aptitude -y safe-upgrade
#
echo
echo
echo
echo
echo
echo
echo
echo
echo
echo
echo
echo
echo
echo
echo
echo
echo
echo
echo
echo
echo "==============================================================="
echo
echo "All done!"
echo
echo "If you are confident that all went well, reboot this puppy and play."
echo
echo "If not, now is your (last?) chance to fix things."
echo
echo "==============================================================="

