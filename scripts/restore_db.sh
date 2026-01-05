#!/bin/bash
set -e

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | xargs)
else
  echo "⚠️  No .env file found."
  exit 1
fi

BACKUP_DIR="${AZURE_MOUNT_PATH}/backup"

echo "🆘 STARTING DISASTER RECOVERY RESTORE..."
echo "⚠️  WARNING: This will OVERWRITE the current database with the backup."
echo "⚠️  Make sure PhotoPrism is stopped or idle."
echo ""
echo "Available backups in Azure:"
ls -lh "$BACKUP_DIR"/*.sql.gz | awk '{print $9 " (" $5 ")"}'
echo ""

read -p "Paste the full path of the backup file to restore: " BACKUP_FILE

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ File not found."
    exit 1
fi

echo "⏳ Restoring from $BACKUP_FILE..."

# Unzip and pipe directly to mariadb client inside container
zcat "$BACKUP_FILE" | docker exec -i mariadb mariadb -u "$PHOTOPRISM_DATABASE_USER" -p"$PHOTOPRISM_DATABASE_PASSWORD" "$PHOTOPRISM_DATABASE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ RESTORE COMPLETE! Your database is back."
    echo "🔄 It is recommended to restart the container: docker compose restart photoprism"
else
    echo "❌ Restore failed."
fi
