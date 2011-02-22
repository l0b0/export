#!/bin/sh
#
# NAME
#        GoogleReader.sh - Download your web feed subscriptions
#
# SYNOPSIS
#        GoogleReader.sh <username> <password> <save path>
#
# DESCRIPTION
#        Downloads the web feed subscriptions at Google Reader as an OPML file.
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
#        @midnight /.../export/GoogleReader.sh user password /.../feeds.xml
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

USERNAME="${1%%@*}" # Apply the @gmail.com part later
PASSWORD="$2"
EXPORT_PATH="$3"

# Authenticate
COOKIES_PATH="${EXPORT_PATH}.cookie"
LOGIN_URL='https://www.google.com/accounts/ServiceLogin'
wget --save-cookies="$COOKIES_PATH" --keep-session-cookies --no-check-certificate --output-document=/dev/null "$LOGIN_URL"

GALX="$(grep GALX "$COOKIES_PATH" | cut -f 7)"

POST_DATA="Email=${USERNAME}@gmail.com&Passwd=${PASSWORD}&GALX=${GALX}"
wget --post-data="$POST_DATA" --load-cookies="$COOKIES_PATH" --save-cookies="$COOKIES_PATH" --no-check-certificate --keep-session-cookies --output-document=/dev/null https://www.google.com/accounts/ServiceLoginAuth

# Export
EXPORT_URL=https://www.google.com/reader/subscriptions/export
wget --no-check-certificate --load-cookies="$COOKIES_PATH" --output-document="$EXPORT_PATH" "$EXPORT_URL"

# Cleanup
rm -f -- "$COOKIES_PATH"
