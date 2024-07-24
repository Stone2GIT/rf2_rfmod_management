#
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

# read args, but only the first one given for profile
if ($args[0]) {
     $PROFILE=$args[0]
    } else {
     $PROFILE=player
    }

if ($args[1]) {
     $DATFILE=$args[1]
    } else {
     write-host "Sorry, but we need a dat file mentioned ..."
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

# build mas file in appdata\roaming\~mastemp
#
#
# build argument for modmgr
$ARGUMENTS=" -m""$HOME\Appdata\roaming\~mastemp\$PREFIX$PROFILE.mas"" ""$CURRENTLOCATION\icon.dds"" ""$CURRENTLOCATION\smicon.dds"" ""$CURRENTLOCATION\default.rfm"" "

# run modmgr to build mas file
start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow  -Wait
#
#
# end of build mas file in appdata\roaming\~mastemp

# copy dummy.mas ... and copy the correct named mas file to MASTEMP
#cp dummy.mas $PREFIX$PROFILE.mas
#copy -v $PREFIX$PROFILE.mas $HOME\AppData\Roaming\~MASTEMP\$PREFIX$PROFILE".mas"

# building mod package by using dat file and first entry in it
$ARGUMENTS=" -c""$RF2ROOT"" -o""$RF2ROOT\Packages"" -b""$RF2ROOT\bmp\$DATFILE"" 0"
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
timeout /t 60
