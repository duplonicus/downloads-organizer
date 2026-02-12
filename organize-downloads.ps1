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

    # Documents
    ".pdf"  = "$($Destinations.DocsRoot)\PDFs"
    ".txt"  = "$($Destinations.DocsRoot)\TXT"
    ".md"   = "$($Destinations.DocsRoot)\TXT"
    ".xlsx" = "$($Destinations.DocsRoot)\Spreadsheets"
    ".xls"  = "$($Destinations.DocsRoot)\Spreadsheets"
    ".csv"  = "$($Destinations.DocsRoot)\Spreadsheets"
    ".docx" = "$($Destinations.DocsRoot)\Word"
    ".doc"  = "$($Destinations.DocsRoot)\Word"

    # Archives
    ".zip"  = $Destinations.Archives
    ".rar"  = $Destinations.Archives
    ".7z"   = $Destinations.Archives
    ".gz"   = $Destinations.Archives

    # Media
    ".jpg"  = $Destinations.Images
    ".jpeg" = $Destinations.Images
    ".png"  = $Destinations.Images
    ".mp4"  = $Destinations.Videos
    ".mkv"  = $Destinations.Videos
    ".mp3"  = $Destinations.Music
    ".wav"  = $Destinations.Music

    # Code/Scripts
    ".ps1"  = $Destinations.Scripts
    ".py"   = $Destinations.Scripts
    ".js"   = $Destinations.Scripts
    ".dll"  = $Destinations.Applications
    ".apk"  = $Destinations.Applications
    ".vlt"  = $Destinations.Scripts
}

# --- Execution ---

# Ensure we aren't moving active downloads
$Files = Get-ChildItem -Path $SourceFolder -File | Where-Object { $_.Extension -ne ".crdownload" -and $_.Extension -ne ".tmp" -and $_.Extension -ne ".part" }

foreach ($File in $Files) {
    $Ext = $File.Extension.ToLower()
    
    # Unblock file (remove Zone.Identifier)
    Unblock-File -Path $File.FullName -ErrorAction SilentlyContinue
    
    # Skip locked files
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

        # 1. Create directory if needed
        if (-not (Test-Path -Path $TargetFolder)) {
            New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null
        }

        # 2. Check for duplicate filenames
        $DestinationPath = Join-Path -Path $TargetFolder -ChildPath $File.Name
        
        if (Test-Path -Path $DestinationPath) {
            $TimeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $NewName = "{0}_{1}{2}" -f $File.BaseName, $TimeStamp, $File.Extension
            $DestinationPath = Join-Path -Path $TargetFolder -ChildPath $NewName
            $LogMessage = "$(Get-Date): File exists, using timestamped name: '$NewName'"
            Add-Content -Path $LogFile -Value $LogMessage
        }

        # 3. Move the file with Explicit Verification
        try {
            # Attempt standard move
            Move-Item -Path $File.FullName -Destination $DestinationPath -Force -ErrorAction Stop
            
            # CRITICAL CHECK: Did the source file actually disappear?
            if (Test-Path -Path $File.FullName) {
                
                # Check if destination file exists (meaning it was a Copy, not a Move)
                if (Test-Path -Path $DestinationPath) {
                    # Manual Delete of Source
                    Remove-Item -Path $File.FullName -Force -ErrorAction Stop
                    $LogMessage = "$(Get-Date): Moved (Copy+Delete) '$($File.Name)' to '$DestinationPath'"
                } else {
                     # Destination missing? Then the move failed completely.
                     throw "Move failed: Destination file missing."
                }
            } else {
                # Source is gone, so move was successful
                $LogMessage = "$(Get-Date): Moved '$($File.Name)' to '$DestinationPath'"
            }
            
            Add-Content -Path $LogFile -Value $LogMessage
        }
        catch {
            # 4. Fallback to Robocopy /MOV if Move-Item + Delete fails
            $LogMessage = "$(Get-Date): Move-Item failed for '$($File.Name)', attempting robocopy fallback..."
            Add-Content -Path $LogFile -Value $LogMessage
            
            try {
                $RoboArgs = @($SourceFolder, $TargetFolder, $File.Name, "/MOV", "/R:1", "/W:1", "/NFL", "/NDL", "/NJH", "/NJS")
                & robocopy $RoboArgs | Out-Null
                
                if (Test-Path -Path $File.FullName) {
                     $LogMessage = "$(Get-Date): WARNING - Robocopy ran but file '$($File.Name)' still exists in source."
                     Add-Content -Path $LogFile -Value $LogMessage
                } else {
                     $LogMessage = "$(Get-Date): Robocopy successfully moved '$($File.Name)'"
                     Add-Content -Path $LogFile -Value $LogMessage
                }
            }
            catch {
                $LogMessage = "$(Get-Date): CRITICAL ERROR moving '$($File.Name)' - $($_.Exception.Message)"
                Add-Content -Path $LogFile -Value $LogMessage
            }
        }
    }
}

# Handle directories (extracted archives, etc.)
$Directories = Get-ChildItem -Path $SourceFolder -Directory

foreach ($Directory in $Directories) {
    $TargetFolder = $Destinations.Archives
    
    if (-not (Test-Path -Path $TargetFolder)) {
        New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null
    }
    
    $DestinationPath = Join-Path -Path $TargetFolder -ChildPath $Directory.Name
    
    if (Test-Path -Path $DestinationPath) {
        $TimeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $NewName = "{0}_{1}" -f $Directory.Name, $TimeStamp
        $DestinationPath = Join-Path -Path $TargetFolder -ChildPath $NewName
    }
    
    try {
        Move-Item -Path $Directory.FullName -Destination $DestinationPath -Force -ErrorAction Stop
        
        # Verify Directory Move
        if (Test-Path -Path $Directory.FullName) {
             if (Test-Path -Path $DestinationPath) {
                 Remove-Item -Path $Directory.FullName -Recurse -Force -ErrorAction Stop
                 $LogMessage = "$(Get-Date): Moved (Copy+Delete) folder '$($Directory.Name)' to '$DestinationPath'"
             }
        } else {
            $LogMessage = "$(Get-Date): Moved folder '$($Directory.Name)' to '$DestinationPath'"
        }
        
        Add-Content -Path $LogFile -Value $LogMessage
    }
    catch {
        $LogMessage = "$(Get-Date): ERROR moving folder '$($Directory.Name)' - $($_.Exception.Message)"
        Add-Content -Path $LogFile -Value $LogMessage
    }
}

Add-Content -Path $LogFile -Value "$(Get-Date): Organize-Downloads task completed."
