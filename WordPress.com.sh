#!/bin/sh
#
# NAME
#        WordPress.com.sh - Download your blog
#
# SYNOPSIS
#        WordPress.com.sh <username> <password> <WordPress.com host> <save path>
#
# DESCRIPTION
#        Downloads the blog data and metadata, including attachments.
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

#        Insert a new line with the following contents (replacing the paths,
#        credentials and host (only the part before .wordpress.com with your
#        own): #
#        @midnight "/.../export/WordPress.com.sh" "user" "password" "host" "/.../wp.xml"
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

if [ $# -ne 4 ]
then
    echo 'Wrong parameters - See the documentation on top of the script'
    exit 1
fi

username="$1"
password="$2"
hostname="${3%%.*}" # Don't need the full host name
export_path="$4"

# Authenticate
cookies_path="${export_path}.cookie"
login_url="https://${hostname}.wordpress.com/wp-login.php"

if [ -z "${DEBUG+defined}" ]
then
    trap 'rm -f -- "$cookies_path"' EXIT
fi

curl --insecure --cookie-jar "$cookies_path" --output /dev/null "$login_url"
curl --insecure --cookie "$cookies_path" --cookie-jar "$cookies_path" --output /dev/null \
    --data-urlencode "log=${username}" \
    --data-urlencode "pwd=${password}" \
    --data-urlencode "rememberme=forever" \
    --data-urlencode "wp-submit=Log In" \
    --data-urlencode "redirect_to=https://${hostname}.wordpress.com/wp-admin/" \
    --data-urlencode "testcookie=1" \
    "$login_url"

# Cookie cleansing
sed -i -e 's/#HttpOnly_//' "$cookies_path"

# Export database
export_url="https://${hostname}.wordpress.com/wp-admin/export.php?download=true&submit=Download%20Export%20File"
wget --no-check-certificate --load-cookies "$cookies_path" --output-document "$export_path" --max-redirect=0 "$export_url"

# Export files
files_parent="$(dirname -- "$export_path")"
files_root="$(basename -- "$export_path")"
files_dir="${files_parent}/${files_root%.*}_files"
perl -nle 'print for m/(?:<wp:attachment_url>)(.*)(?:<\/wp:attachment_url>)/g' "$export_path" | wget --input-file - --force-directories --no-host-directories --timestamping --directory-prefix "$files_dir"
