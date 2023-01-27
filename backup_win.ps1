. .\Get-KnownFolder.ps1

$sevenZip = "$PSScriptRoot\.util\7za.exe"

$x = 'Microsoft\Windows\CurrentVersion\Uninstall\*'
$backupInfo = ("HKLM:\Software\$x", "HKCU:\SOFTWARE\$x", "HKLM:\Software\Wow6432Node\$x") | Get-ItemProperty | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate -Unique | Sort-Object -Property DisplayName

# folders that should be backed

$toBack = @()
$toBack += [System.Environment]::GetFolderPath("MyDocuments")
$toBack += [System.Environment]::GetFolderPath("DesktopDirectory")
$toBack += Get-KnownFolderPath "SavedGames"

$nobackup = @()
foreach ($folder in $toBack) {
    $nobackup += (Get-ChildItem $folder -Recurse -Filter ".nobackup").Directory
}

"$PSScriptRoot\backup_exclude.txt", "$PSScriptRoot\backup_exclude.txt" | Remove-Item -ErrorAction Ignore
$nobackup.FullName -join "`n" | Out-File "$PSScriptRoot\backup_exclude.txt" -Encoding utf8 -NoNewline
$toBack -join "`n" | Out-File "$PSScriptRoot\backup_include.txt" -Encoding utf8 -NoNewline
. $sevenZip a -t7z Documents.7z -i@"backup_include.txt" -x@"backup_exclude.txt"