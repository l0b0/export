#!/usr/bin/env python
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
GCAL_URL_PREFIX = 'https://www.google.com/calendar/ical'
GCAL_URL_SUFFIX = 'private/basic.ics'


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
    cals = {}
    for i, a_calendar in enumerate(feed.entry):
        # Grab the calendar id and append it to the bucket.
        cals[a_calendar.title.text] = a_calendar.id.text.split('/')[-1]

    for name, url in cals.iteritems():
        # Create the ical url, we need to add the authorization header because
        # we are using the private url.  This allows us to grab all of the
        # calendars regardless if they are private or public.
        ical = os.path.join(GCAL_URL_PREFIX, url, GCAL_URL_SUFFIX)
        req = urllib2.Request(ical)
        req.add_header('Authorization', 'GoogleLogin auth=' + login_token)
        r = urllib2.urlopen(req)
        # create/open the ics file and write the retrieved ical to it.
        local = open(os.path.join(target_dir, name + '.ics'), "w")
        local.write(r.read())
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
