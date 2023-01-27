[CmdletBinding()]
param (
    $backupFile = "Documents.7z",
    $password,
    $mx=9,
    $mhe="on"
    # $v="-v100m"
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
$x = 'Microsoft\Windows\CurrentVersion\Uninstall\*'
$backupInfo = ("HKLM:\Software\$x", "HKCU:\SOFTWARE\$x", "HKLM:\Software\Wow6432Node\$x") | Get-ItemProperty | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate -Unique | Sort-Object -Property DisplayName
$backupInfo | Out-File "$PSScriptRoot\backup_info.txt" -Encoding utf8 -NoNewline

$backupInclude = "$PSScriptRoot\backup_include.txt"
$backupExclude = "$PSScriptRoot\backup_exclude.txt"

if (Test-Path $backupFile) {
    Remove-Item $backupFile -ErrorAction Stop
}

try {
    if (Test-Path $backupExclude) { $backupExclude | Remove-Item -ErrorAction Inquire }
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
    . $sevenZip a -t7z -mx=9 -v100m $backupFile -x@"backup_exclude.txt" -i@"backup_include.txt"
} finally {
    Write-Host ".nobackup's found in:"
    Write-Host $nobackupFile
}
