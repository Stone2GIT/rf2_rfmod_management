#
# simple script to generate vehicle line of dat file (pkginfo.dat)
#
# Stone 07/2024, info@simracingjustfair.org
#
# Notes:
# - as we are looking for updated packages, we will not find anything else then .mas files ... at least we should

# source variables
. ./variables.ps1

# pwd ...
$CURRENTLOCATION=((Get-Location).Path)

# if tmp exists ... remove it
if (Test-Path tmp)
 {
  remove-Item -Recurse tmp
  new-item -Path tmp -ItemType Director
 }

# get all VEHICLEFOLDERS from vehicles directory
$VEHICLEFOLDERS=((Get-ChildItem -Path Vehicles -Attributes Directory).Name)

# run for each VEHICLEFOLDER
forEach ($VEHICLEFOLDER in $VEHICLEFOLDERS)
 {
  # empts VEHICLELINE
  $VEHICLELINE=""

  # gets last version installed in $VEHICLEFOLDER
  $VEHICLEFOLDERINSTALLEDVERSION=((get-childitem "Vehicles\$VEHICLEFOLDER" -Dir | sort-object LastWriteTime | select-object -Last 1).BaseName)

  # look for .mas files in each VEHICLEFOLDER
  $MASFILES=(Get-ChildItem "Vehicles\$VEHICLEFOLDER\$VEHICLEFOLDERINSTALLEDVERSION\*.mas")

  # what to do if we have found masfiles
  if ($MASFILES)
  {
   forEach ($MASFILE in $MASFILES)
   {
    # if there is a masfile existing create folder and extract -veh files to it
    if (-not (Test-Path "tmp\$VEHICLEFOLDER")) { new-item -Path "tmp\$VEHICLEFOLDER" -ItemType Directory }

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
    $VEHICLELINE = """$VEHICLEFOLDER v3.61,0"" " + $VEHICLELINE

    $VEHICLELINE
   }
  }
 }


