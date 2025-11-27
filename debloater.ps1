# to get `adb` check https://developer.android.com/tools/releases/platform-tools
# adb extra info commands:
# adb shell dumpsys package > all_apps_info.txt
# list dangerouse permissions
# adb shell pm list permissions -d

## JUST CLICK AND RUN :D

# Get the JSON list of apps to debloat - recommended removals
$jsonUrl = "https://raw.githubusercontent.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/main/resources/assets/uad_lists.json"
# more info: https://gist.github.com/mcxiaoke/ade05718f590bcd574b807c4706a00b1
# https://xiaomitime.com/how-to-remove-useless-hyperos-apps-and-debloat-without-root-21525/
# adb cmd package install-existing <package>

$response = Invoke-WebRequest -Uri $jsonUrl -UseBasicParsing
$json = $response.Content | ConvertFrom-Json

# Extract keys where removal is "Recommended"
$apps = $json.PSObject.Properties | Where-Object { $_.Value.removal -eq "Recommended" } | Select-Object -ExpandProperty Name
$apps | Sort-Object | Out-File -FilePath "app.txt" -Encoding utf8

# Add extra apps:
@"
com.android.browser
com.miui.global.packageinstaller
com.xiaomi.aicr
com.android.providers.downloads.ui
com.xiaomi.bluetooth
com.xiaomi.joyose
com.xiaomi.micloud.sdk
com.milink.service
com.miui.audiomonitor
com.miui.cit
com.miui.mishare.connectivity
com.miui.misound
com.block.puzzle.game.hippo.mi
com.sukhavati.gotoplaying.bubble.BubbleShooter.mint
com.mintgames.triplecrush.tile.fun
com.mintgames.wordtrip
com.block.juggle
com.nf.snake
com.jewelsblast.ivygames.Adventure.free
com.logame.eliminateintruder3d
com.miui.calculator
com.android.thememanager
com.miui.gallery
com.xiaomi.xmsf
"@ | Out-File -FilePath "app.txt" -Encoding utf8 -Append

# If you got Boot Loop - remove from the list `com.xiaomi.xmsf`

# Google Debloating, Remove or comment out following section if you do not want remove these apps:
@"
com.google.android.aicore
com.google.android.apps.podcasts
com.google.android.apps.subscriptions.red
com.google.android.youtube
com.google.android.talk
com.google.android.videos
com.google.android.apps.tachyon
com.android.chrome
com.google.android.googlequicksearchbox
com.google.android.apps.wellbeing
com.google.android.feedback
com.google.android.marvin.talkback
com.google.android.music
com.android.deskclock
com.google.android.apps.messaging
com.google.android.contacts
com.google.android.dialer
com.google.android.tts
"@ | Out-File -FilePath "app.txt" -Encoding utf8 -Append

# Check for connected device
$adbList = adb devices | Select-String "device$" | Select-String -NotMatch "List of devices"
if (!$adbList) {
    Write-Host "No Android device connected. Make sure phone has USB Debug enabled and connected to computer. First time it should ask on phone to confirm the connection and keep phone screen ON"
    exit 1
}
Write-Host "Device connected: $adbList"

# This removes built in file explorer - before it is needed to have installed alternative!
# !!! comment out this section if you do not want it !!!
function Install-OpenSourceFileExplorer {
    # Prompt user to choose whether to install an open-source file explorer
    $choice = Read-Host "Do you want to remove the default file browser and replace it with an open-source file browser? (Y/N) [default: Y]"
    # If the user presses ENTER without typing anything, default is 'Y'
    if ([string]::IsNullOrEmpty($choice)) {
        $choice = 'Y'
    }

    if ($choice -eq 'Y' -or $choice -eq 'y') {
        # Download the F-Droid APK to Downloads folder
        Write-Host "Downloading F-Droid APK..."
        Invoke-WebRequest -Uri "https://f-droid.org/F-Droid.apk" -OutFile "1_F-droid.apk"        
        Write-Host "Pushing F-Droid APK to phone's Downloads folder..."
        adb push 1_F-droid.apk /sdcard/Download/
        Write-Host "Your phone should open the 1_F-Droid APK. Please install it before continuing." -ForegroundColor Yellow
        adb shell am start -a android.intent.action.VIEW -d "content://com.android.externalstorage.documents/document/primary%3ADownload"
        Read-Host "Press ENTER to continue when F-Droid is installed."
        Write-Host "Now F-Droid will need permissions to install apps. Please allow it, and then install Fossify Filemanager."        
        # Start F-Droid and open install page for Fossify Filemanager
        $info = Invoke-RestMethod "https://f-droid.org/api/v1/packages/org.fossify.filemanager"
        $code = $info.suggestedVersionCode
        $url  = "https://f-droid.org/repo/org.fossify.filemanager_$code.apk"
        $file = "org.fossify.filemanager_$code.apk"
        Invoke-WebRequest $url -OutFile $file | Out-Null
        adb shell mkdir -p /sdcard/Download 2>$null
        adb push $file "/sdcard/Download/" | Out-Null
        Write-Host "Fossify Filemanager APK has been pushed to your phone's Downloads folder." -ForegroundColor Yellow
        # This would open the Filemanager page in F-Droid, it require internet on phone...
        # adb shell am start -n org.fdroid.fdroid/org.fdroid.fdroid.views.AppDetailsActivity -e appid org.fossify.filemanager
        Read-Host "Press ENTER to continue when Fossify Filemanager is installed."
        @"
com.mi.android.globalFileexplorer
"@ | Out-File -FilePath "app.txt" -Encoding utf8 -Append
        Write-Host "Fossify Filemanager has been installed successfully!" -ForegroundColor Green
    } 
    else {
        Write-Host "You chose not to replace the default file browser. Skipping this stepp." -ForegroundColor Yellow
    }
}

Install-OpenSourceFileExplorer

# Deduplicating and sorting
Get-Content app.txt | Sort-Object -Unique | Set-Content app.txt -Encoding utf8

# ----------- Download open source Fossify apps fo manual install  to Downloads folder--------------
$appsToInstall = @(
    "org.fossify.clock"
    "org.fossify.musicplayer"
    "org.fossify.gallery"
    "org.fossify.calendar"
    "org.fossify.camera"
    "org.fossify.notes"
    "org.fossify.math"
    "org.fossify.messages"
    "org.fossify.phone"
    "org.fossify.contacts"
)

$successApk = @()
$failedApk  = @()

$tempFolder = Join-Path $PSScriptRoot "temp-apk"
adb shell "mkdir -p /sdcard/Download/DebloatAPKs"
if (-not (Test-Path $tempFolder)) { New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null }

foreach ($pkg in $appsToInstall) {
    try {
        $info = Invoke-RestMethod "https://f-droid.org/api/v1/packages/$pkg"
        $code = $info.suggestedVersionCode
        $url  = "https://f-droid.org/repo/${pkg}_$code.apk"
        $file = Join-Path $tempFolder "${pkg}_$code.apk"

        Invoke-WebRequest $url -OutFile $file | Out-Null
        adb shell mkdir -p /sdcard/Download 2>$null
        adb push $file "/sdcard/Download/DebloatAPKs/" | Out-Null
        #Remove-Item $file -Force

        $successApk += "$pkg (v$($info.suggestedVersionName))"
    }
    catch {
        $failedApk += "$pkg"
    }
}
# ---------------------------- Fossify apps download and push completed ----------------------------

# Get list of installed packages
$installed = adb shell pm list packages | ForEach-Object { $_.Replace("package:", "") } | Sort-Object

# Find intersection: apps from app.txt that are installed
$foundApps = Compare-Object -ReferenceObject (Get-Content "app.txt") -DifferenceObject $installed -IncludeEqual -ExcludeDifferent | Select-Object -ExpandProperty InputObject | Sort-Object
$foundApps | Out-File -FilePath "app.txt" -Encoding utf8

# Initialize arrays for logging
$removed = @()
$disabled = @()
$failed = @()
$totalApps = $foundApps.Count
$currentApp = 0

# Process each app in found_apps.txt with progress bar
$foundApps | ForEach-Object {
    $app = $_.Trim()
    if ($app) {
        $currentApp++
        $percentComplete = [math]::Round(($currentApp / $totalApps) * 100)
        Write-Progress -Activity "Debloating Android" -Status "Processing: $app" -PercentComplete $percentComplete -CurrentOperation "$currentApp / $totalApps"
        
        # Try to uninstall
        adb shell "pm uninstall -k --user 0 $app" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $removed += $app
        } else {
            # If uninstall fails, try to disable
            adb shell "pm disable-user --user 0 $app" 2>$null
            if ($LASTEXITCODE -eq 0) {
                $disabled += $app
            } else {
                $failed += $app
            }
        }
    }
}
Write-Progress -Activity "Debloating Android" -Completed
Write-Host "Identified $totalApps apps to clean up.`n"
if ($removed.Count) {
    Write-Host "`nSuccessfully removed ($($removed.Count)) apps." -ForegroundColor Green
}

if ($disabled.Count) {
    Write-Host "`nSuccessfully disabled ($($disabled.Count)) apps." -ForegroundColor Green
}

if ($failedApk.Count) {
    Write-Host "`nFailed to get opensource apps ($($failedApk.Count)):" -ForegroundColor Red
    $failedApk | ForEach-Object { Write-Host "   • $_" }
}
else {
    Write-Host "`nAll 10 Fossify alternative apps are in your phone's Downloads folder!" -ForegroundColor Green
    Write-Host "You can install them manually from there." -ForegroundColor Green
}

# Create CSV summary file - exactly your desired 5-column layout
$csvPath = "debloat_summary.csv"

# Use ArrayList instead of += (this removes the VSCode warning completely)
$csvContent = [System.Collections.ArrayList]::new()

# Add header
[void]$csvContent.Add("installed_apps,to_be_removed,deleted_apps,disabled_apps,failed_to_clean")

# Find max count for rows
$maxRows = ($installed.Count, $foundApps.Count, $removed.Count, $disabled.Count, $failed.Count) | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum

# Build CSV rows - fast and clean
for ($i = 0; $i -lt $maxRows; $i++) {
    $installedApp  = if ($i -lt $installed.Count)  { $installed[$i] }  else { "" }
    $toRemoveApp   = if ($i -lt $foundApps.Count)   { $foundApps[$i] }   else { "" }
    $removedApp    = if ($i -lt $removed.Count)     { $removed[$i] }     else { "" }
    $disabledApp   = if ($i -lt $disabled.Count)    { $disabled[$i] }    else { "" }
    $failedApp     = if ($i -lt $failed.Count)      { $failed[$i] }      else { "" }

    $row = "$installedApp,$toRemoveApp,$removedApp,$disabledApp,$failedApp"
    [void]$csvContent.Add($row)
}

# Write all at once - super fast and clean
$csvContent | Set-Content -Path $csvPath -Encoding UTF8

Write-Host "CSV summary saved to $csvPath" -ForegroundColor Green

# this creates TXT file with DNS address, you can copy paste it to DNS settings in your phone
Write-Host "Created dns.txt with Secure DNS addres in Downloads folder, you can use it for Ad and Malware blocking" -ForegroundColor Blue
Write-Host "In settings search 'Private DNS' set to custom and paste the address in" -ForegroundColor Blue
adb shell "echo no-malware-typo-ads.freedns.controld.com > /sdcard/Download/dns.txt"

Write-Host "`nNow is good to restart phone, if you get boot loop just factory reset it from recovery." -ForegroundColor Yellow
Write-Host "You may want to remove 'com.xiaomi.xmsf' from the list before running debloater again if you got boot loop issue." -ForegroundColor Yellow
# Adviced to block domains:
# Write-Host "`nAdviced to block following domains too:"
# @"
# sdkconfig.ad.xiaomi.com
# taobao.com
# tracking.miui.com
# micloud.xiaomi.net
# ccc.sys.miui.com
# api.zhuti.xiaomi.com
# amap.com
# transifex.com
# screentime.comm.miui.com
# api.xmpush.xiaomi.com
# thm.market.xiaomi.com
# zobj.net
# idm.api.io.mi.com
# ai.service.platform.xiaomi.com
# sandai.net
# com.xiaomi.gamecenter.sdk.service
# "@ | Write-Host 

# Do not block domain: sdkconfig.xiaomi.com
Write-Host "`nPhone app may need permissions, best to install it from F-Droid app instead of using APKs directly." -ForegroundColor Red
Write-Host "You can cancel the script, as clean up is done, or continue to install Phone, Messages and Contacts from F-Droid." -ForegroundColor Yellow
Read-Host "Press ENTER to continue, it opens F-Droid page for Fossify Phone"
adb shell am start -n org.fdroid.fdroid/org.fdroid.fdroid.views.AppDetailsActivity -e appid org.fossify.phone
Read-Host "Press ENTER to continue, it opens F-Droid page for Fossify Messages"
adb shell am start -n org.fdroid.fdroid/org.fdroid.fdroid.views.AppDetailsActivity -e appid org.fossify.messages
Read-Host "Press ENTER to continue, it opens F-Droid page for Fossify Contacts"
adb shell am start -n org.fdroid.fdroid/org.fdroid.fdroid.views.AppDetailsActivity -e appid org.fossify.contacts
