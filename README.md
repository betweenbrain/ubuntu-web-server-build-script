Initial server setup
====================

A hand-rolled shell script to help you get up and running quickly  with an Ubuntu web server. While created specifically for 10.04 LTS 32-bit, efforts have been made to make it version agnostic. Please note: This is not intended to be a complete and comprehensive solution, but a starting point for your custom server.

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


Warranty, guarantees, culpability...etc.
----------------
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Use at your own risk, I do :)

Copyright
-----------------
Unless otherwise stated, this software is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

All attempts have been made to identify third party sources, copyrights, and works within in the script. If I missed something, please let me know and I'll fix it.

