Export scripts
==============

These scripts are all open source and used by yours truly, which means they should be up to date pretty much all the time. Supported web sites:

* [Google Calendar](https://www.google.com/calendar/render)
* [LibraryThing](https://www.librarything.com/)
* [WordPress.com](https://wordpress.com/)

Install
-------

    git submodule update --init
    sudo make install

Use
---
Normal use is documented in each of the files. If you just want to make nightly backups, you can use the `install-crontab-*` targets to create `crontab` entries. **Make sure to make a `crontab` backup first!** I have only tested the `crontab` targets on my own machine, and I take no responsibility for any lost data.
