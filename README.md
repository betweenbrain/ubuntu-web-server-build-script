Initial server setup
====================

A hand-rolled bash shell script to help you get up and running quickly with an Ubuntu 10.04 web server  (Apache2 MPM Worker, MySQL, PHP5, suexec, fcgid).

Please note: This is not intended to be a complete and comprehensive solution, but a starting point for your custom server. Tweak, modify and adjust as needed and desired.

Basic security and essential packages are included. For security and performance reasons, no GUI solutions have been included.

Features
-----------------
This script does a bunch of things. The general run down is that it:

*   Updates your server and configures a number of general settings, such as your hostname, server IP address, timezone ...etc.
*   Securely configures SSH to listen on a custom port, while restricted to a single IP address, disables root SSH login, disables password access, and grants your new admin user (also a sudoer) SSH access via an SSH key.
*   Configures IPTables so that you server only accepts and sends data on ports 80, 443 and your custom port for SSH. Also allows sending on port 25 for sendmail/postifx.
*   Adds a basic DoS rule to IPTables, with logging.
*   Two scripts are added so that IPTables rules are saved and re-loaded when rebooting.
*   Installs and configures Apache2 (MPM Worker), MySQL, PHP5, suExec, fcgid, as well as creates and enables a new site under your admin user's account.
*   Installs and configures  mod_evasive, fail2ban, and mod_security. Your admin user's IP address is white-listed from these security services and a mod_security filter is added to fail2ban. OWASP rules for mod_security v2.2.3 are fetched, configured, and a select set of rules, beyond the base rules, are loaded.
  NOTE: The OWASP rules are configured for DetectionOnly by default. You will need to change that to On when you are comfortable that they are not too many false positives.
  ANOTHER NOTE: As Ubuntu 10.04 uses mod_security 2.5.11-1, backwards compatibility workarounds are implemented. Read the script and see them for yourself ;)

Getting started
----------------

1. Before you do anything else, thoroughly review [build.sh](https://github.com/betweenbrain/ubuntu-web-server-build-script/blob/master/build.sh). You need to understand what it is doing.
2. Then, fire up your VM or VPS with a fresh install of Ubuntu 10.04, connect via SSH and become the Root user.
3. Upload [build.sh](https://github.com/betweenbrain/ubuntu-web-server-build-script/blob/master/build.sh) to your server -OR- create a new shell script via `$ nano build.sh` and copy/paste the contents of [build.sh](https://github.com/betweenbrain/ubuntu-web-server-build-script/blob/master/build.sh) into it.
4. Make your script executable `$ chmod +x build.sh`
5. Let 'er rip! `$ ./build.sh` and follow the on-screen prompts.

When running this script, please keep an eye on things (they tend to happen fast) and keep an eye out for errors.
If you observe any erros while executing this script, please [create an issue report](https://github.com/betweenbrain/ubuntu-web-server-build-script/issues?sort=created&direction=desc&state=open).

Need a VPS? Get one from [Linode](http://www.linode.com/?r=e0368c8dce7aa292de419c36ae0078f64d6d4233), they rock!

What's Next?
------------
Here are a few ideas:

*   Grab a copy of mysqltuner.pl and tweak your mysql install `wget http://mysqltuner.pl/mysqltuner.pl` run with `perl mysqltuner.pl` and follow the recommendations. Some may include:
  *   Disable innob: `sed -i "s/ssl-key=\/etc\/mysql\/server-key.pem/ssl-key=\/etc\/mysql\/server-key.pem\n\nskip-innodb\n/g" /etc/mysql/my.cnf`
  *   Limit MySQL queries: `sed -i "s/#max_connections/max_connections/g" /etc/mysql/my.cnf`
  *   Enable slow query logging: `sed -i "s/#log_slow_queries/log_slow_queries/g" /etc/mysql/my.cnf`<br>
`sed -i "s/#long_query_time/long_query_time/g" /etc/mysql/my.cnf`
  *   Set query cache type: `sed -i "s/query_cache_size        = 16M/query_cache_size        = 16M\nquery_cache_type        = 1\n/g" /etc/mysql/my.cnf`
  *   Enable table cache: `sed -i "s/#table_cache/table_cache/g" /etc/mysql/my.cnf`
*   Keep an eye on your logs and adjust mod_security / fail2ban accordingly
*   Keep things up to date. For example `sudo aptitude safe-upgrade`
*   Add a new database, with a corresponding user, with [add-db.sh](https://github.com/betweenbrain/ubuntu-web-server-build-script/blob/master/admin-scripts/add-db.sh)
*   Add email aliases to postfix:
  *  `sudo nano /etc/postfix/virtual`
  *  Add: `alias email@foo.bar`
  *  `sudo postmap /etc/postfix/virtual`
*  Make sure that you own your bash history file `sudo chown you:you ~/.bash_history`


Warranty, guarantees, culpability...etc.
----------------
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Use at your own risk, I do :)

Parts copyright
-----------------
Unless otherwise stated, this software is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

All attempts have been made to identify third party sources, copyrights, and works within in the script. If I missed something, please let me know and I'll fix it.

