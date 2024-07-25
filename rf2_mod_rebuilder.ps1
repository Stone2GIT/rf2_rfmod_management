#
# simple script to build RFMODs from dat files
#
# Stone, 03/2024, info@simracingjustfair.org
#
# todo:

. .\variables.ps1

# store the current date with month and day in numeric format
$CURRENTDATE=(Get-Date -Format "yy.MMdd")

# pwd ...
$CURRENTLOCATION=((Get-Location).Path)

# read in and identify args
forEach ($ARGUMENT in $args) {
 if ("($FILENAME | select-string '.dat')") {
  $DATFILE=$ARGUMENT
  $CURRENTPACKAGE=0
 } else {
  # if no profile is given as argument we will use default from variables.ps1
  $PROFILE=$ARGUMENT
 }
}

# without a given dat file we cannot do anything
if (-not "$DATFILE") {
 $DATFILE="$HOME\Appdata\Roaming\pkginfo.dat"
 if (-not (Test-Path "$DATFILE" -PathType Leaf)) {
  write-host "Sorry, but we need a dat file at least given as argument or in appdata ..."
  timeout /t 10 | out-null
  exit 1
 } else {
  $CURRENTPACKAGE=((gc $DATFILE |select-string -Pattern "CurPackage"|select -last 1) -split("=") |select -last 1)
 }
}

# replace the version in dat file
(gc $DATFILE) -replace "^Version=.*","Version=$CURRENTDATE" | set-content -Path "$DATFILE"

# filename of the rfmod file ... this is already in dat file ...
#$RFMODFILENAME="$PREFIX"+"$PROFILE"+"$CURRENTDATE.rfmod"
$RFMODFILENAME=((gc $DATFILE | select-string -Pattern "^Location=" | select -last 1) -split("=") |select -last 1)

# filename of the manifest
$VERSION=((((gc $DATFILE |select-string -Pattern "^Version=") -split("="))[1]) -replace "\.","")
$RFMFILENAME="$PREFIX"+"$PROFILE"+"$CURRENTDATE"+"_"+"$VERSION"+".rfm"

# we need to extract and rename files from All Cars & Tracks mas file
$ARGUMENTS=" *.dds *.rfm -x""$RF2ROOT\Installed\rFm\All Tracks & Cars_10.mas"" -o""$CURRENTLOCATION"" "
start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow  -Wait
move-item "All*_10.rfm" "default.rfm" -force
move-item "All*smicon.dds" "smicon.dds" -force
move-item "All*icon.dds" "icon.dds" -force

# build argument for modmgr
$ARGUMENTS=" -m""$HOME\Appdata\roaming\~mastemp\$PREFIX$PROFILE.mas"" ""$CURRENTLOCATION\icon.dds"" ""$CURRENTLOCATION\smicon.dds"" ""$CURRENTLOCATION\default.rfm"" "

# run modmgr to build mas file
start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow  -Wait

# building mod package by using dat file and first entry in it
#$ARGUMENTS=" -c""$RF2ROOT"" -o""$RF2ROOT\Packages"" -b""$RF2ROOT\$DATFILE"" 0"
$ARGUMENTS=" -c""$RF2ROOT"" -o""$RF2ROOT\Packages"" -b""$DATFILE"" ""$CURRENTPACKAGE"" "
start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow -Wait

# install mod package
# TODO: exit codes
$ARGUMENTS=" -p""$RF2ROOT\Packages"" -i""$RFMODFILENAME"" -c""$RF2ROOT"" "
start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow -Wait

# change directory to $RF2ROOT
#cd $RF2ROOT

# start the mod ...
$ARGUMENTS=" +profile=$PROFILE +rfm=$RFMFILENAME +oneclick"
start-process -FilePath "$RF2ROOT\bin64\rFactor2 Dedicated.exe" -ArgumentList $ARGUMENTS -NoNewWindow

# keep the window open to see error messages ...
timeout /t 60 | out-null
