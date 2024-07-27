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

if (-not (Test-Path tmp)) { new-item -Path tmp -ItemType Directory }

# get all components from vehicles directory
$COMPONENTS=((Get-ChildItem -Path Vehicles -Attributes Directory).Name)

# run for each component
forEach ($COMPONENT in $COMPONENTS)
 {
  # empts VEHICLELINE
  $VEHICLELINE=""

  # look for .veh files in each component
  $VEHFILES=(Get-ChildItem "Vehicles\$COMPONENT\*.veh")

  # look for .mas files in each component
  $MASFILES=(Get-ChildItem "Vehicles\$COMPONENT\*.mas")

  # what to do if we have found masfiles
  if ($MASFILES)
  {
   forEach ($MASFILE in $MASFILES)
   {
    # if there is a masfile existing create folder and extract -veh files to it
    if (-not (Test-Path "tmp\$COMPONENT")) { new-item -Path "tmp\$COMPONENT" -ItemType Directory }

    # argument list
    $ARGUMENTS=" *.veh -x""$MASFILE"" -o""$CURRENTLOCATION\tmp\$COMPONENT"" "

    # extract the .veh files from masfile
    start-process "$RF2ROOT\bin64\modmgr.exe" -ArgumentList $ARGUMENTS -NoNewWindow -Wait
   }
  }

  # what to do if we have found vehfiles
  if ($VEHFILES)
  {
   # parse each .veh file
   forEach ($VEHFILE in $VEHFILES)
   {
    $VEHICLEENTRY = (((Get-Content $VEHFILE| select-string -Pattern "^Description") -split ('=')| select-object -last 1) -replace '"', "")

    # line up the entries
    $VEHICLELINE = $VEHICLELINE + " " + """$VEHICLEENTRY,1"""
   }

   # add quotations to vehicleline
   $VEHICLELINE = """$COMPONENT v3.61,0"" " + $VEHICLELINE

   $VEHICLELINE
  }
}
