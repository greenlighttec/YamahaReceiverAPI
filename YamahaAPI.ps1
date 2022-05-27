## Yamaha Receiver Powershell Module
## Configure $Hostname in the "Invoke-YamahaAPI" function to be the IP or hostname of the receiver.
## Volume control is from 0-45, change the max/min ranges to go higher or lower. Note the API expects it as two digits + decimal place (-70.0db = -700)
## There are four scenes avaiable for configuration on the receiver call each scene by Set-YamahaScene -Scene <1-4>
##### THIS IS JUST FOR FUN I DONT CARE IF YOU LIKE IT

function Invoke-YamahaApi {
param(
$apiBody
)

$protocol = 'http'
$hostname = 'x.x.x.x'
$ApiEndpoint = 'YamahaRemoteControl/ctrl'

irm -Uri "$($protocol)://$($hostname)/$($ApiEndpoint)" -Method Post -ContentType text/xml -UseBasicParsing -Body $apiBody

}

function Set-YamahaAudioVolume {
param(
[ValidateRange(0, 45)][int]$volume
)


$MaxVolume = -25
$MinVolume = -70

$setValue = $volume + $MinVolume

$stringValue = "$($setValue)0"

$xmlBody = @"
<YAMAHA_AV cmd="PUT"><Main_Zone><Volume><Lvl><Val>$stringValue</Val><Exp>1</Exp><Unit>dB</Unit></Lvl></Volume></Main_Zone></YAMAHA_AV>
"@

return Invoke-YamahaApi -apiBody $xmlBody

}

function Set-YamahaScene {
param(
[ValidateRange(1, 4)][int]$scene
)

$xmlBody = @"
<YAMAHA_AV cmd="PUT"><Main_Zone><Scene><Scene_Load>Scene $scene</Scene_Load></Scene></Main_Zone></YAMAHA_AV>
"@

return Invoke-YamahaApi -apiBody $xmlBody

}
