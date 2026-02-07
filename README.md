# Downloads Organizer

Automatically organizes your Downloads folder into specific categories using a Windows scheduled task.

## Overview

This project provides a PowerShell-based solution to automatically sort downloaded files into organized folders based on file type. It runs daily at 6:00 PM as a scheduled Windows task.

## Features

- **Automatic Organization**: Sorts files into appropriate folders by file extension
- **Scheduled Execution**: Runs daily at 6:00 PM (configurable)
- **Duplicate Handling**: Appends timestamps to files if a file with the same name already exists
- **Logging**: Records all file movements and errors to a log file
- **Safe Filtering**: Excludes active downloads (`.crdownload`, `.tmp`, `.part` files)

## Project Structure

```
.
├── install-task.ps1          # Installer script - registers the scheduled task
├── organize-downloads.ps1    # Main organizer script - performs file sorting
├── organize-downloads.xml    # Windows Task Scheduler XML template
└── README.md                 # This file
```

## Installation

1. **Run as Administrator**: Open PowerShell as Administrator
2. **Navigate to the project folder**:
   ```powershell
   cd "C:\Path\to\downloads-organizer"
   ```
3. **Execute the installer**:
   ```powershell
   .\install-task.ps1
   ```

The installer will:
- Verify the organizer script exists
- Create the scheduled task
- Confirm successful registration

## File Organization Rules

### Applications
- `.exe`, `.msi` → `G:\Applications`

### Torrents
- `.torrent` → `D:\Torrents\.torrents`

### Documents (organized by type)
- `.pdf` → `Documents\My Documents\PDFs`
- `.txt`, `.md` → `Documents\My Documents\TXT`
- `.xlsx`, `.xls`, `.csv` → `Documents\My Documents\Spreadsheets`
- `.docx`, `.doc` → `Documents\My Documents\Word`

### Archives
- `.zip`, `.rar`, `.7z`, `.gz` → `Documents\Archives`

### Media
- `.jpg`, `.png` → `Pictures\Sorted_Downloads`
- `.mp4`, `.mkv` → `Videos\Sorted_Downloads`
- `.mp3`, `.wav` → `Music\Sorted_Downloads`

### Scripts
- `.ps1`, `.py`, `.js` → `Documents\Scripts`

## Configuration

Edit `organize-downloads.ps1` to customize:

- **Source folder**: Change `$SourceFolder` variable
- **Destination paths**: Modify the `$Destinations` hashtable
- **File rules**: Add/remove entries in the `$Rules` hashtable

Example:
```powershell
$Destinations = @{
    Applications = "G:\Applications"
    Torrents     = "D:\Torrents\.torrents"
    # ... add more as needed
}
```

## Logging

A log file is created at: `C:\Users\{YourUsername}\Downloads_Cleanup_Log.txt`

Contains records of:
- Successfully moved files
- Errors encountered
- Task completion status

## Running Manually

To run the organizer immediately (without waiting for the scheduled time):

```powershell
.\organize-downloads.ps1
```

## Verification

To verify the task is registered:

1. Open **Task Scheduler** (search in Windows)
2. Navigate to **Task Scheduler Library**
3. Look for **OrganizeDownloads** task
4. Check the trigger tab to confirm it runs daily at 6:00 PM

## Troubleshooting

### Task won't register
- Ensure you run `install-task.ps1` as Administrator
- Verify `organize-downloads.xml` is in the same directory

### Files not moving
- Check the log file: `C:\Users\{YourUsername}\Downloads_Cleanup_Log.txt`
- Verify destination folder paths exist and are accessible
- Ensure the script has read/write permissions to both source and destination folders

### Filename mismatch error
- Confirm all files are in the same directory
- File names are case-sensitive in the installer

## Requirements

- Windows 10 or later
- PowerShell 5.0+
- Administrator privileges (to install the task)
- Read/write access to Downloads folder and destination directories

## License

MIT License - Feel free to modify for your needs.
