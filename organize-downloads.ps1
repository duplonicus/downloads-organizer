# Organize-Downloads.ps1
# Automatically organizes the Downloads folder into specific categories.

# --- Configuration ---
$SourceFolder = "$env:USERPROFILE\Downloads"
$LogFile = "$env:USERPROFILE\Downloads_Cleanup_Log.txt"

# Define destination paths
$Destinations = @{
    # Requested Paths
    Applications = "G:\Applications"
    Torrents     = "D:\Torrents\.torrents"
    DocsRoot     = "$env:USERPROFILE\Documents\My Documents"
    
    # Catch-all Paths (Standard Windows folders)
    Archives     = "$env:USERPROFILE\Documents\Archives"
    Images       = "$env:USERPROFILE\Pictures\Sorted_Downloads"
    Videos       = "$env:USERPROFILE\Videos\Sorted_Downloads"
    Music        = "$env:USERPROFILE\Music\Sorted_Downloads"
    Scripts      = "$env:USERPROFILE\Documents\Scripts"
}

# Define extension rules
$Rules = @{
    # Exes
    ".exe"  = $Destinations.Applications
    ".msi"  = $Destinations.Applications

    # Torrents
    ".torrent" = $Destinations.Torrents

    # Documents (Specific subfolders as requested)
    ".pdf"  = "$($Destinations.DocsRoot)\PDFs"
    ".txt"  = "$($Destinations.DocsRoot)\TXT"
    ".md"   = "$($Destinations.DocsRoot)\TXT"
    ".xlsx" = "$($Destinations.DocsRoot)\Spreadsheets"
    ".xls"  = "$($Destinations.DocsRoot)\Spreadsheets"
    ".csv"  = "$($Destinations.DocsRoot)\Spreadsheets"
    ".docx" = "$($Destinations.DocsRoot)\Word"
    ".doc"  = "$($Destinations.DocsRoot)\Word"

    # Archives (Catch-all)
    ".zip"  = $Destinations.Archives
    ".rar"  = $Destinations.Archives
    ".7z"   = $Destinations.Archives
    ".gz"   = $Destinations.Archives

    # Media (Catch-all)
    ".jpg"  = $Destinations.Images
    ".jpeg" = $Destinations.Images
    ".png"  = $Destinations.Images
    ".mp4"  = $Destinations.Videos
    ".mkv"  = $Destinations.Videos
    ".mp3"  = $Destinations.Music
    ".wav"  = $Destinations.Music

    # Code/Scripts (Catch-all)
    ".ps1"  = $Destinations.Scripts
    ".py"   = $Destinations.Scripts
    ".js"   = $Destinations.Scripts
    ".dll"  = $Destinations.Applications
    ".apk"  = $Destinations.Applications
    ".vlt"  = $Destinations.Scripts
}

# --- Execution ---

# Ensure we aren't moving active downloads (exclude partials)
$Files = Get-ChildItem -Path $SourceFolder -File | Where-Object { $_.Extension -ne ".crdownload" -and $_.Extension -ne ".tmp" -and $_.Extension -ne ".part" }

foreach ($File in $Files) {
    $Ext = $File.Extension.ToLower()
    
    # Unblock file if it has Zone.Identifier stream (downloaded from internet)
    Unblock-File -Path $File.FullName -ErrorAction SilentlyContinue
    
    # Skip files that are locked/in use by another process
    try {
        $FileStream = [System.IO.File]::Open($File.FullName, 'Open', 'Read', 'None')
        $FileStream.Close()
    }
    catch {
        $LogMessage = "$(Get-Date): Skipped '$($File.Name)' - file is in use"
        Add-Content -Path $LogFile -Value $LogMessage
        continue
    }
    
    if ($Rules.ContainsKey($Ext)) {
        $TargetFolder = $Rules[$Ext]

        # 1. Create directory if it doesn't exist
        if (-not (Test-Path -Path $TargetFolder)) {
            New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null
        }

        # 2. Check for duplicate filenames to avoid overwriting
        $DestinationPath = Join-Path -Path $TargetFolder -ChildPath $File.Name
        
        if (Test-Path -Path $DestinationPath) {
            # Append timestamp if file exists
            $TimeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $NewName = "{0}_{1}{2}" -f $File.BaseName, $TimeStamp, $File.Extension
            $DestinationPath = Join-Path -Path $TargetFolder -ChildPath $NewName
            $LogMessage = "$(Get-Date): File exists, using timestamped name: '$NewName'"
            Add-Content -Path $LogFile -Value $LogMessage
        }

        # 3. Move the file using robocopy (more reliable than Move-Item)
        try {
            # Create a temporary directory to hold just this file for robocopy
            $TempDir = "$env:TEMP\org_tmp_$(Get-Random)"
            New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
            Copy-Item -Path $File.FullName -Destination $TempDir -Force | Out-Null
            
            # Use robocopy to move (more reliable with locked/synced files)
            $RoboCopyResult = robocopy $TempDir $TargetFolder $File.Name /MOVE /R:1 /W:1 /NFL /NDL /NJH /NJS
            
            # Clean up temp directory
            Remove-Item -Path $TempDir -Force -Recurse -ErrorAction SilentlyContinue
            
            $LogMessage = "$(Get-Date): Moved '$($File.Name)' to '$DestinationPath'"
            Add-Content -Path $LogFile -Value $LogMessage
        }
        catch {
            $LogMessage = "$(Get-Date): ERROR moving '$($File.Name)' to '$DestinationPath' - $($_.Exception.Message)"
            Add-Content -Path $LogFile -Value $LogMessage
        }
    }
}

# Handle directories (extracted archives, etc.)
$Directories = Get-ChildItem -Path $SourceFolder -Directory

foreach ($Directory in $Directories) {
    # Move extracted folders to Archives
    $TargetFolder = $Destinations.Archives
    
    # 1. Create directory if it doesn't exist
    if (-not (Test-Path -Path $TargetFolder)) {
        New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null
    }
    
    # 2. Check for duplicate folder names
    $DestinationPath = Join-Path -Path $TargetFolder -ChildPath $Directory.Name
    
    if (Test-Path -Path $DestinationPath) {
        # Append timestamp if folder exists
        $TimeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $NewName = "{0}_{1}" -f $Directory.Name, $TimeStamp
        $DestinationPath = Join-Path -Path $TargetFolder -ChildPath $NewName
    }
    
    # 3. Move the directory using robocopy
    try {
        # Use robocopy to move directories (more reliable)
        $RoboCopyResult = robocopy $Directory.FullName $DestinationPath /E /MOVE /R:1 /W:1 /NFL /NDL /NJH /NJS
        $LogMessage = "$(Get-Date): Moved folder '$($Directory.Name)' to '$TargetFolder'"
        Add-Content -Path $LogFile -Value $LogMessage
    }
    catch {
        $LogMessage = "$(Get-Date): ERROR moving folder '$($Directory.Name)' - $($_.Exception.Message)"
        Add-Content -Path $LogFile -Value $LogMessage
    }
}

# Log completion
Add-Content -Path $LogFile -Value "$(Get-Date): Organize-Downloads task completed."
