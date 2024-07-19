﻿#
# simple script to update RFMODs by content
#
# Dietmar Stein, 07/2024, info@simracingjustfair.org
#
# todo: run only if there has changed something

. .\variables.ps1

# read in profile name as args, but only the first one given
if ($args[0]) {
    $PROFILE=$args[0]
    }

# store the current date with month and day in numeric format
$CURRENTDATE=(Get-Date -Format "MMdd")

# filename of the dat file ...
$PREFIX="srjf-"
$DATFILE="$PREFIX"+"$PROFILE.dat"

# the rfmod file name
$RFMODFILENAME="$PREFIX"+"$PROFILE"+"$CURRENTDATE.rfmod"

# setting new version in dat file using numeric date ... it is very unlikely we are going to update a mod twice a day
(gc $DATFILE) -replace """^Version""=.*","""Version""=$CURRENTDATE" | set-content -Path "$DATFILE"

# setting correct rfmod file location in dat file
#(((gc $DATFILE |select-string -Pattern "^Location=") -split("="))[1])
(gc $DATFILE) -replace """^Location""=.*","""Location""=$RF2ROOT\Packages\$RFMODFILENAME" | set-content -Path "$DATFILE"

# read in whole dat file
$DATFILECONTENT=(gc $DATFILE)

# get all vehicle entries in dat file
$VEHICLES=(gc $DATFILE | select-string -Pattern 'Vehicle=')

# looping through vehicle entries
ForEach($VEHICLESTRING in $VEHICLES) {
    # get the folder name
    $VEHICLESTRING=($VEHICLESTRING -split('='))
    $VEHICLEFOLDER=($VEHICLESTRING[1] -split(' ') -replace '"','')

    # get the version string
    $VEHICLEVERSION=($VEHICLEFOLDER[1] -split(','))

    # remove the leading 'v' of the version string
    $VEHICLEVERSION=($VEHICLEVERSION[0] -replace '^v','')

    # get the last version installed in $VEHICLEFOLDER
    #
    # ATTENTION 
    # ... if there is anything installed in the folder, which is higher rated by sort it will be taken :-(
    # think of 3.61-gtw24-01 and 3.61-zzz-01
    #
    $VEHICLEFOLDER=$VEHICLEFOLDER[0]
    $VEHICLEINSTALLEDVERSION=((gci $RF2ROOT\Installed\Vehicles\$VEHICLEFOLDER\ -Dir | sort-object LastWriteTime | select -Last 1).BaseName)

    # if ... replace a string function
    # (gc "$RF2USERDATA\multiplayer.json") -replace """Test Day"":.*","""Test Day"":true," | set-content -Path "$RF2USERDATA\multiplayer.json"

    # compare
    if ( "$VEHICLEVERSION" -inotmatch "$VEHICLEINSTALLEDVERSION" ) {
        echo $VEHICLEFOLDER" does not match"
        echo "Found $VEHICLEINSTALLEDVERSION and $VEHICLEVERSION is found in mod definition."
    
        # example string we are looking for AstonMartin_Vantage_GT3_2019 v3.61-gtw24-01,0
        #
        # we are replacing the installed version with the version found in dat file
        $DATFILECONTENT=($DATFILECONTENT -replace "$VEHICLEFOLDER v$VEHICLEVERSION","$VEHICLEFOLDER v$VEHICLEINSTALLEDVERSION")
        }

    }

# writing the changed dat file ...
$DATFILECONTENT | set-content -Path $DATFILE