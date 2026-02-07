#!/bin/bash

# Organize-Downloads.sh
# Automatically organizes the Downloads folder into specific categories.

# --- Configuration ---
SOURCE_FOLDER="$HOME/Downloads"
LOG_FILE="$HOME/Downloads_Cleanup_Log.txt"

# Define destination paths
declare -A DESTINATIONS=(
    [Applications]="$HOME/Applications"
    [Torrents]="$HOME/Torrents"
    [DocsRoot]="$HOME/Documents/My Documents"
    [Archives]="$HOME/Documents/Archives"
    [Images]="$HOME/Pictures/Sorted_Downloads"
    [Videos]="$HOME/Videos/Sorted_Downloads"
    [Music]="$HOME/Music/Sorted_Downloads"
    [Scripts]="$HOME/Documents/Scripts"
)

# Define extension rules
declare -A RULES=(
    # Executables
    [exe]="${DESTINATIONS[Applications]}"
    [msi]="${DESTINATIONS[Applications]}"
    [deb]="${DESTINATIONS[Applications]}"
    [rpm]="${DESTINATIONS[Applications]}"
    [app]="${DESTINATIONS[Applications]}"
    
    # Torrents
    [torrent]="${DESTINATIONS[Torrents]}"
    
    # Documents
    [pdf]="${DESTINATIONS[DocsRoot]}/PDFs"
    [txt]="${DESTINATIONS[DocsRoot]}/TXT"
    [md]="${DESTINATIONS[DocsRoot]}/TXT"
    [xlsx]="${DESTINATIONS[DocsRoot]}/Spreadsheets"
    [xls]="${DESTINATIONS[DocsRoot]}/Spreadsheets"
    [csv]="${DESTINATIONS[DocsRoot]}/Spreadsheets"
    [docx]="${DESTINATIONS[DocsRoot]}/Word"
    [doc]="${DESTINATIONS[DocsRoot]}/Word"
    
    # Archives
    [zip]="${DESTINATIONS[Archives]}"
    [rar]="${DESTINATIONS[Archives]}"
    [7z]="${DESTINATIONS[Archives]}"
    [gz]="${DESTINATIONS[Archives]}"
    [tar]="${DESTINATIONS[Archives]}"
    [bz2]="${DESTINATIONS[Archives]}"
    
    # Media
    [jpg]="${DESTINATIONS[Images]}"
    [jpeg]="${DESTINATIONS[Images]}"
    [png]="${DESTINATIONS[Images]}"
    [gif]="${DESTINATIONS[Images]}"
    [mp4]="${DESTINATIONS[Videos]}"
    [mkv]="${DESTINATIONS[Videos]}"
    [avi]="${DESTINATIONS[Videos]}"
    [mov]="${DESTINATIONS[Videos]}"
    [mp3]="${DESTINATIONS[Music]}"
    [wav]="${DESTINATIONS[Music]}"
    [flac]="${DESTINATIONS[Music]}"
    [aac]="${DESTINATIONS[Music]}"
    
    # Code/Scripts
    [ps1]="${DESTINATIONS[Scripts]}"
    [py]="${DESTINATIONS[Scripts]}"
    [js]="${DESTINATIONS[Scripts]}"
    [sh]="${DESTINATIONS[Scripts]}"
    [go]="${DESTINATIONS[Scripts]}"
    [rb]="${DESTINATIONS[Scripts]}"
)

# --- Execution ---

# Exclude hidden files and partial downloads
shopt -s nullglob
for FILE in "$SOURCE_FOLDER"/*; do
    # Skip directories
    [[ -d "$FILE" ]] && continue
    
    # Skip hidden files and partials
    FILENAME=$(basename "$FILE")
    [[ "$FILENAME" == .* ]] && continue
    [[ "$FILENAME" == *.crdownload ]] && continue
    [[ "$FILENAME" == *.tmp ]] && continue
    [[ "$FILENAME" == *.part ]] && continue
    
    # Get file extension (lowercase)
    EXT="${FILENAME##*.}"
    EXT="${EXT,,}"
    
    if [[ -n "${RULES[$EXT]}" ]]; then
        TARGET_FOLDER="${RULES[$EXT]}"
        
        # 1. Create directory if it doesn't exist
        mkdir -p "$TARGET_FOLDER"
        
        # 2. Check for duplicate filenames
        DESTINATION_PATH="$TARGET_FOLDER/$FILENAME"
        
        if [[ -f "$DESTINATION_PATH" ]]; then
            # Append timestamp if file exists
            TIMESTAMP=$(date +%Y%m%d-%H%M%S)
            BASENAME="${FILENAME%.*}"
            EXTENSION=".${FILENAME##*.}"
            NEW_NAME="${BASENAME}_${TIMESTAMP}${EXTENSION}"
            DESTINATION_PATH="$TARGET_FOLDER/$NEW_NAME"
        fi
        
        # 3. Move the file
        if mv "$FILE" "$DESTINATION_PATH" 2>/dev/null; then
            LOG_MESSAGE="$(date '+%m/%d/%Y %H:%M:%S'): Moved '$FILENAME' to '$TARGET_FOLDER'"
        else
            LOG_MESSAGE="$(date '+%m/%d/%Y %H:%M:%S'): ERROR moving '$FILENAME' - Failed to move"
        fi
        
        echo "$LOG_MESSAGE" >> "$LOG_FILE"
    fi
done

# Log completion
echo "$(date '+%m/%d/%Y %H:%M:%S'): Organize-Downloads task completed." >> "$LOG_FILE"
