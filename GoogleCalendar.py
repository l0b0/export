#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Google Calendar backup script

Synopsis:

GoogleCalendar.py <username> <password> <prefix>

Description:

The username can be either your full email address or just the part before the
"@" sign - if one doesn't work, try the other (they both worked for me).

If you use two-factor authentication, the password *must* be an
application-specific password. You can create one at
<https://accounts.google.com/IssuedAuthSubTokens>.

Example:

GoogleCalendar.py john.doe abcd1234efgh5678 ~/calendars

Copyright (C) 2011 Lucas David-Roesler
Copyright (C) 2013-2014 Victor Engmark

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""
try:
    from xml.etree import ElementTree
except ImportError:
    from elementtree import ElementTree
import atom.service
import datetime
import gdata.calendar
import gdata.calendar.service
import gdata.service
import os
import sys
import urllib2

CALENDAR_SERVICE = gdata.calendar.service.CalendarService()
CALENDAR_SERVICE.source = 'Google-Calendar_Backup'
GOOGLE_CALENDAR_URL_PREFIX = 'https://www.google.com/calendar/ical'
GOOGLE_CALENDAR_URL_SUFFIX = 'private/basic.ics'


def auth(username, password):
    """
    Log in to Google

    Returns the client login token
    """
    CALENDAR_SERVICE.email = username
    CALENDAR_SERVICE.password = password
    CALENDAR_SERVICE.ProgrammaticLogin()

    return CALENDAR_SERVICE.GetClientLoginToken()


def backup(login_token, target_dir):
    """
    Back up all calendars
    """
    # calendar list
    feed = CALENDAR_SERVICE.GetOwnCalendarsFeed()
    # calendar bucket
    calendars = {}
    for i, a_calendar in enumerate(feed.entry):
        # Grab the calendar id and append it to the bucket.
        calendars[a_calendar.title.text] = a_calendar.id.text.split('/')[-1]

    for name, url in calendars.iteritems():
        # Create the ical url, we need to add the authorization header because
        # we are using the private url.  This allows us to grab all of the
        # calendars regardless if they are private or public.
        ical_url = os.path.join(GOOGLE_CALENDAR_URL_PREFIX, url, GOOGLE_CALENDAR_URL_SUFFIX)
        request = urllib2.Request(ical_url)
        request.add_header('Authorization', 'GoogleLogin auth=' + login_token)
        r = urllib2.urlopen(request)
        # create/open the ics file and write the retrieved ical to it.
        local = open(os.path.join(target_dir, name + '.ics'), "w")
        for line in urllib2.urlopen(request):
            if not line.startswith('DTSTAMP:'):
                local.write(line)
        local.close()


class UsageError(Exception):
    """Raise in case of invalid parameters."""
    def __init__(self, message):
        Exception.__init__(self)
        self._message = message

    def __str__(self):
        return self._message.encode('utf-8')


def main(argv=None):
    """Argument handling."""

    if argv is None:
        argv = sys.argv

    if len(argv) != 4:
        raise UsageError(__doc__)

    username = argv[1]
    password = argv[2]
    target_dir = argv[3]

    backup(auth(username, password), target_dir)

if __name__ == '__main__':
    sys.exit(main())
