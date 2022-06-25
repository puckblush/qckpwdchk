Write-Host -Background black -Fore yellow @"
[\][/][\][/][\]
[/| Quick   [/|
[\| Passwd  [\|
[/| Check   [/|
[\][/][\][/][\]
"@
$lowgradeterms = @("data","info","user",".xml",".csv",".xlsx")
$highgradeterms = @("pass","login","flag","pwd","admin","cred","account","acct")
$unattendPaths = @("$Env:SystemDrive\Windows\Panther","$Env:SystemDrive\Windows\System32\Panther","$Env:SystemDrive\Windows\System32\Sysprep")
$maxFileSize = 8192

Write-Host -Background black -fore yellow "Running as $(whoami)`n"
Write-Host -Background black -Fore cyan "Checking PSReadLine files..."
foreach($user in (Get-ChildItem "$Env:SystemDrive\Users")) {

$username = $user.Name
$ReadlinePath = "$Env:SystemDrive\Users\$username\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
Write-Host -Fore magenta -Back black " ====== $user ====== : "

try { $PSReadlineContent = Get-Content -Erroraction stop $ReadlinePath }
catch [System.UnauthorizedAccessException] {Write-Host -Back black -Fore red "Access denied"}
catch [System.Management.Automation.ItemNotFoundException] {Write-Host -Back black -Fore red "User does not have a PSReadLine file"}
catch { Write-Host -Back black -Fore red "An error occured! : " $_.Exception }

foreach($line in $PSReadlineContent) {
$printed = 0
foreach($term in $highgradeterms) {
if($line.ToLower().contains($term) -and $printed -eq 0) {
Write-Host -Back black -Fore green "LINE : " $line
$printed = 1
}
}

foreach($term in $lowgradeterms) {
if($line.contains($term) -and $printed -eq 0) {
Write-Host -Back black -Fore yellow "LINE : " $line
$printed = 1
}
}
if($printed -eq 0) {
Write-Host -Back black -Fore white "LINE : " $line
}

}
$PSReadlineContent = ""

}

Write-Host -Background black -Fore cyan "`nChecking Common Document Locations..."
Write-Host -Background black -Fore cyan "Search Terms : $highgradeterms $lowgradeterms"
Write-Host -Background black -Fore cyan "Max File Size : $maxFileSize"
foreach($user in (Get-ChildItem "$Env:SystemDrive\Users")) {
Write-Host -Fore magenta -Back black "====== $user ======"

$profile = "$Env:SystemDrive\Users\$user\"
$chromePath = "$profile\AppData\Local\Google\Chrome"
$firefoxPath = "$profile\AppData\Local\Mozilla\Firefox"

try {
if(Test-Path -Erroraction 'stop' $chromePath) {
Write-Host -Fore green -Back black "BROWSER: User has a Chrome profile at '$chromePath'; It may contain login information"
}
if(Test-Path -Erroraction 'stop' $firefoxPath) {
Write-Host -Fore green -Back black "BROWSER: User has a Firefox profile at '$firefoxPath'; It may contain login information"
}
}
catch [System.UnauthorizedAccessException] {Write-Host -Back black -Fore red "Access denied"}
catch { Write-Host -Back black -Fore red "An error occured! : " $_.Exception }

try {
$filelist = Get-ChildItem -Erroraction 'stop' $profile -Recurse
foreach($file in $filelist) {
$filename = $file.Name

foreach($term in $highgradeterms) {
if($filename.ToLower().contains($term)) {
Write-Host -Fore green -Back black $file.FullName
}
}

foreach($term in $lowgradeterms) {
if($filename.ToLower().contains($term)) {
Write-Host -Fore yellow -Back black $file.FullName
}
}

try {
if($file.length -lt $maxFileSize -and $file.FullName.endswith(".exe") -ne $true -and $file.FullName.endswith(".lnk") -ne $true -and $file.FullName.endswith(".dll") -ne $true) {

$filecontent = Get-Content -Erroraction 'stop' $file.FullName
if($filecontent.length -eq 32) {
Write-Host -Back black -Fore green "HASH: '$file.FullName' might be a hash"
}
foreach($term in $highgradeterms) {
if($filecontent.ToLower().contains($term)) {
Write-Host -Fore green -Back black "'$term' found in " $file.FullName " :"
$termContent = (Get-Content -Erroraction 'stop' $file.FullName | Select-String $term)
Write-Host -Back black -Fore green "=== > " $termContent
}
}
foreach($term in $lowgradeterms) {
if($filecontent.ToLower().contains($term)) {
Write-Host -Fore yellow -Back black "'$term' found in " $file.FullName
$termContent = (Get-Content -Erroraction 'stop' $file.FullName | Select-String $term)
Write-Host -Back black -Fore yellow " === > " $termContent
}
}
}
}

catch {
}

}
}
catch [System.UnauthorizedAccessException] {Write-Host -Back black -Fore red "Access denied"}
catch [System.Management.Automation.ItemNotFoundException] {Write-Host -Back black -Fore red "User does not have a Profile"}
catch { Write-Host -Back black -Fore red "An error occured! : " $_.Exception }
}

Write-Host -Background black -Fore cyan "Checking Unattend files..."
foreach($unattendPath in $unattendPaths) {
try {

$files = Get-ChildItem -Erroraction 'stop' $unattendPath -Recurse -Include *.xml

foreach($file in $files) {
try {
$content = Get-Content -Erroraction stop $file.FullName
Write-Host -Fore magenta -Back black " ====== $file ====== : "
$content = $content.split(">")
foreach($entry in $content) {
if($entry.ToLower().contains("</value")) {
Write-Host -Back black -Fore green "[UNATTEND] Possible Password Value (Base64 Encoded) :" $entry.Trim().split("<")[0]
}
elseif($entry.ToLower().contains("</password")) {
Write-Host -Back black -Fore green "[UNATTEND] Possible Password Value (Base64 Encoded) :" $entry.Trim().split("<")[0]
}
elseif($entry.ToLower().contains("</username")) {
Write-Host -Back black -Fore green "[UNATTEND] Possible Username Value :" $entry.Trim().split("<")[0]
}
elseif($entry.ToLower().contains("</name") -or $entry.ToLower().contains("</description")) {
Write-Host -Back black -Fore yellow "[UNATTEND] Possible Misc Value :" $entry.Trim().split("<")[0]
}

}
}
catch [System.UnauthorizedAccessException] {Write-Host -Back black -Fore red "Access denied for file '$file'"}
catch [System.Management.Automation.ItemNotFoundException] {Write-Host -Back black -Fore red "No unattend path at $unattendPath"}
catch { Write-Host -Back black -Fore red "An error occured! : " $_.Exception }
}

}
catch [System.UnauthorizedAccessException] {Write-Host -Back black -Fore red "Access denied"}
catch [System.Management.Automation.ItemNotFoundException] {Write-Host -Back black -Fore red "No unattend path at $unattendPath"}
catch { Write-Host -Back black -Fore red "An error occured! : " $_.Exception }

}
