#!/bin/bash
# Script to import Google Takeout archives into Immich using the CLI
# Usage: ./import_takeout.sh /path/to/takeout_directory

INPUT_PATH=$1
TEMP_BASE="/mnt/data/immich/import_temp"
IMMICH_CLI_IMAGE="ghcr.io/immich-app/immich-cli:latest"
NETWORK="photos-pi_default"
DEFAULT_URL="http://immich_server:3001/api"

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
fi

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
    
    # ensure permissions for docker mount
    sudo chown -R 1000:1000 "$EXTRACT_DIR"

    # 5. Upload via Immich CLI
    echo "☁️  Uploading to Immich..."
    
    # We run the CLI container attached to the same network as Immich to use specific container names
    docker run --rm \
        --network "$NETWORK" \
        -v "$EXTRACT_DIR:/import:ro" \
        -e IMMICH_INSTANCE_URL="$DEFAULT_URL" \
        -e IMMICH_API_KEY="$IMMICH_API_KEY" \
        "$IMMICH_CLI_IMAGE" \
        upload --recursive /import

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
