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
#        Set the DEBUG environment variable for debugging output.
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
if [ -n "${DEBUG+defined}" ]
then
    set -o xtrace
fi

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
tmp_dir="$(mktemp -d)"
if [ -z "${DEBUG+defined}" ]
then
    trap 'rm -rf -- "$tmp_dir"' EXIT
fi
cookies_path="${tmp_dir}/cookie"
signup_path="${tmp_dir}/signup"
hostname='www.librarything.com'
base_url="https://${hostname}"
login_url="${base_url}/signup.php"

wget --post-data "$post_data" --keep-session-cookies --save-cookies="$cookies_path" --output-document="$signup_path" "$login_url"

# Export
export_url="${base_url}/export-csv"
wget --load-cookies="$cookies_path" --output-document="$export_path" "$export_url"
