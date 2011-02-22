#!/bin/sh
#
# NAME
#        Delicious.sh - Download your bookmarks
#
# SYNOPSIS
#        Delicious.sh <username> <password> <save path>
#
# DESCRIPTION
#        Downloads the bookmarks at Delicious as an XML file.
#
#        How to export at midnight every day:
#
#        First, make sure nobody else can read your crontab. If not, they can
#        get access to your password, and I'm not good at sympathy.
#
#        $ git clone git://github.com/l0b0/export.git
#
#        $ crontab -e
#
#        Insert a new line with the following contents (replacing the example
#        paths and login with your own):
#
#        @midnight /.../export/Delicious.sh user password /.../bookmarks.xml
#
# BUGS
#        https://github.com/l0b0/export/issues
#
# COPYRIGHT AND LICENSE
#        Copyright (C) 2010, 2011 Victor Engmark
#
#        This program is free software: you can redistribute it and/or modify
#        it under the terms of the GNU General Public License as published by
#        the Free Software Foundation, either version 3 of the License, or
#        (at your option) any later version.
#
#        This program is distributed in the hope that it will be useful,
#        but WITHOUT ANY WARRANTY; without even the implied warranty of
#        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#        GNU General Public License for more details.
#
#        You should have received a copy of the GNU General Public License
#        along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################
set -o errexit -o nounset

if [ $# -ne 3 ]
then
    echo 'Wrong parameters - See the documentation on top of the script'
    exit 1
fi

USERNAME="$1"
PASSWORD="$2"
EXPORT_PATH="$3"

# Export
EXPORT_URL=https://api.del.icio.us/v1/posts/all
wget --user="$USERNAME" --password="$PASSWORD" -O "$EXPORT_PATH" --no-check-certificate "$EXPORT_URL"
