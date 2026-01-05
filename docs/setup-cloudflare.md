# ☁️ Setup Guide: Cloudflare Tunnel

[🔙 Back to README](../README.md)

---

To make your PhotoPrism accessible from the internet securely (<https://photos.yourdomain.com>) without opening ports on your router, we use **Cloudflare Tunnel**.

Follow these steps to obtain your **Token**, which is needed for the `.env` file.

## 1. Prerequisites

* Have your own domain (e.g., `familyname.com`).
* Have a free account on [Cloudflare](https://www.cloudflare.com/).
* Have changed your domain's nameservers to point to Cloudflare.

## 2. Create the Tunnel in Zero Trust

1. Go to the **[Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)**.
2. In the sidebar, go to **Networks** > **Tunnels**.
3. Click on **Create a tunnel**.
4. Select **Cloudflared** (connector).
5. Name it, e.g., `raspberry-pi-photos`.

## 3. Get the Token

1. On the "Install and run a connector" screen, you will see several commands.
2. Look for the block that says "If you already have cloudflared installed...".
3. You will see a long command that looks like this:

    ```bash
    sudo cloudflared service install eyJhIjoiM...
    ```

4. The long string of letters and numbers starting with `ey...` is your **TOKEN**.
5. Copy it and paste it into your `.env` file:

    ```bash
    CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoiM...
    ```

## 4. Configure Routing (Public Hostname)

1. Click **Next** on the Cloudflare website.
2. In the **Public Hostnames** tab, add a new one:
    * **Subdomain**: `photos` (or whatever you prefer).
    * **Domain**: `yourdomain.com`.
    * **Service**: `HTTP`.
    * **URL**: `photoprism:2342`
        * *Note: We put "photoprism" because it is the container name in our Docker network.*
3. Save the changes (**Save Tunnel**).

## 5. Ready

Once you start the system with `docker compose up -d`, the `cloudflared` container will use that token to connect. In a few seconds, you will see the status in the Cloudflare dashboard turn to **HEALTHY**, and you will be able to access your site.
