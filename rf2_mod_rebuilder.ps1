#
# simple script to build RFMODs from dat files
#
# Stone, 03/2024, info@simracingjustfair.org
#

. .\variables.ps1

# store the current date with month and day in numeric format
$CURRENTDATE=(Get-Date -Format "MMdd")
$CURRENTLOCATION=((Get-Location).Path)

# read args, but only the first one given for profile
if ($args[0]) {
    $PROFILE=$args[0]
    }

if ($args[1]) {
     $DATFILE=$args[1]
    } else {
     # filename of the dat file ...
     $PREFIX="srjf-"
     $DATFILE="$PREFIX"+"$PROFILE.dat"
    }

# filename of the rfmod file ...
$RFMODFILENAME="$PREFIX"+"$PROFILE"+"$CURRENTDATE.rfmod"

# filename of the manifest
$VERSION=((((gc $DATFILE |select-string -Pattern "^Version=") -split("="))[1]) -replace "\.","")
$RFMFILENAME="$PREFIX"+"$PROFILE"+"$CURRENTDATE_$VERSION.rfm"

# change to BuildModPackage folder ;-)
cd $RF2ROOT\bmp

# copy dummy.mas ... and copy the correct named mas file to MASTEMP
cp dummy.mas $PREFIX$PROFILE.mas
copy -v $PREFIX$PROFILE.mas $HOME\AppData\Roaming\~MASTEMP\$PREFIX$PROFILE".mas"

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
