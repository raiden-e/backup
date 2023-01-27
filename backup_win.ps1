[CmdletBinding()]
param (
    $backupFile = "Documents.7z",
    $backupFolder = "backup",
    $password,
    [int]$mx = 9,
    $mhe = "on",
    [int]$v = 100
)


$sevenZip = "$PSScriptRoot\.util\7za.exe"

# folders that should be backed
. .\Get-KnownFolder.ps1
$toBack = @()
$toBack += [System.Environment]::GetFolderPath("MyDocuments")
$toBack += [System.Environment]::GetFolderPath("DesktopDirectory")
$toBack += Get-KnownFolderPath "SavedGames"
$toBack += "$env:USERPROFILE\.gnupg"
$toBack += "$PSScriptRoot\backup_info.txt"


# Script

if(Test-Path $backupFolder -PathType Container){
    Remove-Item $backupFolder -Recurse -Force
}
foreach ($dir in ("tmp", $backupFolder)){
    if(!(Test-Path $dir -PathType Container)){
        New-Item $dir -ItemType Directory -Force
    }
}

$backupFile = "$backupFolder\$backupFile"

$x = 'Microsoft\Windows\CurrentVersion\Uninstall\*'
$backupInfo = ("HKLM:\Software\$x", "HKCU:\SOFTWARE\$x", "HKLM:\Software\Wow6432Node\$x") | Get-ItemProperty | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate -Unique | Sort-Object -Property DisplayName
$backupInfo | Out-File "$PSScriptRoot\backup_info.txt" -Encoding utf8 -NoNewline

$backupInclude = "$PSScriptRoot\backup_include.txt"
$backupExclude = "$PSScriptRoot\backup_exclude.txt"


if (Test-Path $backupExclude) {
    Write-Host "Deleting $backupExclude"
    Remove-Item $backupExclude -ErrorAction Inquire
}
foreach ($folder in $toBack) {
    if ((Get-Item $folder) -is [IO.FileInfo]) { continue }

    Write-Host "Backing $folder"
    $folderRel = $folder.LastIndexOf("\") + 1
    try {
        foreach ($n in (Get-ChildItem $folder -Recurse -Filter ".nobackup").Directory.FullName) {
            $nobackupFile += $n.Substring($folderRel) + "`n"
        }
    } catch { $_ }
}

# params
$nobackupFile | Out-File $backupExclude -Encoding utf8
$toBack | Out-File $backupInclude -Encoding utf8
if ($v) {
    $split = "-v${v}m"
}
. $sevenZip a "-t7z" "-mx=$mx" "$split" "-p""$password""" $backupFile -x@"backup_exclude.txt" -i@"backup_include.txt"

if (!$?) {
    return
}

Write-Host ".nobackup's found in:"
Write-Host $nobackupFile
