glassfishinstall
================

Linux Glassfish Install script

The script makes a bunch of assumptions about where Java is installed.
See the script for detail.

*Usage*
* Download a recent version of Glassfish from here: http://glassfish.java.net/downloads
* Drop the zip archive in the same directory as ./installglassfish.sh
* Run ./installglassfish.sh

*Help*

```
thys@elim:~/repos/glassfishinstall$ ./installglassfish.sh -h
USAGE: ./installglassfish.sh [flags] args
flags:
  -d,--domain:  Glassfish Domain (default: 'Sthysel')
  -v,--version:  Glassfish Version (default: '3.1.2.2')
  -h,--[no]help:  show this help (default: false)

```


