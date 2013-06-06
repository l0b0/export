#!/usr/bin/python
try:
  from xml.etree import ElementTree
except ImportError:
  from elementtree import ElementTree
import gdata.calendar.service
import gdata.service
import atom.service
import gdata.calendar
#--------------------
import datetime 
import urllib2

email = ''
password = ''
backup_folder = ''

# log into google
calendar_service = gdata.calendar.service.CalendarService()
calendar_service.email = email
calendar_service.password = password
calendar_service.source = 'Google-Calendar_Backup'
calendar_service.ProgrammaticLogin()

token = calendar_service.GetClientLoginToken()

# calendar list
feed = calendar_service.GetOwnCalendarsFeed()
# calendar bucket
cals = {}
for i, a_calendar in enumerate(feed.entry):
    # Grab the calendar id and append it to the bucket.
    id_url = a_calendar.id.text
    id_parts = id_url.split('/')
    id = id_parts[-1]
    cals[a_calendar.title.text] = id

for name, url in cals.iteritems():
    # Create the ical url, we need to add the authorization header because
    # we are using the private url.  This allows us to grab all of the 
    # calendars regardless if they are private or public.
    ical = 'https://www.google.com/calendar/ical/' + url + '/private/basic.ics'
    req = urllib2.Request(ical)
    req.add_header('Authorization', 'GoogleLogin auth='+token)
    r = urllib2.urlopen(req)
    # create/open the ics file and write the retrieved ical to it.
    local = open(backup_folder+name+'.ics',"w")
    local.write(r.read())
    local.close()
