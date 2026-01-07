#!/bin/bash
set -e

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | xargs)
else
  echo "⚠️  No .env file found."
  exit 1
fi

REMOTE_NAME="azureblob"
CONTAINER_NAME="photos"

echo "☁️  Setting up Rclone for Azure Blob Storage..."

# 1. Configure Rclone
if rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
    echo "✅ Remote '${REMOTE_NAME}' already exists."
elif [ -n "$AZURE_ACCOUNT_NAME" ] && [ -n "$AZURE_ACCOUNT_KEY" ] && [ "$AZURE_ACCOUNT_NAME" != "CHANGE_ME" ]; then
    echo "⚡️ Configuring '${REMOTE_NAME}' non-interactively..."
    rclone config create "$REMOTE_NAME" azureblob account "${AZURE_ACCOUNT_NAME}" key "${AZURE_ACCOUNT_KEY}"
    echo "✅ Remote '${REMOTE_NAME}' created."
else
    echo "⚡️ Launching rclone config..."
    echo "   👉 Create a new remote named '${REMOTE_NAME}'"
    echo "   👉 Type: 'azureblob'"
    echo "   👉 Follow the prompts with your Account Name and Key."
    rclone config
fi

# 2. Check mount point
if [ ! -d "$AZURE_MOUNT_PATH" ]; then
    echo "📂 Creating mount point: $AZURE_MOUNT_PATH"
    sudo mkdir -p "$AZURE_MOUNT_PATH"
fi

# 3. Create Systemd Service for Persistence
SERVICE_FILE="/etc/systemd/system/rclone-mount.service"

echo "⚙️  Creating systemd service for auto-mount at '$SERVICE_FILE'..."

sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Rclone Mount Azure Blob
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=$USER
ExecStart=/usr/bin/rclone mount ${REMOTE_NAME}:${CONTAINER_NAME} ${AZURE_MOUNT_PATH} \\
   --allow-other \\
   --vfs-cache-mode writes \\
   --dir-cache-time 72h \\
   --log-level INFO \\
   --log-file /var/log/rclone-mount.log
ExecStop=/bin/fusermount -u ${AZURE_MOUNT_PATH}
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL

# 4. Enable and Start Service
echo "🚀 Enabling and starting rclone-mount service..."
sudo systemctl daemon-reload
sudo systemctl enable rclone-mount.service
sudo systemctl start rclone-mount.service

# 5. Verify
sleep 3
if mountpoint -q "$AZURE_MOUNT_PATH"; then
    echo "✅ Azure container mounted successfully at $AZURE_MOUNT_PATH"
    
    # Ensure backup and originals dirs exist
    mkdir -p "$AZURE_MOUNT_PATH/originals"
    mkdir -p "$AZURE_MOUNT_PATH/backup"
    echo "✅ Directory structure created in Azure."
else
    echo "❌ Mount failed. Check 'sudo systemctl status rclone-mount.service' or '/var/log/rclone-mount.log'"
fi
