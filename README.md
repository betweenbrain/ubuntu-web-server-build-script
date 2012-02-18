Initial server setup
====================

A hand-rolled shell script to help you get up and running quickly with an Ubuntu web server. While created specifically for 10.04 LTS 32-bit, efforts have been made to make it version agnostic. Please note: This is not intended to be a complete and comprehensive solution, but a starting point for your custom server.

Basic security and essential packages are included. For security and performance reasons, no GUI based solutions have been included.

Getting started
----------------

1. Please, please, please review [build.txt](https://github.com/betweenbrain/ubuntu-web-server-build-script/blob/master/build.txt) line by line. You need to understand what it is doing.
2. Fire up your VM or VPS, and SSH in as Root.
3. Create a new script `$ nano build.sh`
4. Copy/paste the contents of build.txt into your editor.
5. Make your script executable `$ chmod +x build.sh`
6. Let 'er rip! `$ ./build.sh` and follow the on-screen prompts.

Need a VPS? Grab one at [Linode](http://www.linode.com/?r=e0368c8dce7aa292de419c36ae0078f64d6d4233)

What's Next?
------------
There are many things to do next, but here are a few ideas:
  - Grab a copy of mysqltuner.pl and tweak your mysql install `wget http://mysqltuner.pl/mysqltuner.pl` (run with `perl mysqltuner.pl` and follow the recomendations. I.e. `sed -i "s/ssl-key=\/etc\/mysql\/server-key.pem/ssl-key=\/etc\/mysql\/server-key.pem\n\nskip-innodb\n/g" /etc/mysql/my.cnf`)
  - Keep an eye on your logs and adjust mod_security / fail2ban accordingly
  - Keep things up to date `sudo aptitude safe-upgrade`
  - Add a new databse and user (https://help.ubuntu.com/community/ApacheMySQLPHP):
    `mysql -u root -p`<br>
    `mysql> CREATE DATABASE database1;`<br>
    `mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON database1.* TO 'yourusername'@'localhost' IDENTIFIED BY 'yourpassword';`<br>
    `mysql> \q`

Notes (a.k.a. what I learned)
-----------------
###suPHP was a pain to overcome. Here's the deal###
  - While `php5-cgi` is the package everyone says you need for suPHP, `libapache2-mod-php5` was also needed.
  - `suPHP_ConfigPath` is needed to be added to each site's VirtualHost, in this case pointed to one level above the web root. This is where we have a php.ini file that contains custom settings (in leau of /etc/php5/apache2/php.ini)
  - suPHP's default `docroot` is ${HOME}/public_html, whereas mine originally was ${HOME}/www. I changed my convention to match theirs in case of future upgrades overwritting their config file (which could wipe out any changes I make to it).



Warranty, guarantees, culpability...etc.
----------------
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Use at your own risk, I do :)

Copyright
-----------------
Unless otherwise stated, this software is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

All attempts have been made to identify third party sources, copyrights, and works within in the script. If I missed something, please let me know and I'll fix it.

