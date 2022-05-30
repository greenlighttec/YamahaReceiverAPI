## Yamaha Receiver Powershell Module
## Volume control is from 0-45, change the max/min ranges to go higher or lower. Note the API expects it as two digits + decimal place (-70.0db = -700)
## There are four scenes avaiable for configuration on the receiver call each scene by Set-YamahaScene -Scene <1-4>
##### THIS IS JUST FOR FUN I DONT CARE IF YOU LIKE IT
## Global Variables here for your environment

#### Set the max DB and min DB values here
$MaxVolume = -25
$MinVolume = -70
Set-Variable -Name VolumeRange -Value $MaxVolume - $MinVolume -Option Constant

### Set your hostname and protocol here
$protocol = 'http'
$hostname = '10.23.1.10'


function Invoke-YamahaApi {
param(
$apiBody
)


$ApiEndpoint = 'YamahaRemoteControl/ctrl'

irm -Uri "$($protocol)://$($hostname)/$($ApiEndpoint)" -Method Post -ContentType text/xml -UseBasicParsing -Body $apiBody

}

function Get-YamahaPlayStatus {


$xmlBody = @"
<YAMAHA_AV cmd="GET"><Pandora><Play_Info>GetParam</Play_Info></Pandora></YAMAHA_AV>
"@

$results = Invoke-YamahaApi -apiBody $xmlBody

Write-Host "Current Status: $($Results.childNodes.ChildNodes.ChildNodes.playback_info)" -ForegroundColor Cyan

return $results.YAMAHA_AV.ChildNodes.Play_Info.meta_info

}

function Get-YamahaGeneralStatus {

$xmlBody = @'
<YAMAHA_AV cmd="GET"><Main_Zone><Basic_Status>GetParam</Basic_Status></Main_Zone></YAMAHA_AV>
'@

$WebRequest = Invoke-YamahaApi -apiBody $xmlBody

$BaseDetails = $WebRequest.ChildNodes.ChildNodes.ChildNodes

# Calculate current Volume from DB, ignoring decimal place. We're sacrificing half a decibel here
[int]$CurrentVolume = ($BaseDetails.volume.lvl.val).Substring(0,3)
$Volume = $CurrentVolume - $MinVolume
if ($Volume -eq 0) {$Volume = 'MIN'} elseif ($Volume -eq $VolumeRange) {$Volume = 'MAX'}

$CurrentStatus = $BaseDetails.Power_Control.power
$AutoSleep = $BaseDetails.Power_Control.sleep

[pscustomobject]$returnValues = @{
    PowerState = $CurrentStatus
    AutoSleep = $AutoSleep
    Volume = $Volume
    SelectedInput = $BaseDetails.input.input_sel

}

$returnValues

return Get-YamahaPlayStatus

}

function Set-YamahaAudioVolume {
param(
[ValidateRange(0, $VolumeRange)][int]$volume
)

# Convert the integer volume range to a dB value for the receiver, including third decimal digit.
$setValue = $volume + $MinVolume
$stringValue = "$($setValue)0"

$xmlBody = @"
<YAMAHA_AV cmd="PUT"><Main_Zone><Volume><Lvl><Val>$stringValue</Val><Exp>1</Exp><Unit>dB</Unit></Lvl></Volume></Main_Zone></YAMAHA_AV>
"@

$WebRequest = Invoke-YamahaApi -apiBody $xmlBody

return Get-YamahaGeneralStatus

}

function Set-YamahaScene {
param(
[ValidateRange(1, 4)][int]$scene
)

$xmlBody = @"
<YAMAHA_AV cmd="PUT"><Main_Zone><Scene><Scene_Load>Scene $scene</Scene_Load></Scene></Main_Zone></YAMAHA_AV>
"@

$WebRequest = Invoke-YamahaApi -apiBody $xmlBody
return Get-YamahaGeneralStatus

}
