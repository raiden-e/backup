$backupFile = "Documents.7z"
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

if (Test-Path $backupFile) {
    Remove-Item $backupFile -ErrorAction Stop
}

try {
    if (Test-Path "$PSScriptRoot\backup_exclude.txt") {
        "$PSScriptRoot\backup_exclude.txt" | Remove-Item -ErrorAction Inquire
    }
    foreach ($folder in $toBack) {
        if((Get-item $folder) -is [IO.FileInfo]){
            continue
        }
        Write-Host "Backing $folder"
        $folderRel = $folder.LastIndexOf("\") + 1
        try {
            foreach ($n in (Get-ChildItem $folder -Recurse -Filter ".nobackup").Directory.FullName) {
                $nobackupFile += $n.Substring($folderRel) + "`n"
            }
        } catch {
            $_
        }
    }

    $nobackupFile | Out-File "$PSScriptRoot\backup_exclude.txt" -Encoding utf8
    $toBack | Out-File "$PSScriptRoot\backup_include.txt" -Encoding utf8
    . $sevenZip a -t7z $backupFile -x@"backup_exclude.txt" -i@"backup_include.txt"
} finally {
    Write-Host ".nobackup's found in:"
    Write-Host $nobackupFile
}
