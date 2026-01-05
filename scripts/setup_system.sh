#!/bin/bash
set -e

# Load environment variables if .env exists
if [ -f .env ]; then
  export $(cat .env | xargs)
else
  echo "⚠️  No .env file found. Please copy .env.example to .env and configure it first."
  exit 1
fi

echo "🚀 Starting System Setup for PhotoPrism on Pi..."

# 1. Update System
echo "📦 Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# 2. Install Dependencies
echo "🛠  Installing dependencies (git, unzip, rclone)..."
sudo apt-get install -y git unzip rclone

# 3. Install Docker (add user to group)
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installed. You might need to log out and log back in for group changes to take effect."
else
    echo "✅ Docker already installed."
fi

# 4. Create Directory Structure
echo "📂 Creating directory structure..."

# Verify SSD Mount
if ! mountpoint -q "$SSD_MOUNT_PATH"; then
    echo "⚠️  WARNING: '$SSD_MOUNT_PATH' does not seem to be a mountpoint."
    echo "   Ensure your SSD is mounted correctly via /etc/fstab"
    read -p "   Press [Enter] to continue anyway or Ctrl+C to abort..."
fi

sudo mkdir -p "${SSD_MOUNT_PATH}/photoprism/storage"
sudo mkdir -p "${SSD_MOUNT_PATH}/photoprism/database"
sudo mkdir -p "${SSD_MOUNT_PATH}/photoprism/import"

# Verify Azure Mount Config
sudo mkdir -p "${AZURE_MOUNT_PATH}"
sudo chown -R $USER:$USER "${AZURE_MOUNT_PATH}"

# Set permissions for Docker volumes
# PhotoPrism usually runs as internal user/group, simply allowing access
sudo chmod -R 777 "${SSD_MOUNT_PATH}/photoprism"

echo "✅ System setup complete!"
echo "➡️  Next step: Run 'scripts/setup_rclone.sh' to configure Azure Storage."
