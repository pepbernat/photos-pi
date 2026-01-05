#!/bin/bash

# Find the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
  export $(cat "$PROJECT_ROOT/.env" | xargs)
else
  echo "⚠️  No .env file found at $PROJECT_ROOT/.env"
  exit 1
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${AZURE_MOUNT_PATH}/backup"
KEEP_DAYS=7

echo "💾 Starting DB Backup to Azure..."

# Verify Azure Mount
if mountpoint -q "$AZURE_MOUNT_PATH"; then
    FILENAME="db_backup_$TIMESTAMP.sql"
    FILEPATH="$BACKUP_DIR/$FILENAME"
    
    # Execute Dump inside Docker Container
    # Note: We use the container name 'mariadb' defined in docker-compose, assuming it's running
    if docker ps | grep -q mariadb; then
        docker exec mariadb mariadb-dump \
            -u "$PHOTOPRISM_DATABASE_USER" \
            -p"$PHOTOPRISM_DATABASE_PASSWORD" \
            "$PHOTOPRISM_DATABASE_NAME" > "$FILEPATH"
        
        if [ $? -eq 0 ]; then
            echo "✅ Backup created: $FILENAME"
            
            # Compress
            gzip "$FILEPATH"
            echo "📦 Compressed: $FILENAME.gz"
            
            # Cleanup old backups
            find "$BACKUP_DIR" -name "db_backup_*.sql.gz" -mtime +$KEEP_DAYS -delete
            echo "🧹 Old backups cleaned."
        else
            echo "❌ Error dumping database."
        fi
    else
        echo "❌ MariaDB container is not running."
    fi
else
    echo "❌ Error: Azure mountpoint not found at $AZURE_MOUNT_PATH"
fi
