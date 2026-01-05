# 📸 PhotoPrism on Raspberry Pi (Cloudflare + Azure Blob)

Welcome! This repository contains a **Plug & Play** configuration to run a powerful, self-hosted photo management system on your Raspberry Pi.

It replaces Google Photos with **PhotoPrism**, using **Azure Blob Storage** for unlimited storage and **Cloudflare Tunnel** for secure remote access.

## 🌟 Features

* **Self-Hosted:** Runs on your Raspberry Pi 4/5.
* **Unlimited Storage:** Uses Azure Blob Storage (cheap & reliable) for originals and backups.
* **Performance:** Uses a local SSD for the database (MariaDB) and thumbnails.
* **Secure:** Accessible via `https://photos.yourdomain.com` without opening router ports.
* **Smart:** AI-powered facial recognition and object detection.

## 🛠 Prerequisites

1. **Raspberry Pi 4 or 5** (4GB RAM min, 8GB recommended).
2. **USB SSD Drive** (128GB+ recommended) formatted as EXT4 and mounted (e.g., at `/mnt/ssd`).
3. **Azure Account:** A Storage Account with a Blob Container (e.g., named `photos`).
4. **Cloudflare Account:** A domain managed by Cloudflare + Zero Trust setup.

## 🚀 Quick Start Guide

### Step 1: Clone the Repository

Log in to your Raspberry Pi and clone this repo:

```bash
git clone https://github.com/pepbernat/Photos-Pi.git
cd Photos-Pi
```

### Step 2: Prepare the System

Run the system setup script to install Docker, Rclone, and create directories.

```bash
./scripts/setup_system.sh
```

### Step 3: Configure Environment

Copy the example config and edit it with your secrets.

```bash
cp .env.example .env
nano .env
```

*Fill in your database passwords, Azure paths (defaults are likely fine).*

👉 **Need the Cloudflare Token?** Read the [Cloudflare Setup Guide](cloudflare_setup_guide.md).

### Step 4: Setup Azure Storage

Run the guided script to connect your Azure account.

```bash
./scripts/setup_rclone.sh
```

*Follow the prompts (choose 'azureblob', enter account name & key). The script will automatically create a system service to keep it mounted.*

### Step 5: Launch! 🚀

Start the system with Docker Compose.

```bash
docker compose up -d
```

Wait a few minutes (initial database creation takes time).

* **URL:** `https://photos.yourdomain.com` (or `http://<PI_IP>:2342` locally)
* **User:** `admin`
* **Password:** (The one you set in `.env`)

---

## 📱 Mobile Experience (App)

PhotoPrism is a **Progressive Web App (PWA)**. It works like a native app without needing an app store.

1. Open your Cloudflare URL (e.g., `https://photos.yourdomain.com`) in Chrome/Safari on your phone.
2. Tap **Share** (iOS) or **Menu** (Android).
3. Select **"Add to Home Screen"**.
4. It will now launch as a full-screen app and sync your photos.

## 💸 Cost Warning (Azure)

While the code is free, **Azure Blob Storage is not**.

* Expect to pay ~$0.18 - $0.20 per GB/year (Cool Tier) or check [Azure Pricing](https://azure.microsoft.com/en-us/pricing/details/storage/blobs/).
* Example: 1 TB of photos ≈ $15-$20 / month depending on tier and access frequency. Check your budget!

---

## 📥 Importing Photos (Google Takeout)

1. Download your photos from **Google Takeout**.
2. Unzip them (or keep them as zips, but extraction is recommended first).
3. Place the files into the **Local Import Folder**:
    * `/mnt/ssd/photoprism/import`
4. Run the import command:

```bash
docker compose exec photoprism photoprism import
```

*This will move photos from the local import folder to Azure Blob Storage (`/originals`) and index them.*

## 🛡 Backups

The system includes a script to backup the database to Azure (so **everything** is in the cloud).

**Test backup manually:**

```bash
./scripts/backup_db.sh
```

**Setup automatic daily backup:**
Add this to your crontab (`crontab -e`):

```cron
0 3 * * * /home/pi/Photos-Pi/scripts/backup_db.sh >> /var/log/photoprism_backup.log 2>&1
```

## 📂 Architecture

For a deep dive into the design decisions, read the [Architecture Documentation](photo_prism_en_raspberry_pi_con_azure_blob_y_cloudflare_tunnel.md).
