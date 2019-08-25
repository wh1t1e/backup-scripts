#- If first checks for folders and creates them if they are missing.
#- It Checks the files from the Source in the Destination
#   1) If they exists it copies which ever is newer.
#   2) If they are missing it copies them to Destination
#- It Checks the files from the Destination in the Source
#   1) If they are missing it copies them to Destination

###################################################
###################################################
Param($Source,$Destination)
$Source = "C:\Users\Owner\Desktop\backup1"
$Destination = "C:\Users\Owner\Desktop\backup2"
function Get-FileMD5 {
   Param([string]$file)
   $mode = [System.IO.FileMode]("open")
   $access = [System.IO.FileAccess]("Read")
   $md5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
   $fs = New-Object System.IO.FileStream($file,$mode,$access)
   $Hash = $md5.ComputeHash($fs)
   $fs.Close()
   [string]$Hash = $Hash
   Return $Hash
}
function Copy-LatestFile{
    Param($File1,$File2,[switch]$whatif)
    $File1Date = get-Item $File1 | foreach-Object{$_.LastWriteTimeUTC}
    $File2Date = get-Item $File2 | foreach-Object{$_.LastWriteTimeUTC}
    if($File1Date -gt $File2Date)
    {
        Write-Host "$File1 is Newer... Copying..."
        if($whatif){Copy-Item -path $File1 -dest $File2 -force -whatif}
        else{Copy-Item -path $File1 -dest $File2 -force}
    }
    else
    {
        Write-Host "$File2 is Newer... Copying..."
        if($whatif){Copy-Item -path $File2 -dest $File1 -force -whatif}
        else{Copy-Item -path $File2 -dest $File1 -force}
    }
    Write-Host
}

# Getting Files/Folders from Source and Destination
$SrcEntries = Get-ChildItem $Source -Recurse
$DesEntries = Get-ChildItem $Destination -Recurse

# Parsing the folders and Files from Collections
$Srcfolders = $SrcEntries | Where-Object{$_.PSIsContainer}
$SrcFiles = $SrcEntries | Where-Object{!$_.PSIsContainer}
$Desfolders = $DesEntries | Where-Object{$_.PSIsContainer}
$DesFiles = $DesEntries | Where-Object{!$_.PSIsContainer}

# Checking for Folders that are in Source, but not in Destination
foreach($folder in $Srcfolders)
{
    $SrcFolderPath = $source -replace "\\","\\" -replace "\:","\:"
    $DesFolder = $folder.Fullname -replace $SrcFolderPath,$Destination
    if(!(test-path $DesFolder))
    {
        Write-Host "Folder $DesFolder Missing. Creating it!"
        new-Item $DesFolder -type Directory | out-Null
    }
}

# Checking for Folders that are in Destinatino, but not in Source
foreach($folder in $Desfolders)
{
    $DesFilePath = $Destination -replace "\\","\\" -replace "\:","\:"
    $SrcFolder = $folder.Fullname -replace $DesFilePath,$Source
    if(!(test-path $SrcFolder))
    {
        Write-Host "Folder $SrcFolder Missing. Creating it!"
        new-Item $SrcFolder -type Directory | out-Null
    }
}

# Checking for Files that are in the Source, but not in Destination
foreach($entry in $SrcFiles)
{
    $SrcFullname = $entry.fullname
    $SrcName = $entry.Name
    $SrcFilePath = $Source -replace "\\","\\" -replace "\:","\:"
    $DesFile = $SrcFullname -replace $SrcFilePath,$Destination
    if(test-Path $Desfile)
    {
        $SrcMD5 = Get-FileMD5 $SrcFullname
        $DesMD5 = Get-FileMD5 $DesFile
        If(Compare-Object $srcMD5 $desMD5)
        {
            Write-Host "The Files MD5's are Different... Checking Write
Dates"
            Write-Host $SrcMD5
            Write-Host $DesMD5
            Copy-LatestFile $SrcFullname $DesFile
        }
    }
    else
    {
        Write-Host "$Desfile Missing... Copying from $SrcFullname"
        copy-Item -path $SrcFullName -dest $DesFile -force
    }
}

# Checking for Files that are in the Destinatino, but not in Source
foreach($entry in $DesFiles)
{
    $DesFullname = $entry.fullname
    $DesName = $entry.Name
    $DesFilePath = $Destination -replace "\\","\\" -replace "\:","\:"
    $SrcFile = $DesFullname -replace $DesFilePath,$Source
    if(!(test-Path $SrcFile))
    {
        Write-Host "$SrcFile Missing... Copying from $DesFullname"
        copy-Item -path $DesFullname -dest $SrcFile -force
    }
}