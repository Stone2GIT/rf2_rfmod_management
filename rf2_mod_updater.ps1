#
# simple script to update RFMODs by content
#
# Stone, 07/2024, info@simracingjustfair.org
#
# todo:
# - we could choose to rebuild latest mod in pkginfo.dat if no dat filename is given
# - (gc ./pkginfo.dat|select-string -Pattern "CurPackage") -split("=") | tail -n 1 gives CurPackage number

. ./variables.ps1

# store the current date with month and day in numeric format
$CURRENTDATE=(Get-Date -Format "MMdd")
$CURRENTLOCATION=((Get-Location).Path)

# read in and identify args
forEach ($ARGUMENT in $args) {
 if ("($FILENAME | select-string '.dat')") {
  $DATFILE=$ARGUMENT
 } else {
  # if no profile is given as argument we will use default from variables.ps1
  $PROFILE=$ARGUMENT
 }
}

# without a given dat file we cannot do anything
if (-not "$DATFILE") {
 write-host "Sorry, but we need a dat file mentioned ..."
 timeout /t 10 | out-null
 exit 1
}

# the new rfmod file name for the updated one
$RFMODFILENAME="$PREFIX"+"$PROFILE"+"$CURRENTDATE.rfmod"

# setting new version in dat file using numeric date ... it is very unlikely we are going to update a mod twice a day
(gc $DATFILE) -replace """^Version""=.*","""Version""=$CURRENTDATE" | set-content -Path "$DATFILE"

# setting correct rfmod file location in dat file
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

	$UPDATE=1
    
        # example string we are looking for AstonMartin_Vantage_GT3_2019 v3.61-gtw24-01,0
        #
        # we are replacing the installed version with the version found in dat file
        $DATFILECONTENT=($DATFILECONTENT -replace "$VEHICLEFOLDER v$VEHICLEVERSION","$VEHICLEFOLDER v$VEHICLEINSTALLEDVERSION")
        }

    }

# get all track entries in dat file
$TRACKS=(gc $DATFILE | select-string -Pattern 'Track=')

# looping through vehicle entries
ForEach($TRACKSTRING in $TRACKS) {
    # get the folder name
    $TRACKSTRING=($TRACKSTRING -split('='))
    $TRACKFOLDER=($TRACKSTRING[1] -split(' ') -replace '"','')

    # get the version string
    $TRACKVERSION=($TRACKFOLDER[1] -split(','))

    # remove the leading 'v' of the version string
    $TRACKVERSION=($TRACKVERSION[0] -replace '^v','')

    # get the last version installed in $TRACKFOLDER
    $TRACKFOLDER=$TRACKFOLDER[0]
    $TRACKINSTALLEDVERSION=((gci $RF2ROOT\Installed\Locations\$TRACKFOLDER\ -Dir | sort-object LastWriteTime | select -Last 1).BaseName)

    # if ... replace a string function
    # (gc "$RF2USERDATA\multiplayer.json") -replace """Test Day"":.*","""Test Day"":true," | set-content -Path "$RF2USERDATA\multiplayer.json"

    # compare
    if ( "$TRACKVERSION" -inotmatch "$TRACKINSTALLEDVERSION" ) {
        echo $TRACKFOLDER" does not match"
        echo "Found $TRACKINSTALLEDVERSION and $TRACKVERSION is found in mod definition."

	$UPDATE=1
    
        # example string we are looking for AstonMartin_Vantage_GT3_2019 v3.61-gtw24-01,0
        #
        # we are replacing the installed version with the version found in dat file
        $DATFILECONTENT=($DATFILECONTENT -replace "$TRACKFOLDER v$TRACKVERSION","$TRACKFOLDER v$TRACKINSTALLEDVERSION")
        }

    }

if ($UPDATE -eq 1)
 {
  # writing the changed dat file ...
  $DATFILECONTENT | set-content -Path $DATFILE
 }
