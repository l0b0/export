#!/bin/sh
#
# NAME
#        LibraryThing.sh - Download your library
#
# SYNOPSIS
#        LibraryThing.sh <username> <password> <save path>
#
# DESCRIPTION
#        Downloads the entire library of a single user in comma-separated values
#        (CSV) format.
#
#        How to save your personal library at midnight every day:
#
#        First, make sure nobody else can read your crontab. If not, they can
#        get access to your password, and I'm not good at sympathy.
#
#        $ git clone git://github.com/l0b0/export.git
#
#        $ crontab -e
#
#        Insert a new line with the following contents (replacing the paths and
#        credentials with your own):
#
#        @midnight "/.../export/LibraryThing.sh" "user" "password" "/.../lt.csv"
#
# BUGS
#        https://github.com/l0b0/export/issues
#
# COPYRIGHT AND LICENSE
#        Copyright (C) 2010-2012 Victor Engmark
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

# Authenticate
POST_DATA="formusername=${USERNAME}&formpassword=${PASSWORD}&index_signin_already=Sign%20in"
COOKIES_PATH="${EXPORT_PATH}.cookie"
SIGNUP_PATH="${EXPORT_PATH}.signup"
LOGIN_URL='https://www.librarything.com/signup.php'

wget --post-data "$POST_DATA" --keep-session-cookies --save-cookies="$COOKIES_PATH" --no-check-certificate --output-document="$SIGNUP_PATH" "$LOGIN_URL"

# Export
CHECKSUM="$(grep cookie_userchecksum $COOKIES_PATH | cut -f 7)"
USERNUM="$(grep cookie_usernum $COOKIES_PATH | cut -f 7)"
USERID="$(grep cookie_userid $COOKIES_PATH | cut -f 7)"
COOKIE="cookie_userchecksum=${CHECKSUM};cookie_usernum=${USERNUM};cookie_userid=${USERID}"
EXPORT_URL=https://www.librarything.com/export-csv

wget --no-check-certificate --header "Cookie: $COOKIE" -O "$EXPORT_PATH" "$EXPORT_URL"

# Cleanup
rm -f -- "$COOKIES_PATH" "$SIGNUP_PATH"
