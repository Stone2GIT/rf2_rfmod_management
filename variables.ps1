#
# simple script defining base variables
#
# Dietmar Stein, 07/2024, info@simracingjustfair.org
#

# where is rfactor 2 located (currently program files (x86) is not supported)
$RF2ROOT="$HOME\rf2ds"

# where do we find the downloaded workshop packages
$RF2WORKSHOPPKGS="$RF2ROOT\steamapps\workshop\content\365960"

# as SteamCMD needs to be installed, where to find it
$STEAMINSTALLDIR="$RF2ROOT\steamcmd"

# we need an Steam API key for the DLC installer
$STEAMAPIKEY=""

# DLC installer uses CSV files ...
$CSVCARFILE="$RF2ROOT\dlccars.csv"
$CSVTRACKFILE="$RF2ROOT\dlctracks.csv"
$CSVCONTENTFILE="$RF2ROOT\dlccontent.csv"

# name of the profile to use (refer to $RF2ROOT\Userdata\<profile>)
# note: can be given as argument on CLI where used in scripts
$PROFILE="player"