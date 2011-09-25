#!/bin/sh
#
# NAME
#        GoogleAuth.sh - Authenticate with Google services
#
# SYNOPSIS
#        . GoogleAuth.sh
#
# DESCRIPTION
#        Authenticates with Google and stores a session cookie in $COOKIES_PATH
#        to be used by Google export scripts.
#
# BUGS
#        https://github.com/l0b0/export/issues
#
# COPYRIGHT AND LICENSE
#        Copyright (C) 2011 Victor Engmark
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

# Authenticate
LOGIN_URL='https://accounts.google.com/ServiceLogin?service='$SERVICE
wget --save-cookies="$COOKIES_PATH" --keep-session-cookies --no-check-certificate --output-document=/dev/null "$LOGIN_URL"

GALX="$(grep GALX "$COOKIES_PATH" | cut -f 7)"

POST_DATA="Email=${USERNAME}@gmail.com&Passwd=${PASSWORD}&GALX=${GALX}"
wget --post-data="$POST_DATA" --load-cookies="$COOKIES_PATH" --save-cookies="$COOKIES_PATH" --no-check-certificate --keep-session-cookies --output-document=/dev/null https://accounts.google.com/ServiceLoginAuth?service=$SERVICE
