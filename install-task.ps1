# Install-Task.ps1
# Registers the Organize Downloads scheduled task using the XML template.

# --- Configuration ---
$TaskName = "OrganizeDownloads"
$XmlFileName = "organize-downloads.xml" 

# Check if XML exists in the current directory
if (-not (Test-Path $XmlFileName)) {
    Write-Error "Could not find '$XmlFileName'. Please save the XML code to a file in this folder."
    return
}

# 1. Locate the Organizer Script
# We assume the organizer script is in the same folder as this installer, 
# but you can hardcode the path below if different.
$ScriptPath = "$PSScriptRoot\Organize-Downloads.ps1"

if (-not (Test-Path $ScriptPath)) {
    Write-Warning "Could not find 'Organize-Downloads.ps1' in the current folder."
    $ScriptPath = Read-Host "Please paste the full path to your Organize-Downloads.ps1 file"
    
    if (-not (Test-Path $ScriptPath)) {
        Write-Error "Invalid path provided. Exiting."
        return
    }
}

Write-Host "Using Script: $ScriptPath" -ForegroundColor Cyan

# 2. Prepare the XML Content
# Read the XML and replace the placeholder __SCRIPT_PATH__ with the actual file path
$XmlContent = Get-Content -Path $XmlFileName -Raw
$XmlContent = $XmlContent -replace "__SCRIPT_PATH__", $ScriptPath

# 3. Register the Task
try {
    # Register-ScheduledTask requires a TaskObject or XML file path. 
    # Since we modified the XML in memory, we pass it as a string to the -Xml parameter.
    Register-ScheduledTask -Xml $XmlContent -TaskName $TaskName -Force -ErrorAction Stop
    
    Write-Host "------------------------------------------------"
    Write-Host "Success! Task '$TaskName' has been registered." -ForegroundColor Green
    Write-Host "It will run daily at 6:00 PM."
    Write-Host "You can verify it by opening Task Scheduler."
    Write-Host "------------------------------------------------"
}
catch {
    Write-Error "Failed to register task. Ensure you are running this script as Administrator."
    Write-Error $_.Exception.Message
}
