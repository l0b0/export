#!/bin/sh
#
# NAME
#        GoogleCalendar.sh - Download your calendars
#
# SYNOPSIS
#        GoogleCalendar.sh <username> <password> <save directory>
#
# DESCRIPTION
#        Downloads your Google Calendar iCal files as single files and removes
#        the DTSTAMP entries (they just contain the export time).
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
#        @midnight /.../export/GoogleCalendar.sh user password /.../calendars
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
directory="$(dirname -- "$(readlink -fn -- "$0")")"
COOKIES_PATH="${EXPORT_PATH}.cookie"
AUTH_SCRIPT="${directory}/GoogleAuth.sh"
if ! [ -e "$AUTH_SCRIPT" ]
then
    echo "$AUTH_SCRIPT is missing." >&2
    echo "You need to download https://github.com/l0b0/export/blob/master/GoogleAuth.sh and put it in the same directory as this script." >&2
    exit 1
fi
. "$AUTH_SCRIPT"

# Export
EXPORT_URL=https://www.google.com/calendar/exporticalzip
EXPORT_FILE="${EXPORT_PATH}/calendars.zip"
wget --no-check-certificate --load-cookies="$COOKIES_PATH" --output-document="$EXPORT_FILE" "$EXPORT_URL"
unzip -o -d "$EXPORT_PATH" "$EXPORT_FILE"

# Cleanup
sed -i -e '/^DTSTAMP:/d' "$EXPORT_PATH"/*
rm -f -- "$COOKIES_PATH" "$EXPORT_FILE"
