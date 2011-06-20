#!/usr/bin/perl
# -----------------------------------------
# Program : lfmCOL.pl (Generic last.fm Data Collector (last.fm -> xml))
# Version : 0.1.0 - 2009-08-26
#           0.1.1 - 2009-08-28 help screen modified
#           0.2.0 - 2009-09-02 parameter "-maxpages" added
#           0.3.0 - 2009-11-07 user.getRecentTracks added
#           0.4.0 - 2010-02-10 user.getArtistTracks added
#           0.4.1 - 2010-04-25 help text modified
#           0.5.0 - 2010-09-18 geo.getEvents, user.getRecommendedEvents added
#           0.6.0 - 2010-12-03 album.getShouts, artist.getPastEvents, chart.getHypedArtists,
#                              chart.getHypedTracks, chart.getLovedTracks, chart.getTopArtists,
#                              chart.getTopTags, chart.getTopTracks, track.getShouts,
#                              user.getBannedTracks, user.getPersonalTags (for tracks only),
#                              venue.getPastEvents added
#
# Copyright (C) 2009, 2010 Klaus Tockloth
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# Contact (eMail): <Klaus.Tockloth@googlemail.com>
#
# Further information:
# - last.fm API Documentation (Last.fm Ltd.)
#
# Test:
# - Windows (XP)
# - Linux (Ubuntu 9.04)
# - OS-X (10.6.4)
# - checked with Perl::Critic (severity 2)
#
# Know bug:
# - utf8 double encoding in logfile (for command line parameters)
# -----------------------------------------

use warnings;
use strict;

# General
use English;
use Getopt::Long;

# lastfm
use File::Basename;
use LWP::UserAgent;
use URI::QueryParam;
use Encode;
use XML::Simple;
use Digest::MD5 qw(md5_hex);

# Debug
use Data::Dumper;

my $EMPTY = q{};

my $lastfm_response = $EMPTY;
my $lastfm_xmlref = $EMPTY;

my $parse_error = 0;
my $http_error = 0;

# command line parameters
my $help = $EMPTY;
my $maxpages = -1;
my $xmlfile = $EMPTY;
my $logging = 0;

my %params = ();
my $ua = $EMPTY;
my $info = $EMPTY;

# last.fm response - example for "user.getLovedTracks":
# 
# <lovedtracks user="Linuxology" total="66" page="1" perPage="50" totalPages="2">
#     <track>
#         <name>As the World Burns</name>
#         ...
#     </track>
#     ...
# </lovedtracks>

# supported last.fm webservice
my %lastfm_webservice = 
(
  # Album
  'album.getShouts'           => ['shouts',          'shout',   'totalPages'],

  # Artist
  'artist.getPastEvents'       => ['events',          'event',   'totalPages'],
  'artist.getImages'           => ['images',          'image',   'totalpages'],
  'artist.getShouts'           => ['shouts',          'shout',   'totalPages'],

  # Chart
  'chart.getHypedArtists'      => ['artists',         'artist',  'totalPages'],
  'chart.getHypedTracks'       => ['tracks',          'track',   'totalPages'],
  'chart.getLovedTracks'       => ['tracks',          'track',   'totalPages'],
  'chart.getTopArtists'        => ['artists',         'artist',  'totalPages'],
  'chart.getTopTags'           => ['tags',            'tag',     'totalPages'],
  'chart.getTopTracks'         => ['tracks',          'track',   'totalPages'],

  # Geo
  'geo.getEvents'              => ['events',          'event',   'totalpages'],

  # Group
  'group.getMembers'           => ['members',         'user',    'totalPages'],

  # Library
  'library.getAlbums'          => ['albums',          'album',   'totalPages'],
  'library.getArtists'         => ['artists',         'artist',  'totalPages'],
  'library.getTracks'          => ['tracks',          'track',   'totalPages'],

  # Track
  'track.getShouts'           => ['shouts',          'shout',   'totalPages'],

  # User
  'user.getArtistTracks'       => ['artisttracks',    'track',   'totalPages'],
  'user.getBannedTracks'       => ['bannedtracks',    'track',   'totalPages'],
  'user.getFriends'            => ['friends',         'user',    'totalPages'],
  'user.getLovedTracks'        => ['lovedtracks',     'track',   'totalPages'],
  'user.getPastEvents'         => ['events',          'event',   'totalPages'],
  # 'user.getPersonalTags'       => ['taggings',        'artists', 'totalPages'],
  # 'user.getPersonalTags'       => ['taggings',        'albums',  'totalPages'],
  'user.getPersonalTags'       => ['taggings',        'tracks',  'totalPages'],
  'user.getRecentStations'     => ['recentstations',  'station', 'totalPages'],
  'user.getRecentTracks'       => ['recenttracks',    'track',   'totalPages'],
  'user.getRecommendedArtists' => ['recommendations', 'artist',  'totalPages'],
  'user.getRecommendedEvents'  => ['events',          'event',   'totalPages'],

  # Venue
  'venue.getPastEvents'        => ['events',          'event',   'totalPages'],
);

# configuration defaults (overwritten by read_Program_Configuration())
my $terminal_encoding = 'utf8';
use constant HTTP_TIMEOUT => 53;
my $httpTimeout = HTTP_TIMEOUT;
my $httpProxy = $EMPTY;

my ($appbasename, $appdirectory, $appsuffix) = fileparse($0, qr/\.[^.]*/);
my $logfile = $appbasename . '.log';
my $cfgfile = $appbasename . '.cfg';

my $appfilename = basename($0);

my $cfgfile_found = 0;
read_Program_Configuration();

# set STDOUT to configured terminal encoding
binmode STDOUT, ":encoding($terminal_encoding)";

my $proginfo = "$appfilename - Generic last.fm Data Collector (last.fm -> xml), Rel. 0.6.0 - 2010-12-03";
printf {*STDOUT} "\n%s\n\n", $proginfo;

# commandline parameters will overwrite configuration parameters
GetOptions('h|?'        => \$help,
           'maxpages=i' => \$maxpages, 
           'xmlfile=s'  => \$xmlfile,
           'logging=i'  => \$logging,
          );

if (($help) || ($xmlfile eq $EMPTY)) {
  show_help();
}

if ($#ARGV < 0) {
  show_help();
}

# copy the key/value pairs into a hash (enforce utf8 encoding)
for (my $i = 0; $i <= $#ARGV; $i++) {
  my ($key, $value) = split /=/, $ARGV[$i], 2;

  # encode all command line input parameters to 'utf8'
  if (lc $terminal_encoding eq 'utf8') {
    # data is already utf8 encoded (nothing to do)
  }
  else {
    $key = encode_utf8($key);
    $value = encode_utf8($value);
  }

  $params{$key} = $value;
}

my $lfm_method = $params{'method'};
if (! defined $lfm_method) {
  printf {*STDOUT} "Error: no method defined !\n";
  exit 1;
}

if (! $lastfm_webservice{$lfm_method}) {
  printf {*STDOUT} "Error: method <%s> not supported !\n", $lfm_method;
  exit 1;
}

# keys for XML parsing
my @value = @{$lastfm_webservice{$lfm_method}};
my $lfm_root = $value[0];
my $lfm_element = $value[1];
my $lfm_totalPages = $value[2];

if ($logging) {
  if (not defined open LOGFILE, '+>:utf8', $logfile) {
    die "Error opening logfile \"$logfile\": $!\n";
  }
}

if ($logging) {
  printf {*LOGFILE} "%s\n\n", $proginfo;
  printf {*LOGFILE} "Timestamp .....: %s (localtime)\n",                    scalar localtime;
  printf {*LOGFILE} "Timestamp .....: %s (gmtime)\n",                       scalar gmtime;
  printf {*LOGFILE} "Configuration .: cfgfile = %s (%s)\n",                 $cfgfile, ($cfgfile_found ? 'found' : 'not_found');
  printf {*LOGFILE} "Configuration .: logging = %s\n",                      $logging;
  printf {*LOGFILE} "Configuration .: terminal_encoding = %s (expected)\n", $terminal_encoding;
  printf {*LOGFILE} "Configuration .: httpProxy = %s\n",                    $httpProxy;
  printf {*LOGFILE} "Configuration .: httpTimeout = %s\n",                  $httpTimeout;
  printf {*LOGFILE} "System ........: OSNAME = %s\n",                       $OSNAME;
  printf {*LOGFILE} "System ........: PERL_VERSION = %s\n",                 $PERL_VERSION;
  printf {*LOGFILE} "Parameter .....: maxpages = %s\n",                     $maxpages;
  printf {*LOGFILE} "Parameter .....: xmlfile = %s\n",                      $xmlfile;
  printf {*LOGFILE} "Parameter .....: logging = %s\n",                      $logging;
  for (my $i = 0; $i <= $#ARGV; $i++) {
    printf {*LOGFILE} "Parameter .....: %s\n",                              $ARGV[$i];
  }
}

# create an internet user agent
$ua = LWP::UserAgent->new;
$ua->agent('lfmCOL/0.1');
$ua->timeout($httpTimeout);
if ($httpProxy ne $EMPTY) {
  $ua->proxy('http', $httpProxy);
}

fetch_lastfm_data();

if ($logging) {
  printf {*STDOUT} "\nSee log file \"%s\" for processing details.\n", $logfile;
  close LOGFILE or die "Error closing logfile \"$logfile\": $!\n";
}
exit 0;


# -----------------------------------------
# Fetch paginated last.fm data.
# -----------------------------------------
sub fetch_lastfm_data
{
  if ($logging) {
    printf {*LOGFILE} "\nfunction fetch_lastfm_data():\n";
    printf {*LOGFILE} ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n";
  }

  my $pagesfetched = 0;
  my $pageindex = 1;
  my $pagestotal = '?';

  # a start page was defined on the command line  
  if (defined $params{page}) {
    $pageindex = $params{page};
  }

  # xml reference (resulting structure)
  my $xmlref = {};
  my $xmlindex = 0;

  while (1) {
    $info = "fetching page $pageindex / $pagestotal ... ";
    printf {*STDOUT} "%s", $info;
    if ($logging) { printf {*LOGFILE} "\n%s\n", $info; }

    $params{page} = $pageindex;
    lastfm_request_service(\%params);

    # communications error?
    if ($http_error) {
      if ($lastfm_response->code >= 500) {
        # server or gateway http errors (500-599): try again
        $info = sprintf "server or gateway error <%s> (trying again)", $lastfm_response->status_line;
        printf {*STDOUT} "%s\n", $info;
        if ($logging) { printf {*LOGFILE} "%s\n", $info; }
        sleep 1; # we are fair to the server
        next;
      }
      else {
        # all other http errors (100-499): exit
        $info = sprintf "bad http error <%s> (exit program)", $lastfm_response->status_line;
        printf {*STDOUT} "%s\n", $info;
        if ($logging) { printf {*LOGFILE} "%s\n", $info; }
        return;
      }
    }

    # xml parsing error?
    if ($parse_error) {
      $info = "error parsing last.fm xml response (skipping page)";
      printf {*STDOUT} "%s\n", $info;
      if ($logging) { printf {*LOGFILE} "%s\n", $info; }
      $pageindex++;
      $pagesfetched++;
      sleep 1; # we are fair to the server
      next;
    }

    # page successfully fetched
    $pagesfetched++;

    $pagestotal = $lastfm_xmlref->{$lfm_root}->[0]->{$lfm_totalPages};
    printf {*STDOUT} "OK\n", $info;
    if ($logging) { printf {*LOGFILE} "\nfetching page $pageindex / $pagestotal ... OK\n"; }

    # process the last.fm XML response
    foreach my $element (@{$lastfm_xmlref->{$lfm_root}->[0]->{$lfm_element}}) {
      $xmlref->{$lfm_element}->[$xmlindex] = $element;
      $xmlindex++;
    }

    if ($maxpages > 0) {
      if ($pagesfetched >= $maxpages) {
        last;
      }
    }

    if ($pageindex >= $pagestotal) {
      last;
    }
    else {
      $pageindex++;
      sleep 1; # we are fair to the server
    }
  }

  $info = "generating xml file ... ";
  printf {*STDOUT} "\n%s", $info;
  if ($logging) { printf {*LOGFILE} "\n%s", $info; }

  XMLout($xmlref,
         OutputFile => $xmlfile,
         RootName => $lfm_root,
         SuppressEmpty => 1,
         NumericEscape => 0,
         XMLDecl => '<?xml version="1.0" encoding="UTF-8"?>'
        );

  $info = "done";
  printf {*STDOUT} "%s\n", $info;
  if ($logging) { printf {*LOGFILE} "%s\n", $info; }

  $info = sprintf "See xml file \"%s\" for processing results.", $xmlfile;
  printf {*STDOUT} "\n%s\n", $info;
  if ($logging) { printf {*LOGFILE} "\n%s\n", $info; }

return;
}


# -----------------------------------------
# Request a last.fm service - send http get/post request and decode xml response.
# -----------------------------------------
sub lastfm_request_service
{
  my %lfmParams = %{(shift)};  # copy data to new hash

  my $lastfm_api_key = '0996e89f272c714ec0bd463ea17faf6c';
  my $lastfm_api_secret = 'aced25823414f7398e60a0323eff1741';
  my $lastfm_service_root = 'http://ws.audioscrobbler.com/2.0/';
  my $lastfm_service_uri = $EMPTY;
  my $rc = 0;

  if ($logging) {
    printf {*LOGFILE} "\nlast.fm request:\n----------------\n";
    printf {*LOGFILE} "Timestamp .....: %s\n", scalar localtime;
  }

  # add "api_key" to "%params"
  $lfmParams{api_key} = $lastfm_api_key;

  # write all parameters to logfile
  foreach my $key (sort keys %lfmParams) {
    my $value = $lfmParams{$key};
    if ($logging) { printf {*LOGFILE} "Parameter .....: %s = %s\n", $key, $value; }
  }

  # build the hash string
  my $hashstring = $EMPTY;
  foreach my $key (sort keys %lfmParams) {
    my $value = $lfmParams{$key};
    $hashstring .= $key . $value;
  }
  # add "api_secret" to hash string
  $hashstring .= $lastfm_api_secret;

  # calculate hash value and add "api_sig" to "%lfmParams"
  $lfmParams{api_sig} = md5_hex($hashstring);

  # build URI (last.fm request) (inclusive UTF8 escaping)
  $lastfm_service_uri = URI->new($lastfm_service_root);
  foreach my $key (sort keys %lfmParams) {
    my $value = $lfmParams{$key};
    $lastfm_service_uri->query_param($key, $value);
  }
  if ($logging) { printf {*LOGFILE} "Service URI ...: %s\n", $lastfm_service_uri; }

  # use "post" (instead of "get") if "sk" (session key) is given
  if (defined $lfmParams{sk}) {
    # last.fm write service
    $lastfm_response = $ua->post($lastfm_service_uri);
  }
  else {
    # last.fm read service
    $lastfm_response = $ua->get($lastfm_service_uri);
  }

  if ($logging) {
    printf {*LOGFILE} "\nlast.fm xml response:\n---------------------\n";
    printf {*LOGFILE} "%s", $lastfm_response->decoded_content;

    printf {*LOGFILE} "\nlast.fm response:\n-----------------\n";
    printf {*LOGFILE} "http status ...: %s\n", $lastfm_response->status_line;
  }

  $http_error = 0;
  if (! $lastfm_response->is_success) {
    $http_error = 1;
    $rc = 1;
  }

  # transfer xml response to perl data structure - force everything into arrays
  # eval() avoids that the call dies (eg. due to parsing errors)
  $parse_error = 0;
  $lastfm_xmlref = eval { XMLin($lastfm_response->decoded_content, ForceArray => 1) };
  if ($@) {
    $parse_error = 1;
    if ($logging) { printf {*LOGFILE} "Error <%s> parsing last.fm xml response !\n", $@; }
    $rc = 2;
  }
  else {
    if ($logging) {
      printf {*LOGFILE} "last.fm status : %s\n", $lastfm_xmlref->{status};
      # printf {*LOGFILE} "Parsed xml     : %s\n", Dumper($lastfm_xmlref);
    }
  }

# 0=successful; 1/2=not successful
return $rc;
}


# -----------------------------------------
# Show help and exit.
# -----------------------------------------
sub show_help
{
  printf {*STDOUT}
        "Copyright (C) 2009, 2010 Klaus Tockloth <Klaus.Tockloth\@googlemail.com>\n" .
        "This program comes with ABSOLUTELY NO WARRANTY. This is free software,\n" .
        "and you are welcome to redistribute it under certain conditions.\n" .
        "\n" .
        "Usage:\n" .
        "perl $appfilename  [-maxpages=N] -xmlfile=\"Name\" [-logging=0|1] method=\"name\" [param1=\"value\"] ... [paramN=\"value\"]\n" .
        "\n" .
        "Examples:\n" .
        "perl $appfilename  -xmlfile=myRecentTracks.xml         method=user.getRecentTracks  limit=50  user=toc-rox\n" .
        "perl $appfilename  -xmlfile=myLovedTracks.xml          method=user.getLovedTracks  user=toc-rox\n" .
        "perl $appfilename  -xmlfile=ArethaImages.xml           method=artist.getImages     artist=\"Aretha Franklin\"\n" .
        "perl $appfilename  -xmlfile=Albums_maz35.xml           method=library.getAlbums    user=maz35\n" .
        "perl $appfilename  -xmlfile=Artists_maz35.xml          method=library.getArtists   user=maz35\n" . 
        "perl $appfilename  -xmlfile=Tracks_maz35.xml           method=library.getTracks    user=maz35\n" .
        "perl $appfilename  -xmlfile=\"Members_Webservices.xml\"  method=group.getMembers     group=\"Last.fm Web Services\"\n" .
        "\n" .
        "perl $appfilename  -maxpages=10  -xmlfile=Tracks_maz35.xml  method=library.getTracks  user=maz35\n" .
        "perl $appfilename  -maxpages=10  -xmlfile=Tracks_maz35.xml  method=library.getTracks  user=maz35  page=22\n" .
        "\n" .
        "-h | -?   = show help (this)\n" .
        "-maxpages = maximum number of pages to be fetched (default=-1 [no limit])\n" .
        "-xmlfile  = (to) xml data file\n" .
        "-logging  = 0=OFF / 1=ON; logfile=\"$logfile\"\n" .
        "\n" .
        "General information:\n" .
        "- How to get a session key (sk)? : See documentation of \"lfmCMD.pl\".\n" .
        "- Configuration file settings    : See xml file \"$cfgfile\".\n" .
        "\n" .
        "Supported last.fm methods:\n";

  foreach my $key (sort keys %lastfm_webservice) {
    printf {*STDOUT} "- %s\n", $key;
  }

exit 1;
}


# -----------------------------------------
# Read program configuration (from cfg/xml file).
# -----------------------------------------
sub read_Program_Configuration
{
  if (! (-s $cfgfile)) {
    return;
  }
  $cfgfile_found = 1;

  # SuppressEmpty => 1 : skip undefined values (eg. <logging></logging>)
  my $config = XMLin($cfgfile, SuppressEmpty => 1);
  # print Dumper($config);

  if (defined $config->{logging}) {
    $logging = $config->{logging};
  }

  if (defined $config->{terminal_encoding}) {
    $terminal_encoding = $config->{terminal_encoding};
  }

  if (defined $config->{http}->{timeout}) {
    $httpTimeout = $config->{http}->{timeout};
  }

  if (defined $config->{http}->{proxy}) {
    $httpProxy = $config->{http}->{proxy};
  }

return;
}
