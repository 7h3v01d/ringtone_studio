# Sends .m4r ringtones to an iPhone through iTunes (Windows). No installs needed.
# Run with no argument = file picker. Run with a ringtonesender:// link = send that file automatically.
param([string]$Url = '')
Add-Type -AssemblyName System.Windows.Forms
function Say($text, $icon = 'Information') {
    [void][System.Windows.Forms.MessageBox]::Show($text, 'Send Ringtone to iPhone', 'OK', $icon)
}

# 1. Find the ringtone(s): from the website link, or let the user pick
$dl = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'
$files = @()
if ($Url -match '^ringtonesender:(//)?send\?name=([^&]+)') {
    $name = [IO.Path]::GetFileName([Uri]::UnescapeDataString($Matches[2]))
    if ($name -match '^[\w\-\. \(\)]+\.m4r$') {
        $target = Join-Path $dl $name
        for ($i = 0; $i -lt 40 -and -not (Test-Path $target); $i++) { Start-Sleep -Milliseconds 500 }
        if (Test-Path $target) { $files = @($target) }
        else {
            $recent = Get-ChildItem $dl -Filter *.m4r -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-3) } |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($recent) { $files = @($recent.FullName) }
        }
    }
}
if ($files.Count -eq 0) {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = 'Choose your ringtone(s)'
    $dlg.InitialDirectory = $dl
    $dlg.Filter = 'iPhone ringtones (*.m4r)|*.m4r'
    $dlg.Multiselect = $true
    if ($dlg.ShowDialog() -ne 'OK') { exit }
    $files = $dlg.FileNames
}

# 2. Start iTunes
try { $it = New-Object -ComObject iTunes.Application }
catch {
    Say "iTunes could not be started.`n`nMake sure iTunes is installed, open it once by hand, then try again." 'Error'
    exit
}

# 3. Add each tone to the iTunes library (it lands in Tones)
$added = 0; $tooLong = @()
foreach ($f in $files) {
    try {
        $st = $it.LibraryPlaylist.AddFile($f)
        $n = 0
        while ($st -and $st.InProgress -and $n -lt 150) { Start-Sleep -Milliseconds 200; $n++ }
        if ($st) {
            for ($i = 1; $i -le $st.Tracks.Count; $i++) {
                if ($st.Tracks.Item($i).Duration -gt 40.5) { $tooLong += [IO.Path]::GetFileName($f) }
            }
            $added++
        }
    } catch { }
}
if ($added -eq 0) {
    Say "iTunes would not accept the file(s). Make sure they end in .m4r." 'Error'
    exit
}

# 4. Find the iPhone and sync
$dev = $null
for ($i = 1; $i -le $it.Sources.Count; $i++) {
    if ($it.Sources.Item($i).Kind -eq 2) { $dev = $it.Sources.Item($i) }
}
if (-not $dev) {
    Say ("Your ringtone(s) are in iTunes, but no iPhone was found.`n`n" +
         "Plug in the iPhone, unlock it, tap 'Trust', wait for the little phone icon to appear in iTunes, then run this again.")
    exit
}
$it.UpdateIPod()

$msg = "Done! Syncing $added ringtone(s) to '$($dev.Name)'.`n`nWait until iTunes finishes syncing (progress shows at the top), then on the phone go to:`nSettings > Sounds & Haptics > Ringtone"
if ($tooLong.Count) { $msg += "`n`nWarning: iPhone ignores tones over 40 seconds: " + ($tooLong -join ', ') }
$msg += "`n`nIf the tone does not show up: in iTunes click the phone icon > Tones > tick 'Sync Tones' > Apply (one-time setup)."
Say $msg
