 #
# simple script in order to update workshop items
#
# Dietmar Stein, 03/2024, info@simracingjustfair.org
#

# Notes
#
# steamcmd +login anonymous +runscript "C:\Program Files (x86)\Steam\steamapps\common\rFactor 2\workshopids\classicseries.txt" +quit
# workshop_download_item 365960 2985911376 validate
# Add-Content -Path $DATFILE -value $TRACKENTRIES

# source variables
. ./variables.ps1

$CURRENTDATE=(Get-Date -Format "MMdd")
$CURRENTLOCATION=((Get-Location).Path)

# getting SteamIDs by simply using $args
$STEAMIDS=$args

if (!$STEAMIDS) {

# getting SteamIDs by simply using gci
$STEAMIDS=(gci -Path $RF2WORKSHOPPKGS|select -Expand Name) 

}

# what to do with the given IDs
foreach ($STEAMID in $STEAMIDS)
 {  
    write-host "Adding SteamID $STEAMID to steamcmd script."
    Add-Content -Path $CURRENTLOCATION\$CURRENTDATE".ids" -value "workshop_download_item 365960 $STEAMID validate"

    #
    # 07/2024
    #
    # using a scriptfile leads to timeouts for some reason ...
    # 
    #$ARGUMENTS=" +force_install_dir ""$RF2ROOT"" +login anonymous +workshop_download_item 365960 $STEAMID +quit"
    #start-process "$STEAMINSTALLDIR\steamcmd" -ArgumentList $ARGUMENTS -NoNewWindow -wait

    #timeout /t 5
 }

    # simple message  
    write-host "Finished generating script file."

    # generating arguments string
    $ARGUMENTS=" +force_install_dir ""$RF2ROOT"" +login anonymous +runscript $CURRENTLOCATION\$CURRENTDATE"".ids"" +quit"
    
    #
    # 07/2024
    #
    # using a scriptfile leads to timeouts for some reason ...
    # 
    # downloading the workshop item
    start-process "$STEAMINSTALLDIR\steamcmd" -ArgumentList $ARGUMENTS -NoNewWindow -wait

    forEach ($STEAMID in $STEAMIDS)
    {
    # looking for RFCMP to install (need to be sorted, think of GT3 vehicles, 3.60 base, 3.61 update)
    # $RFCMPS=(gci $RF2WORKSHOPPKGS\$STEAMID *.rfcmp -recurse| select -Expand Name|sort)
    $RFCMPS=(gci $RF2WORKSHOPPKGS\$STEAMID *.rfcmp -recurse| select-object -Expand Name|sort)
    
    # install each RFCMP with modmgr ... assuming modmgr is configured
    foreach ($RFCMP in $RFCMPS)
    {
        write-host "Installing $RFCMP"
        #& "$RF2ROOT\bin64\ModMgr.exe" -i"$RFCMP" -p"$RF2WORKSHOPPKGS\$STEAMID" -d"$RF2ROOT"
        $ARGUMENTS=" -i""$RFCMP"" -p""$RF2WORKSHOPPKGS\$STEAMID"" -d""$RF2ROOT"" -c""$RF2ROOT"" "
        $ARGUMENTS
        start-process -FilePath "$RF2ROOT\bin64\ModMgr.exe" -ArgumentList $ARGUMENTS -nonewwindow -wait

        # start-process does not really wait for modmgr having finished so we need some xtra wait
        start-sleep -seconds 3
    }
    }

    del $CURRENTDATE".ids"
