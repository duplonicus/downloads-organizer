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
    ".png"  = $Destinations.Images
    ".mp4"  = $Destinations.Videos
    ".mkv"  = $Destinations.Videos
    ".mp3"  = $Destinations.Music
    ".wav"  = $Destinations.Music

    # Code/Scripts (Catch-all)
    ".ps1"  = $Destinations.Scripts
    ".py"   = $Destinations.Scripts
    ".js"   = $Destinations.Scripts
}

# --- Execution ---

# Ensure we aren't moving active downloads (exclude partials)
$Files = Get-ChildItem -Path $SourceFolder -File | Where-Object { $_.Extension -ne ".crdownload" -and $_.Extension -ne ".tmp" -and $_.Extension -ne ".part" }

foreach ($File in $Files) {
    $Ext = $File.Extension.ToLower()
    
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
        }

        # 3. Move the file
        try {
            Move-Item -Path $File.FullName -Destination $DestinationPath -ErrorAction Stop
            $LogMessage = "$(Get-Date): Moved '$($File.Name)' to '$TargetFolder'"
            Add-Content -Path $LogFile -Value $LogMessage
        }
        catch {
            $LogMessage = "$(Get-Date): ERROR moving '$($File.Name)' - $($_.Exception.Message)"
            Add-Content -Path $LogFile -Value $LogMessage
        }
    }
}

# Log completion
Add-Content -Path $LogFile -Value "$(Get-Date): Organize-Downloads task completed."
