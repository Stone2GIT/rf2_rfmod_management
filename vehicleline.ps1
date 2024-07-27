#
# simple script to generate vehicle line of dat file (pkginfo.dat)
#
# Stone 07/2024, info@simracingjustfair.org
#

# get all components from vehicles directory
$COMPONENTS=((Get-ChildItem -Path Vehicles).Name)

# run for each component
forEach ($COMPONENT in $COMPONENTS)
 {

  # empts VEHICLELINE
  $VEHICLELINE=""

  # look for .veh files in each component
  $VEHFILES=(Get-ChildItem "Vehicles\$COMPONENT\*.veh")

  # parse each .veh file
  forEach ($VEHFILE in $VEHFILES)
   {
    $VEHICLEENTRY=(((Get-Content $VEHFILE| select-string -Pattern "^Description") -split('=')| select-object -last 1) -replace '"',"")

    # line up the entries
    $VEHICLELINE=$VEHICLELINE+" "+"""$VEHICLEENTRY,1"""
   }

  # add quotations to vehicleline
  $VEHICLELINE="""$COMPONENT v3.61,0"" "+$VEHICLELINE

 $VEHICLELINE
}
