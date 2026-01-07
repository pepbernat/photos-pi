#!/bin/bash
# Script to import Google Takeout archives from a directory
# Usage: ./import_takeout.sh /path/to/takeout_directory

INPUT_PATH=$1

if [ -z "$INPUT_PATH" ]; then
    echo "Usage: $0 <path_to_directory_or_file>"
    exit 1
fi

process_file() {
    local ARCHIVE=$1
    echo "========================================================"
    echo "🚀 Processing $ARCHIVE..."
    echo "========================================================"

    # 1. Prepare Extraction Directory
    # We use a unique name based on the filename to avoid collisions
    BASENAME=$(basename "$ARCHIVE")
    EXTRACT_DIR="/mnt/data/photoprism/import/takeout_${BASENAME}_$(date +%s)"
    mkdir -p "$EXTRACT_DIR"

    # 2. Extract based on extension
    echo "📦 Extracting to $EXTRACT_DIR..."
    
    if [[ "$ARCHIVE" == *.zip ]]; then
        unzip -q "$ARCHIVE" -d "$EXTRACT_DIR"
    elif [[ "$ARCHIVE" == *.tgz ]] || [[ "$ARCHIVE" == *.tar.gz ]]; then
        tar -xzf "$ARCHIVE" -C "$EXTRACT_DIR"
    else
        echo "⚠️  Skipping unsupported file type: $ARCHIVE"
        rm -rf "$EXTRACT_DIR"
        return
    fi

    # 3. Fix Permissions
    echo "🔧 Fixing permissions..."
    sudo chown -R 1000:1000 "$EXTRACT_DIR"

    # 4. Trigger PhotoPrism Import via Docker
    CONTAINER_IMPORT_PATH="/photoprism/import/$(basename "$EXTRACT_DIR")"

    echo "📸 Starting PhotoPrism Import..."
    cd ~/Photos-Pi
    # We use 'photoprism import' which moves files. 
    # If you wanted to copy, you'd use 'photoprism index' but import is better for Takeout cleanup.
    docker compose exec photoprism photoprism import "$CONTAINER_IMPORT_PATH"

    # 5. Cleanup Extracted Files
    echo "🧹 Cleaning up extracted temp folder..."
    sudo rm -rf "$EXTRACT_DIR"

    echo "✅ Finished processing $ARCHIVE"
}

# Main Logic
if [ -d "$INPUT_PATH" ]; then
    echo "📂 Directory detected. Searching for archives in $INPUT_PATH..."
    # Find zip, tgz, tar.gz
    find "$INPUT_PATH" -maxdepth 1 -type f \( -name "*.zip" -o -name "*.tgz" -o -name "*.tar.gz" \) | while read -r file; do
        process_file "$file"
    done
elif [ -f "$INPUT_PATH" ]; then
    process_file "$INPUT_PATH"
else
    echo "❌ Error: $INPUT_PATH is not a valid file or directory."
    exit 1
fi

echo "🎉 All Done!"
