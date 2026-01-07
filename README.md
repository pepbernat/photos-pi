# 📸 Immich on Raspberry Pi (Ultimate Edition)

![Immich + Raspberry Pi](https://img.shields.io/badge/Immich-Raspberry%20Pi-blue?style=for-the-badge&logo=raspberrypi)
![Azure Blob Storage](https://img.shields.io/badge/Storage-Azure%20Blob-0078D4?style=for-the-badge&logo=microsoftazure)
![Cloudflare Tunnel](https://img.shields.io/badge/Access-Cloudflare%20Zero%20Trust-F38020?style=for-the-badge&logo=cloudflare)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

Welcome! This repository provides a **"Plug & Play"** setup to deploy your own **private Google Photos** on a Raspberry Pi, combining the power of **Immich** with the scalability of the cloud.

🇪🇸 **Leer esto en Español: [README.es.md](README.es.md)**

---

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage & Mobile Apps](#usage--mobile-apps)
- [Backups](#backups)
- [Contributing](#contributing)
- [License](#license)

---

## Features

1. **Real Alternative to Google Photos:** Modern web interface, maps, facial recognition, and smart AI search.
2. **Unlimited & Hybrid Storage:**
    - **Azure Blob Storage:** Stores originals (TBs of photos at low cost).
    - **Local SSD:** Stores the database and cache, ensuring maximum speed.
3. **Secure Remote Access:** No need to open router ports. Your site will be accessible from anywhere (`https://photos.yourdomain.com`) thanks to Cloudflare Tunnel.
4. **Resilience:** Robust database (PostgreSQL) and automatic cloud backups.
5. **Total Privacy:** You control your data.

## Architecture

The system uses a smart hybrid architecture to balance cost and performance.
To understand how it works under the hood (Postgres, Redis, Rclone cache), check the **Technical Architecture** (currently in Spanish: [docs/architecture.es.md](docs/architecture.es.md)).

## Requirements

- **Hardware:** Raspberry Pi 4 or 5 (Min 4GB RAM, Ideal 8GB).
- **Local Storage:** USB SSD Drive (Min 128GB). *Do not use an SD card for data.*
- **Cloud:** An Azure account (Blob Storage) and a domain on Cloudflare.

## Installation

Follow these steps to get it running in 15 minutes.

### 1. Clone the repository

SSH into your Raspberry Pi and download the code:

```bash
git clone https://github.com/pepbernat/Photos-Pi.git
cd Photos-Pi
```

### 2. Prepare the System

Run the automatic script to install Docker, Rclone, and adjust permissions:

```bash
./scripts/setup_system.sh
```

## Configuration

Copy the configuration template:

```bash
cp .env.example .env
nano .env
```

Edit the `.env` file with your passwords and tokens.
> 💡 **Need the Cloudflare Token?** Follow this **[Step-by-Step Guide](docs/setup-cloudflare.md)**.

### 4. Connect Azure

Run the assistant to configure `rclone` and connect your storage:

```bash
./scripts/setup_rclone.sh
```

### 5. Deploy

Start the services with Docker Compose:

```bash
docker compose up -d
```

Wait a few minutes for it to start. You can access it at `https://photos.yourdomain.com` or `http://<YOUR-PI-IP>:2283`.

Create your admin account on the first login.

## Usage & Mobile Apps

Download the native Immich app:

- **Android:** [Google Play](https://play.google.com/store/apps/details?id=app.immich)
- **iOS:** [App Store](https://apps.apple.com/app/immich/id1677386979)

Enter your server URL (`https://photos.yourdomain.com`) and login.

## Backups

The system includes scripts to ensure you don't lose anything.

- **Originals:** Stored directly in Azure.
- **Database:** A backup is automatically performed every night at 3 AM and uploaded to Azure (`/backup`).

### Disaster Recovery

If your Raspberry Pi fails, you can restore everything on a new installation by running:

```bash
./scripts/restore_db.sh <backup_file>
```

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) to get started.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
