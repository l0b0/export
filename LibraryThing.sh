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
#        Copyright (C) 2010-2014 Victor Engmark
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

username="$1"
password="$2"
export_path="$3"

# Authenticate
post_data="formusername=${username}&formpassword=${password}&index_signin_already=Sign%20in"
cookies_path="${export_path}.cookie"
signup_path="${export_path}.signup"
trap 'rm -f -- "$cookies_path" "$signup_path"' EXIT
if [ -n "${DEBUG+defined}" ]
then
    trap '' EXIT
fi
login_url='https://www.librarything.com/signup.php'

wget --post-data "$post_data" --keep-session-cookies --save-cookies="$cookies_path" --no-check-certificate --output-document="$signup_path" "$login_url"

# Export
checksum="$(grep cookie_userchecksum $cookies_path | cut -f 7)"
usernum="$(grep cookie_usernum $cookies_path | cut -f 7)"
userid="$(grep cookie_userid $cookies_path | cut -f 7)"
cookie="cookie_userchecksum=${checksum};cookie_usernum=${usernum};cookie_userid=${userid}"
export_url=https://www.librarything.com/export-csv

wget --no-check-certificate --header "Cookie: $cookie" -O "$export_path" "$export_url"
