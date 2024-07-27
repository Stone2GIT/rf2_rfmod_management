#
# simple script to update RFMODs by content
#
# Stone, 07/2024, info@simracingjustfair.org
#
# todo:
# - we could choose to rebuild latest mod in pkginfo.dat if no dat filename is given
# - (Get-Content ./pkginfo.dat|select-string -Pattern "CurPackage") -split("=") | tail -n 1 gives CurPackage number

. ./variables.ps1

# store the current date with month and day in numeric format
$CURRENTDATE=(Get-Date -Format "yy.MMdd")

# pwd ...
$CURRENTLOCATION=((Get-Location).Path)

# read in and identify args
forEach ($ARGUMENT in $args) {
 if ("($FILENAME | select-string '.dat')") {
  $DATFILE=$ARGUMENT
  #$CURRENTPACKAGE=((Get-Content $DATFILE |select-string -Pattern "CurPackage"|select-object -last 1) -split("=") |select-object -last 1)
 }
}

# without a given dat file we cannot do anything
if (-not "$DATFILE") {
 $DATFILE="$HOME\Appdata\Roaming\pkginfo.dat"
 if (-not (Test-Path "$DATFILE" -PathType Leaf)) {
  write-host "Sorry, but we need a dat file at least given as argument or in appdata ..."
  timeout /t 10 | out-null
  exit 1
 }
}

# if tmp exists ... remove it
if (Test-Path tmp)
 {
  remove-Item -Recurse tmp
  new-item -Path tmp -ItemType Director
 }

# replace the version in dat file
(Get-Content $DATFILE) -replace "^Version=.*","Version=$CURRENTDATE" | set-content -Path "$DATFILE" -Encoding ASCII

# read in whole dat file
$DATFILECONTENT=(Get-Content $DATFILE)

# get all vehicle entries in dat file
$VEHICLES=(Get-Content $DATFILE | select-string -Pattern 'Vehicle=')

# looping through vehicle entries
ForEach($VEHICLESTRING in $VEHICLES) {
    
    # get the folder name, VEHICLESTRING might be e.g. Vehicle="Callaway_Corvette_GT3_2017 v2024.07.25,0" "SRC Corvette Guest #108,1" "Simracing:Justfair #61,1"
    $VEHICLESTRING=($VEHICLESTRING -split('='))

    # VEHICLEFOLDER will be e.g. Callaway_Corvette_GT3_2017
    $VEHICLEFOLDER=($VEHICLESTRING[1] -split(' ') -replace '"','')

    # get the version string, might be e.g. v3.61
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
    $VEHICLEINSTALLEDVERSION=((Get-ChildItem $RF2ROOT\Installed\Vehicles\$VEHICLEFOLDER\ -Dir | sort-object LastWriteTime | select-object -Last 1).BaseName)

    # compare
    if ( "$VEHICLEVERSION" -inotmatch "$VEHICLEINSTALLEDVERSION" ) {
        write-host $VEHICLEFOLDER" does not match"
        write-host "Found $VEHICLEINSTALLEDVERSION and $VEHICLEVERSION is found in mod definition."
            



#
#
#
# at this point we need to extract in the .mas file from $VEHICLEINSTALLEDVERSION and extract .veh files
        
# look for .mas files in each VEHICLEFOLDER
$MASFILES=(Get-ChildItem "$RF2ROOT\Installed\Vehicles\$VEHICLEFOLDER\$VEHICLEINSTALLEDVERSION\*.mas")

# what to do if we have found masfiles
if ($MASFILES)
 {
  forEach ($MASFILE in $MASFILES)
{

$VEHICLELINE=""

# if there is a masfile existing create folder and extract -veh files to it
if (-not (Test-Path "$CURRENTLOCATION\tmp\$VEHICLEFOLDER")) { new-item -Path "$CURRENTLOCATION\tmp\$VEHICLEFOLDER" -ItemType Directory }

# argument list
$ARGUMENTS=" *.veh -x""$MASFILE"" -o""$CURRENTLOCATION\tmp\$VEHICLEFOLDER"" "

# extract the .veh files from masfile
start-process "$RF2ROOT\bin64\modmgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow -Wait

# look for .veh files in each VEHICLEFOLDER
$VEHFILES=(Get-ChildItem "$CURRENTLOCATION\tmp\$VEHICLEFOLDER\*.veh")

# parse each .veh file
forEach ($VEHFILE in $VEHFILES)
{
$VEHICLEENTRY = (((Get-Content $VEHFILE| select-string -Pattern "^Description") -split ('=')| select-object -last 1) -replace '"', "")

# line up the entries
$VEHICLELINE = $VEHICLELINE + " " + """$VEHICLEENTRY,1"""
}

# add quotations to vehicleline
$VEHICLELINE = """$VEHICLEFOLDER v$VEHICLEINSTALLEDVERSION,0""" + $VEHICLELINE

}
}
#
#
#


        # example string we are looking for "AstonMartin_Vantage_GT3_2019 v3.61-gtw24-01,0"
        #
        # we are replacing the installed version with the version found in dat file
        #$DATFILECONTENT=($DATFILECONTENT -replace "$VEHICLEFOLDER v$VEHICLEVERSION","$VEHICLEFOLDER v$VEHICLEINSTALLEDVERSION")
        $DATFILECONTENT=($DATFILECONTENT -replace "Vehicle=""$VEHICLEFOLDER v$VEHICLEVERSION.*","Vehicle=$VEHICLELINE")


         #-replace "^Version=.*","Version=$CURRENTDATE" 

        # set variable in order to run update
        $UPDATE=1
        }

    }

# get all track entries in dat file
$TRACKS=(Get-Content $DATFILE | select-string -Pattern 'Track=')

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
    $TRACKINSTALLEDVERSION=((Get-ChildItem $RF2ROOT\Installed\Locations\$TRACKFOLDER\ -Dir | sort-object LastWriteTime | select-object -Last 1).BaseName)

    # if ... replace a string function
    # (Get-Content "$RF2USERDATA\multiplayer.json") -replace """Test Day"":.*","""Test Day"":true," | set-content -Path "$RF2USERDATA\multiplayer.json"

    # compare
    if ( "$TRACKVERSION" -inotmatch "$TRACKINSTALLEDVERSION" ) {
        write-host $TRACKFOLDER" does not match"
        write-host "Found $TRACKINSTALLEDVERSION and $TRACKVERSION is found in mod definition."

        # example string we are looking for AstonMartin_Vantage_GT3_2019 v3.61-gtw24-01,0
        #
        # we are replacing the installed version with the version found in dat file
        $DATFILECONTENT=($DATFILECONTENT -replace "$TRACKFOLDER v$TRACKVERSION","$TRACKFOLDER v$TRACKINSTALLEDVERSION")

        # set variable in order to run update
        $UPDATE=1
        }

    }

# if the UPDATE value is 1 ...
if ($UPDATE -eq 1)
 {

  write-host "Writing updated "$DATFILE
  # writing the changed dat file ...
  $DATFILECONTENT | set-content -Path $DATFILE -Encoding ASCII

  # calling mod_builder ...
  start-process -FilePath powershell -ArgumentList "$CURRENTLOCATION\rf2_mod_builder.ps1 $DATFILE" -NoNewWindow -Wait
 }
