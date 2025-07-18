#
# simple script to build RFMODs from dat files
#
# Stone, 03/2024, info@simracingjustfair.org
#
# todo:

. .\variables.ps1

# store the current date with month and day in numeric format
$CURRENTDATE=(Get-Date -Format "yyMM.dd")
$CURRENTYEAR=(Get-Date -Format "yy")
$CURRENTMONTH=(Get-Date -Format "MM")
$CURRENTDAY=(Get-Date -Format "dd")
#$CURRENTDATE=[int]$CURRENTYEAR+[int]$CURRENTMONTH+[int]$CURRENTDAY

# pwd ...
$CURRENTLOCATION=((Get-Location).Path)

# we need this for UNiX time in seconds
[DateTimeOffset]::Now.ToUnixTimeSeconds()

# set UNiX timestamp / date
$UNIXTIME=(([DateTimeOffset](Get-Date)).ToUnixTimeSeconds())

if ($args[0]) {
 # read in and identify args
 forEach ($ARGUMENT in $args) {
  if ( $ARGUMENT | select-string '.dat' ) {
   $DATFILE=$ARGUMENT
   $CURRENTPACKAGE=(((gc $DATFILE | select-string -Pattern "CurPackage")[0]) -split("="))[1]
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
  $CURRENTPACKAGE=(((gc $DATFILE | select-string -Pattern "CurPackage")[0]) -split("="))[1]
 }
}


write-host "Generating settings for tracks for profile "$PLRPROFILE" using .dat file "$DATFILE

# look for tracks specified in .dat file
$TRACKS=(gc $DATFILE) | select-string -pattern "Track="


# we need to extract gdb file from track layout .mas files for each track found in .dat file
foreach($TRACK in $TRACKS) {

# if tmp exists ... remove it
if (Test-Path $CURRENTLOCATION\tmp)
 {
  write-host "Removing previous tmp folder"
  remove-Item -Recurse $CURRENTLOCATION\tmp
  new-item -Path $CURRENTLOCATION\tmp -ItemType Directory
 }
else {
  write-host "Creating tmp folder"
  new-item -Path $CURRENTLOCATION\tmp -ItemType Directory
 }

 $TRACK=($TRACK -split('='))
 $TRACKFOLDER=($TRACK[1] -split(' ') -replace '"','')[0]
 $TRACKVERSION=($TRACK[1] -split(' ') -replace '"','')[1]
 $TRACKVERSION=($TRACKVERSION -split(','))
 $TRACKVERSION=($TRACKVERSION[0] -replace '^v','')
   
 # look for .mas files in each TRACKFOLDER
 $MASFILES=(Get-ChildItem "$RF2ROOT\Installed\Locations\$TRACKFOLDER\$TRACKVERSION\*.mas")

 foreach($MASFILE in $MASFILES) {
  write-host "Extracting MAS file "$MASFILE
  $ARGUMENTS=" *.gdb -x""$MASFILE"" -o""$CURRENTLOCATION\tmp"" "
  start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow  -Wait

   $GDBFILES=(Get-ChildItem "$CURRENTLOCATION\tmp\*.gdb")

   foreach($GDBFILE in $GDBFILES) {
    # get the first line of $GDBFILE
    $TRACKLAYOUT=(gc $GDBFILE)[0]
    $TRACKSETTINGSFOLDER=(((gc $GDBFILE| select-string -pattern "Settingsfolder") -split("="))[1]) -replace(' ','')

    if (! (Test-Path $RF2ROOT\Userdata\$PLRPROFILE\Settings\$TRACKSETTINGSFOLDER)) { new-item -Path $RF2ROOT\Userdata\$PLRPROFILE\Settings\$TRACKSETTINGSFOLDER -ItemType Directory }
    Copy-Item $CURRENTLOCATION\template.wet $RF2ROOT\Userdata\$PLRPROFILE\Settings\$TRACKSETTINGSFOLDER\${TRACKLAYOUT}s.wet
   }


 }

}


write-host "Building mod package for profile "$PLRPROFILE" using .dat file "$DATFILE

# replace the version in dat file
(get-content $DATFILE) -replace "^Version=.*","Version=$CURRENTDATE" | set-content -Path "$DATFILE" -Encoding ASCII
(get-content $DATFILE) -replace "^Date=.*","Date=$UNIXTIME" | set-content -Path "$DATFILE" -Encoding ASCII

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
