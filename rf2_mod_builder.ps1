#
# script to build RFMODs from .dat file
#
# Stone, 03/2024, info@simracingjustfair.org
#
# GitHub: github.com/Stone2GIT
#
# Updates 2025/26/07
#
# - customizing .dat file
# - making $RFMODFILENAME and $RFMODNAME unique using UNiX time
#
# Updates until 2025/26/07
#
# - weather file in UserData\$PLRPROFILE\Settings\$TRACKLAYOUT
#   generated for packed tracks layout with user:autosave.rrbin
# - dedicated.ini file in UserData\$PLRPROFILE
#   dedicated<modname>.ini is deleted in order to let be created by dedicated server 
# - added some status messages
#

. .\variables.ps1

# store the current date with month and day in numeric format
#
$CURRENTDATE=(Get-Date -Format "yyMM.dd")

# get current working directory ...
#
$CURRENTLOCATION=((Get-Location).Path)

# we need this for UNiX time in seconds
#
[DateTimeOffset]::Now.ToUnixTimeSeconds()

# set UNiX timestamp / date
#
$UNIXTIME=(([DateTimeOffset](Get-Date)).ToUnixTimeSeconds())

# look if a profile was given on command line
#
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

# look if a .dat file was given on command line
# => without a given dat file we cannot do anything
#
if (-not "$DATFILE") {
 $DATFILE="$HOME\Appdata\Roaming\pkginfo.dat"
 if (-not (Test-Path "$DATFILE" -PathType Leaf)) {
  write-host "`r`n`r`n=> Sorry, but we need a dat file at least given as argument or in appdata ..."
  timeout /t 10 | out-null
  exit 1
 } else {
  $CURRENTPACKAGE=(((gc $DATFILE | select-string -Pattern "CurPackage")[0]) -split("="))[1]
 }
}

# create settings folder in $PLRPROFILE and .wet file for track(s)
#
write-host "`r`n`r`n=> Generating settings for tracks for profile "$PLRPROFILE" using .dat file "$DATFILE

# look for tracks specified in .dat file
#
$TRACKS=(gc $DATFILE) | select-string -pattern "Track="

# we need to extract .gdb file from track layout .mas files for each track found in .dat file
#
foreach($TRACK in $TRACKS) {

 # if content in tmp exists ... remove it
 #
 if (Test-Path $CURRENTLOCATION\tmp) {
   write-host "`r`n`r`n=> Removing previous content in tmp folder"
   remove-Item -Recurse $CURRENTLOCATION\tmp\*
  }
 else {
   write-host "`r`n`r`n=> Creating tmp folder"
   new-item -Path $CURRENTLOCATION\tmp -ItemType Directory
  }

  # get the track and their version
  #
  $TRACK=($TRACK -split('='))
  $TRACKFOLDER=($TRACK[1] -split(' ') -replace '"','')[0]
  $TRACKVERSION=($TRACK[1] -split(' ') -replace '"','')[1]
  $TRACKVERSION=($TRACKVERSION -split(','))
  $TRACKVERSION=($TRACKVERSION[0] -replace '^v','')

  # count layouts of a track
  #
  # ((((gc .\example.dat| select-string -pattern "Track=")) -split('" ')) -replace('"','')|measure).count
   
  # look for .mas files in each TRACKFOLDER
  #
  $MASFILES=(Get-ChildItem "$RF2ROOT\Installed\Locations\$TRACKFOLDER\$TRACKVERSION\*.mas")

  # extract the .gdb files from the MAS file
  #
  foreach($MASFILE in $MASFILES) {
   write-host "`r`n`r`n=> Extracting .gdb from MAS file "$MASFILE
   $ARGUMENTS=" *.gdb -x""$MASFILE"" -o""$CURRENTLOCATION\tmp"" "
   start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow  -Wait

   write-host "`r`n`r`n=> Analyzing .gdb files"
   $GDBFILES=(Get-ChildItem "$CURRENTLOCATION\tmp\*.gdb")

   foreach($GDBFILE in $GDBFILES) {
    # get the first line of $GDBFILE
    $TRACKLAYOUT=(gc $GDBFILE)[0]
    $TRACKSETTINGSFOLDER=(((gc $GDBFILE| select-string -pattern "Settingsfolder") -split("="))[1]) -replace(' ','')

     if (! (Test-Path $RF2ROOT\Userdata\$PLRPROFILE\Settings\$TRACKSETTINGSFOLDER)) { new-item -Path $RF2ROOT\Userdata\$PLRPROFILE\Settings\$TRACKSETTINGSFOLDER -ItemType Directory }
     # this would convert template.wet to ASCII if it has been changed 
     #
     (get-content $CURRENTLOCATION\template.wet) | set-content -Path "$RF2ROOT\Userdata\$PLRPROFILE\Settings\$TRACKSETTINGSFOLDER\${TRACKLAYOUT}s.wet" -Encoding ASCII
   }
 }
}

# increase rubber build up
#
(gc $RF2ROOT\UserData\$PLRPROFILE\$PLRPROFILE.json) -replace '"RealRoadTimeScalePractice":.*','"RealRoadTimeScalePractice":10' | set-content -Path $RF2ROOT\UserData\$PLRPROFILE\$PLRPROFILE.json -Encoding ASCII

# generating the mod package
#
write-host "`r`n`r`n=> Building mod package for profile "$PLRPROFILE" using .dat file "$DATFILE

# generate filename for the rfmod file
#
$RFMODNAME=modbuilder-$UNIXTIME
$RFMODFILENAME=modbuilder-$UNIXTIME.rfmod

######################################
#
# change some parameters in .dat file
#
(get-content $DATFILE) \
	-replace "^Version=.*","Version=$CURRENTDATE" | set-content -Path "$DATFILE" -Encoding ASCII \
	-replace "^Date=.*","Date=$UNIXTIME" | set-content -Path "$DATFILE" -Encoding ASCII \
	-replace "^Location=.*","Location=$RF2ROOT\Packages\$RFMODFILENAME" | set-content -Path $DATFILE -Encoding ASCII \
	-replace "^Author=.*","Author=Stone" | set-content -Path $DATFILE -Encoding ASCII \
	-replace "^URL=.*","URL=simracingjustfair.org" | set-content -Path $DATFILE -Encoding ASCII \
	-replace "^Desc=.*","Desc=rFactor 2 Dedicated Server Mod built with rF2_rfmod_builder.ps1" | set-content -Path $DATFILE -Encoding ASCII \
	-replace "^Name=.*","Name=$RFMODNAME" | set-content -Path $DATFILE -Encoding ASCII

# filename of the manifest
#
$RFMFILENAME=( (($RFMODFILENAME -replace "\.rfmod","")+"_"+($CURRENTDATE -replace "\.","")+".rfm") -split("\\")| select -last 1 )

# get the filename of the original / previous used masfile
#
#$MASFILE=((gc $DATFILE | select-string -Pattern "^RFM=" | select -last 1) -split("\\") |select -last 1)
$MASFILE=$RFMODNAME

# build argument for modmgr to build masfile
#
write-host "`r`n`r`n=> Building MAS file "$MASFILE
 $ARGUMENTS=" -m""$HOME\Appdata\roaming\~mastemp\$MASFILE"" ""$CURRENTLOCATION\icon.dds"" ""$CURRENTLOCATION\smicon.dds"" ""$CURRENTLOCATION\default.rfm"" "
 start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow  -Wait

# give the filesystem cache a little time
#
timeout /t 3 | out-null

# building mod package by using dat file and first entry in it
#
write-host "`r`n`r`n=> Building RFMOD with dat entry "$CURRENTPACKAGE" from "$DATFILE
 $ARGUMENTS=" -c""$RF2ROOT"" -o""$RF2ROOT\Packages"" -b""$DATFILE"" $CURRENTPACKAGE "
 start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow -Wait

# deleting the Dedicated.ini file will make the DS create a new one with all tracks available
#
write-host "`r`n`r`n=> Deleting dedicated.ini file"
 $FILENAMEPART=(($RFMODFILENAME -replace '\.rfmod','') -split('\\') | select -last 1)
 #remove-item -Path "$RF2ROOT\Userdata\$PLRPROFILE\Dedicated(($RFMODFILENAME -replace '\.rfmod','') -split('\\') | select -last 1).ini"
 remove-item -Path "$RF2ROOT\Userdata\$PLRPROFILE\Dedicated$FILENAMEPART.ini"

# give the filesystem cache a little time
#
timeout /t 3 | out-null

# install mod package
# TODO: exit codes
#$ARGUMENTS=" -p""$RF2ROOT\Packages"" -i""$RFMODFILENAME"" -c""$RF2ROOT"" "
write-host "`r`n`r`n=> Installing RFMOD "$RFMODFILENAME
 $ARGUMENTS=" -i""$RFMODFILENAME"" -c""$RF2ROOT"" "
 start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow -Wait

# start the dedicated server with the mod ...
#
$ARGUMENTS=" +profile=$PLRPROFILE +rfm=""$RFMFILENAME"" +oneclick"

cd $RF2ROOT
 write-host "`r`n`r`n=> Starting rF2 dedicated server"
# start-process -FilePath "$RF2ROOT\bin64\rFactor2 Dedicated.exe" -ArgumentList $ARGUMENTS -NoNewWindow
cd $CURRENTLOCATION

# keep the window open to see error messages ...
#
timeout /t 300
