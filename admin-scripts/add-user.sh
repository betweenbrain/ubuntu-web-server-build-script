#!/bin/bash
# ================================================================== #
# Shell script to add a new sudoer
# ================================================================== #
# Copyright (c) 2012 Matt Thomas http://betweenbrain.com
# This script is licensed under GNU GPL version 2.0 or above
# ================================================================== #
#
read -p "Enter new user's username: " NEWUSER
#
useradd -s /bin/bash -m -d /home/$NEWUSER --user-group $NEWUSER
passwd $NEWUSER
#

