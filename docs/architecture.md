# 📸 PhotoPrism on Raspberry Pi with Azure Blob Storage and Cloudflare Tunnel

[🔙 Back to README](../README.md)

---

## 1. Project Goal

The goal of this project is to **replace Google Photos** with a solution that is:

- ✅ **Open-source**
- ✅ Self-hosted
- ✅ Running on a **Raspberry Pi**
- ✅ Capable of handling **terabytes of photos/videos** without large local disks
- ✅ Accessible from the Internet **without a static IP or opening ports**
- ✅ With original storage and backups in **Azure Blob Storage**
- ✅ Robust database (**MariaDB**) and **AI** optimization

The chosen solution is **PhotoPrism**, deployed via **Docker**, using:

- **Local USB SSD** → Base system, database (performance), and cache
- **Azure Blob Storage** → Original photos/videos and database backups
- **Cloudflare Tunnel** → Secure remote access via subdomain

---

## 2. Requirements and Constraints

### 2.1 Functional Requirements

- Import the entire current **Google Photos** library
- Maintain **metadata (dates, location)** as much as possible
- Browse, search, and view photos/videos from the web
- Scale to multiple TBs without resizing local hardware
- Face detection and image classification (AI) enabled

### 2.2 Non-Functional Requirements

- Do not depend on a static public IP
- Do not open ports on the router
- Minimize points of failure (especially the SD card)
- Maintain an understandable and maintainable architecture

### 2.3 Technical Constraints

- PhotoPrism **requires local storage** for:
  - Thumbnails
  - Cache
  - High-performance database

➡️ **It is not possible** to run PhotoPrism without any reliable local disk.

---

## 3. Final Architecture

```text
Internet
  │
  ▼
Cloudflare (HTTPS, DNS, Zero Trust)
  │
  ▼
Cloudflare Tunnel (outbound)
  │
  ▼
Raspberry Pi
├── USB SSD (EXT4) /mnt/ssd
│   ├── /photoprism/storage   (thumbnails, cache)
│   ├── /photoprism/database  (MariaDB data files)
│   └── /photoprism/import    (staging)
│
└── Azure Blob Storage (mounted with rclone) /mnt/azurephotos
    ├── /originals            (photos and videos, TBs)
    └── /backup               (daily MariaDB dumps)
```

---

## 4. Key Technical Decisions

### 4.1 Why USB SSD and not SD Card

- PhotoPrism performs **many small, constant writes**.
- SD cards degrade and offer low IOPS.
- Necessary for MariaDB.

➡️ The USB SSD is **mandatory** for a stable system.

### 4.2 Why Azure Blob Storage

- Virtually unlimited scale.
- Predictable cost.
- High durability.
- Integrable via **rclone** as a filesystem.

➡️ Allows having **TBs of photos** and **Centralized Backups** with only **tens of local GBs**.

### 4.3 Why rclone mount

- Natively supports Azure Blob.
- Stable and widely used.
- Allows PhotoPrism to work as if it were a local disk.

### 4.4 Why MariaDB (and not SQLite)

- **Superior performance** for large libraries (thousands of photos).
- Better concurrency management (avoids database locks).
- Greater robustness against data corruption.
- Standard in production deployments.

### 4.5 Why Cloudflare Tunnel

- Does not require a static IP.
- Does not require NAT or open ports.
- Automatic TLS.
- Very suitable for homelabs.

---

## 5. System Preparation

### 5.1 Hardware Requirements

- Raspberry Pi 4 or 5 (min 4 GB RAM recommended, ideal 8GB for AI).
- USB 3.0 SSD (recommended: **128 GB or larger**).
- Stable Internet connectivity.

### 5.2 Operating System

- Raspberry Pi OS **64-bit**.
- Docker + Docker Compose.

---

## 6. Local Storage Preparation (SSD)

```bash
sudo mkfs.ext4 /dev/sda1
sudo mkdir -p /mnt/ssd
sudo mount /dev/sda1 /mnt/ssd
```

Structure used:

```text
/mnt/ssd/photoprism/
├── storage
├── database
└── import
```

---

## 7. Azure Blob Storage

### 7.1 Creation

- Create Azure Storage account.
- Create a **Blob Container** (e.g., `photos`).

### 7.2 Rclone Configuration

```bash
rclone config
```

Create a remote, for example: `azureblob`.

### 7.3 Mounting the Container

```bash
sudo mkdir -p /mnt/azurephotos

rclone mount azureblob:photos /mnt/azurephotos \
  --vfs-cache-mode writes \
  --allow-other \
  --dir-cache-time 72h
```

Create folders inside the mount if they don't exist:

```bash
mkdir -p /mnt/azurephotos/originals
mkdir -p /mnt/azurephotos/backup
```

---

## 8. Deployment with Docker Compose

Updated configuration including MariaDB and optimized AI settings. See `docker-compose.yml` in the root directory.

```bash
docker compose up -d
```

---

## 9. Automatic Backup Strategy

To meet the requirement that **all critical storage is on Azure**, we implement an automatic backup of the MariaDB database to the Azure container.

Script location: `/home/pi/backup_db.sh` (or `./scripts/backup_db.sh` in this repo).

Add to cron (`crontab -e`) to run every night at 3 AM:

```cron
0 3 * * * /bin/bash /home/pi/backup_db.sh
```

With this, both **originals** and the **database** reside in Azure Blob Storage. If the Raspberry Pi or SSD dies, no data is lost, only the generated cache.

---

## 10. Migration from Google Photos

### 10.1 Export

- Use **Google Takeout**.
- Export only *Google Photos*.

### 10.2 Extraction

```bash
unzip '*.zip' -d /mnt/ssd/photoprism/import
```

### 10.3 Import and Classification

Since AI and MariaDB are enabled, the import process will analyze faces and objects.

```bash
# Move files from import to originals in Azure and index
docker compose exec photoprism photoprism import
```

This will process the photos on the SSD and move them to `/photoprism/originals` (which points to Azure), creating thumbnails on the SSD.

---

## 11. Remote Access with Cloudflare Tunnel

*(See section 8 for docker compose)*

---

## 12. Risks and Mitigations

| Risk | Mitigation |
| :--- | :--- |
| SD Corruption | Mandatory USB SSD |
| Azure Latency | VFS Cache + Local Thumbnails |
| Local DB Loss | **MariaDB + Daily Auto-Backup to Azure** |
| Pi Hardware Failure | Replace Pi, reinstall Docker, and restore backup from Azure |

---

## 13. Future Evolutions

- Replication from Azure to another provider (Additional Geo-redundant Backup).

---

## 14. Conclusion

This **Plug & Play** architecture allows you to:

- Replace Google Photos with a rich user experience (AI, Maps).
- Scale to multiple TB thanks to Azure Blob Storage.
- Sleep soundly knowing that **all persistent data** (Photos + DB) is safe in the cloud.
- Maintain local access speed thanks to the SSD and MariaDB.

It is a robust, scalable, and private system.
