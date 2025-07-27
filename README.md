# rFactor 2 RFMOD Management

## General

Scripts for (re-)building and updating rF2 mod packages using .dat info file as source - the updater will look for the
latest version in installed\\vehicles<vehicle> and update .dat info file and building mod package.

The builder simply uses .dat info file to build mod package and generating a .wet file for the track(s) found in .dat file
using user:autosave.rrbin as realroad setting.

Both scripts are starting dedicated server once with given profile and new mod package.

## Known issues

* if .dat info file is NOT an ASCII file mod package build may fail
* ~~sometimes DS must be started manually in order to define available cars or car categories~~

## Disclaimer

Scripts provided 'as is'.

## Note

* PS1 files need to be opened with editor once in order to get rid of the signing warning.
* Layout entries of tracks will not be updated if there are new ones :-(
* New vehicle or track entries will not be added :-(

## Quick start guide

1. download the repository
2. open .ps1 files with editor once
3. configure RF2ROOT in variables.ps1
4. generate .dat file with mastool and use (or copy from) $HOME/Appdata/Roaming/pkginfo.dat

### rf2\_mod\_builder

5. run rf2\_mod\_builder with <profile> and <datfile> as argument, e.g. rf2\_mod\_builder.ps1 player sample.dat

### rf2\_mod\_updater

5. run rf2\_mod\_updater with <profile> and <datfile> as argument, e.g. rf2\_mod\_updater.ps1 player sample.dat

## Features

Not sure if it should be called Features … the builder generates a weather (.wet) file with Autosave enabled for realroad feature,
Setting realroad factor to 10, deleting Dedicated Server ini file in order to make DS generate it from Scratch (makes all tracks listed available)
and does some informational modification to .dat file given on command line.
