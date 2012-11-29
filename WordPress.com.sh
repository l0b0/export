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

if [ $# -ne 4 ]
then
    echo 'Wrong parameters - See the documentation on top of the script'
    exit 1
fi

USERNAME="$1"
PASSWORD="$2"
HOSTNAME="${3%%.*}" # Don't need the full host name
EXPORT_PATH="$4"

# Authenticate
COOKIES_PATH="${EXPORT_PATH}.cookie"
LOGIN_URL="https://${HOSTNAME}.wordpress.com/wp-login.php"

curl --insecure --cookie-jar "$COOKIES_PATH" --output /dev/null --data "log=${USERNAME}&pwd=${PASSWORD}&rememberme=forever&wp-submit=Log In&redirect_to=https://${HOSTNAME}.wordpress.com/wp-admin/&testcookie=1" "$LOGIN_URL"

# Cookie cleansing
sed -i -e 's/#HttpOnly_//' "$COOKIES_PATH"

# Export database
EXPORT_URL="https://${HOSTNAME}.wordpress.com/wp-admin/export.php?download=true&submit=Download Export File"
wget --no-check-certificate --load-cookies "$COOKIES_PATH" --output-document "$EXPORT_PATH" "$EXPORT_URL"

# Cleanup
rm -f -- "$COOKIES_PATH"

# Export files
FILES_PARENT="$(dirname -- "$EXPORT_PATH")"
FILES_ROOT="$(basename -- "$EXPORT_PATH")"
FILES_DIR="${FILES_PARENT}/${FILES_ROOT%.*}_files"
perl -nle 'print for m/(?:<wp:attachment_url>)(.*)(?:<\/wp:attachment_url>)/g' "$EXPORT_PATH" | wget --input-file - --force-directories --no-host-directories --timestamping --directory-prefix "$FILES_DIR"
