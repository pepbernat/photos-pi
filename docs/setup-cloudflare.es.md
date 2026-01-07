# ☁️ Guía de Configuración: Cloudflare Tunnel

[🔙 Volver al README](../README.es.md)

---

Para que tu Immich sea accesible desde internet de forma segura (<https://fotos.tudominio.com>) sin abrir puertos en tu router, usamos **Cloudflare Tunnel**.

Sigue estos pasos para obtener tu **Token** necesario para el archivo `.env`.

## 1. Requisitos Previos

* Tener un dominio propio (ej: `mifamilia.com`).
* Tener una cuenta gratuita en [Cloudflare](https://www.cloudflare.com/).
* Haber cambiado los nameservers de tu dominio para que apunten a Cloudflare.

## 2. Crear el Túnel en Zero Trust

1. Ve al **[Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)**.
2. En el menú lateral, ve a **Networks** > **Tunnels**.
3. Haz clic en **Create a tunnel**.
4. Selecciona **Cloudflared** (connector).
5. Dale un nombre, ej: `raspberry-pi-photos`.

## 3. Obtener el Token

1. En la pantalla "Install and run a connector", verás varios comandos.
2. Busca el bloque que pone "If you already have cloudflared installed...".
3. Verás un comando largo que se parece a esto:

    ```bash
    sudo cloudflared service install eyJhIjoiM...
    ```

4. La cadena larga de letras y números que empieza por `ey...` es tu **TOKEN**.
5. Copíalo y pégalo en tu archivo `.env`:

    ```bash
    CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoiM...
    ```

## 4. Configurar el Enrutamiento (Public Hostname)

1. Dale a **Next** en la web de Cloudflare.
2. En la pestaña **Public Hostnames**, añade uno nuevo:
    * **Subdomain**: `fotos` (o lo que quieras).
    * **Domain**: `tudominio.com`.
    * **Service**: `HTTP`.
    * **URL**: `immich_server:3001`
        * *Nota: Ponemos "immich_server" porque es el nombre del contenedor en nuestra red Docker.*
3. Guarda los cambios (`Save Tunnel`).

## 5. ¡Listo

Una vez arranques el sistema con `docker compose up -d`, el contenedor `cloudflared` usará ese token para conectarse. En unos segundos, verás que el estado en el panel de Cloudflare pasa a **HEALTHY** y podrás entrar a tu web.
