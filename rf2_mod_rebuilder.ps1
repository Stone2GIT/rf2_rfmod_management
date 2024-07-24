﻿#
# simple script to build RFMODs from dat files
#
# Stone, 03/2024, info@simracingjustfair.org
#
# todo:
# - we need to check arguments what is given and at what position
# - build mas file from All Cars & Tracks mas file in $RF2ROOT\Installed\rFm instead of copying dummy.mas

. .\variables.ps1

# store the current date with month and day in numeric format
$CURRENTDATE=(Get-Date -Format "MMdd")
$CURRENTLOCATION=((Get-Location).Path)

# read in and identify args
forEach ($ARGUMENT in $args) {
 if ("($FILENAME | select-string '.dat')") {
  $DATFILE=$ARGUMENT
 } else {
  $PROFILE=$ARGUMENT
 }
}

# without a given dat file we cannot do anything
if (-not "$DATFILE") {
 write-host "Sorry, but we need a dat file mentioned ..."
 timeout /t 10 | out-null
 exit 1
}

# filename of the rfmod file ...
$RFMODFILENAME="$PREFIX"+"$PROFILE"+"$CURRENTDATE.rfmod"

# filename of the manifest
$VERSION=((((gc $DATFILE |select-string -Pattern "^Version=") -split("="))[1]) -replace "\.","")
$RFMFILENAME="$PREFIX"+"$PROFILE"+"$CURRENTDATE_$VERSION.rfm"

# we need to extract and rename files from All Cars & Tracks mas file
$ARGUMENTS=" *.* -x""$RF2ROOT\Installed\rFm\All Tracks & Cars_10.mas"" -c""$CURRENTLOCATION"" "
start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow  -Wait
move-item "All*_10.rfm" "default.rfm" -force
move-item "All*smicon.dds" "smicon.dds" -force
move-item "All*icon.dds" "icon.dds" -force

# build argument for modmgr
$ARGUMENTS=" -m""$HOME\Appdata\roaming\~mastemp\$PREFIX$PROFILE.mas"" ""$CURRENTLOCATION\icon.dds"" ""$CURRENTLOCATION\smicon.dds"" ""$CURRENTLOCATION\default.rfm"" "

# run modmgr to build mas file
start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow  -Wait

# building mod package by using dat file and first entry in it
$ARGUMENTS=" -c""$RF2ROOT"" -o""$RF2ROOT\Packages"" -b""$RF2ROOT\$DATFILE"" 0"
start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow -Wait

# install mod package
# TODO: exit codes
$ARGUMENTS=" -p""$RF2ROOT\Packages"" -i""$RFMODFILENAME"" -c""$RF2ROOT"" "
start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow -Wait

# change directory to $RF2ROOT
cd $RF2ROOT

# start the mod ...
$ARGUMENTS=" +profile=$PROFILE +rfm=$RFMFILENAME +oneclick"
start-process -FilePath "$RF2ROOT\bin64\rFactor2 Dedicated.exe" -ArgumentList $ARGUMENTS -NoNewWindow

# keep the window open to see error messages ...
timeout /t 60 | out-null
