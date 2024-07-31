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

if ($args[0]) {
 # read in and identify args
 forEach ($ARGUMENT in $args) {
  if ("($FILENAME | select-string '.dat')") {
   $DATFILE=$ARGUMENT
   $CURRENTPACKAGE=((gc $DATFILE |select-string -Pattern "CurPackage"|select -last 1) -split("=") |select -last 1)
  } else {
   # if no profile is given as argument we will use default from variables.ps1
   $PLRPROFILE=$ARGUMENT
  }
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
(gc $DATFILE) -replace "^Version=.*","Version=$CURRENTDATE" | set-content -Path "$DATFILE" -Encoding ASCII

# filename of the rfmod file ... this is already in dat file ...
$RFMODFILENAME=((gc $DATFILE | select-string -Pattern "^Location=" | select -last 1) -split("=") |select -last 1)

# filename of the manifest
$RFMFILENAME=( (($RFMODFILENAME -replace "\.rfmod","")+"_"+($CURRENTDATE -replace "\.","")+".rfm") -split("\\")| select -last 1 )

# get the filename of the original / previous used masfile
$MASFILE=((gc $DATFILE | select-string -Pattern "^RFM=" | select -last 1) -split("\\") |select -last 1)

# we need to extract and rename files from All Cars & Tracks mas file
#write-host "Extracting files from All Tracks & Cars masfile."
#$ARGUMENTS=" *.dds *.rfm -x""$RF2ROOT\Installed\rFm\All Tracks & Cars_10.mas"" -o""$CURRENTLOCATION"" "
#start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow  -Wait
#move-item "All*_10.rfm" "default.rfm" -force
#move-item "All*smicon.dds" "smicon.dds" -force
#move-item "All*icon.dds" "icon.dds" -force

# build argument for modmgr to build masfile
write-host "Building "$MASFILE
$ARGUMENTS=" -m""$HOME\Appdata\roaming\~mastemp\$MASFILE"" ""$CURRENTLOCATION\icon.dds"" ""$CURRENTLOCATION\smicon.dds"" ""$CURRENTLOCATION\default.rfm"" "
start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow  -Wait

timeout /t 3 | out-null

# building mod package by using dat file and first entry in it
write-host "Building RFMOD with dat entry "$CURRENTPACKAGE" from "$DATFILE
$ARGUMENTS=" -c""$RF2ROOT"" -o""$RF2ROOT\Packages"" -b""$DATFILE"" $CURRENTPACKAGE "
start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow -Wait

timeout /t 3 | out-null

# install mod package
# TODO: exit codes
#$ARGUMENTS=" -p""$RF2ROOT\Packages"" -i""$RFMODFILENAME"" -c""$RF2ROOT"" "
write-host "Installing RFMOD "$RFMODFILENAME
$ARGUMENTS=" -i""$RFMODFILENAME"" -c""$RF2ROOT"" "
start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow -Wait

# start the mod ...
$ARGUMENTS=" +profile=$PLRPROFILE +rfm=""$RFMFILENAME"" +oneclick"

# we need to be in RF2ROOT
cd $RF2ROOT
 write-host "Starting rF2 dedicated server"
 start-process -FilePath "$RF2ROOT\bin64\rFactor2 Dedicated.exe" -ArgumentList $ARGUMENTS -NoNewWindow
cd $CURRENTLOCATION

# keep the window open to see error messages ...
timeout /t 10
