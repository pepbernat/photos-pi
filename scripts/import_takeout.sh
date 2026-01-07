#!/bin/bash
# Script to import Google Takeout archives into Immich using local CLI
# Usage: ./import_takeout.sh /path/to/takeout_directory

INPUT_PATH=$1
TEMP_BASE="/mnt/data/immich/import_temp"
DEFAULT_URL="http://127.0.0.1:2283/api"

# 1. Validation
if [ -z "$INPUT_PATH" ]; then
    echo "Usage: $0 <path_to_directory_or_file>"
    exit 1
fi

if [ -z "$IMMICH_API_KEY" ]; then
    echo "⚠️  IMMICH_API_KEY is not set."
    echo "Please create an API Key in Immich (Administration > Users > Click User > API Keys)"
    read -sp "Enter your Immich API Key: " IMMICH_API_KEY
    echo ""
    export IMMICH_API_KEY
fi

# Set Instance URL if not provided
export IMMICH_INSTANCE_URL="${IMMICH_INSTANCE_URL:-$DEFAULT_URL}"

# 2. Main Processing Function
process_file() {
    local ARCHIVE=$1
    local BASENAME=$(basename "$ARCHIVE")
    local EXTRACT_DIR="${TEMP_BASE}/takeout_${BASENAME}_$(date +%s)"

    echo "========================================================"
    echo "🚀 Processing $ARCHIVE..."
    echo "========================================================"

    # 3. Preparation
    echo "📂 Creating temp directory: $EXTRACT_DIR"
    sudo mkdir -p "$EXTRACT_DIR"
    sudo chown 1000:1000 "$EXTRACT_DIR"

    # 4. Extraction
    echo "📦 Extracting archive..."
    if [[ "$ARCHIVE" == *.zip ]]; then
        # Check permissions issues by extracting as current user if possible, or root then chown
        sudo unzip -q "$ARCHIVE" -d "$EXTRACT_DIR"
    elif [[ "$ARCHIVE" == *.tgz ]] || [[ "$ARCHIVE" == *.tar.gz ]]; then
        sudo tar -xzf "$ARCHIVE" -C "$EXTRACT_DIR"
    else
        echo "⚠️  Skipping unsupported file type: $ARCHIVE"
        sudo rm -rf "$EXTRACT_DIR"
        return
    fi
    
    # ensure permissions 
    sudo chown -R 1000:1000 "$EXTRACT_DIR"

    # 5. Upload via Immich CLI
    echo "☁️  Uploading to Immich ($IMMICH_INSTANCE_URL)..."
    
    # Run local immich command
    immich upload --recursive "$EXTRACT_DIR"

    # 6. Cleanup
    echo "🧹 Cleaning up temp directory..."
    sudo rm -rf "$EXTRACT_DIR"

    echo "✅ Finished processing $ARCHIVE"
}

# 7. Execution Loop
if [ -d "$INPUT_PATH" ]; then
    echo "📂 Directory detected. Searching for archives in $INPUT_PATH..."
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
