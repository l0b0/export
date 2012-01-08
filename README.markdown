Export scripts
==============

These scripts are all open source and used by yours truly, which means they should be up to date pretty much all the time. Supported web sites:

* [Delicious](https://delicious.com/)
* [Google Calendar](https://www.google.com/calendar/render)
* [Google Reader](https://www.google.com/reader/)
* [last.fm](http://www.last.fm/)
* [LibraryThing](https://www.librarything.com/)
* [WordPress.com](https://wordpress.com/)

Install
-------

    sudo make install

Use
---
Normal use is documented in each of the files. If you just want to make nightly backups, you can use the `install-crontab-*` targets to create `crontab` entries. **Make sure to make a `crontab` backup first!** I have only tested the `crontab` targets on my own machine, and I take no responsibility for any lost data.

`last.fm.pl`
------------
This is a copy of Klaus Tockloth's excellent [lfmCOL.pl](http://www.easyclasspage.de/lastfm/seite-12.html). Please refer to his page for documentation and updates.
