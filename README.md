# 📸 PhotoPrism en Raspberry Pi (Ultimate Edition)

![PhotoPrism + Raspberry Pi](https://img.shields.io/badge/PhotoPrism-Raspberry%20Pi-blue?style=for-the-badge&logo=raspberrypi)
![Azure Blob Storage](https://img.shields.io/badge/Storage-Azure%20Blob-0078D4?style=for-the-badge&logo=microsoftazure)
![Cloudflare Tunnel](https://img.shields.io/badge/Access-Cloudflare%20Zero%20Trust-F38020?style=for-the-badge&logo=cloudflare)

¡Bienvenido! Este repositorio contiene una configuración **"Plug & Play"** para desplegar tu propio **Google Photos privado** en una Raspberry Pi.

Olvídate de pagar suscripciones mensuales por almacenamiento limitado. Aquí tú controlas tus datos, con almacenamiento ilimitado en la nube (Azure) y privacidad total.

---

## ✨ ¿Qué ofrece este proyecto?

1. **Reemplazo de Google Photos:** Interfaz web preciosa, mapas, detección de caras y búsqueda por IA.
2. **Almacenamiento Infinito:** Usa Azure Blob Storage (barato y seguro) para guardar los originales. No llenas el disco de tu Pi.
3. **Acceso Remoto Seguro:** Sin abrir puertos en el router. Tu web será accesible desde cualquier lugar (`https://fotos.tumismo.com`) gracias a Cloudflare.
4. **Resiliente:** Base de datos en SSD (rápido) + Copias de seguridad automáticas en la nube. ¡A prueba de desastres!

---

## 🛠️ Requisitos de Hardware

* **Raspberry Pi 4 o 5** (Min 4GB RAM, Ideal 8GB).
* **Disco SSD USB** (Min 128GB). *No uses tarjeta SD para los datos, se romperá.*
* Una cuenta de **Azure** y un dominio en **Cloudflare**.

---

## 🚀 Guía de Instalación Rápida

Sigue estos 5 pasos y lo tendrás funcionando en 15 minutos.

### Paso 1: Clonar el proyecto

Conéctate por SSH a tu Raspberry Pi y descarga este código:

```bash
git clone https://github.com/pepbernat/Photos-Pi.git
cd Photos-Pi
```

### Paso 2: Preparar el Sistema

Ejecuta el script automático que instala Docker, Rclone y ajusta los permisos:

```bash
./scripts/setup_system.sh
```

### Paso 3: Configuración Secreta

Copia la plantilla y pon tus contraseñas:

```bash
cp .env.example .env
nano .env
```

> 💡 **¿Necesitas el Token de Cloudflare?** Sigue esta [Guía Paso a Paso](cloudflare_setup_guide.md).

### Paso 4: Conectar la Nube (Azure)

Ejecuta el asistente para conectar tu almacenamiento:

```bash
./scripts/setup_rclone.sh
```

### Paso 5: ¡Despegue

Arranca los motores:

```bash
docker compose up -d
```

Espera unos minutos a que inicie.

* **Web:** `http://<IP-DE-TU-PI>:2342` o tu dominio `https://fotos.tumismo.com`
* **Usuario:** `admin`
* **Password:** La que pusiste en el `.env`.

---

## 📱 Experiencia Móvil (Apps)

Para disfrutarlo en el móvil como una app nativa, tienes dos opciones:

### Opción A: Apps Nativas (Comunidad)

Existen excelentes apps creadas por la comunidad:

* **Android:** [Gallery for PhotoPrism](https://play.google.com/store/apps/details?id=com.photoprism.gallery) (Recomendada).
* **iOS:** [PhotoSync](https://www.photosync-app.com/) (Para subir fotos) o usar la PWA.

### Opción B: App Web (PWA Oficial)

La interfaz oficial está diseñada para funcionar como una app:

1. Abre tu web (`https://fotos.tumismo.com`) en Chrome/Safari.
2. Pulsar **Compartir** (iOS) o **Menú** (Android) -> **"Añadir a Pantalla de Inicio"**.
3. ¡Listo! Funciona a pantalla completa.

---

## 📖 Cómo usarlo

### 📥 Importar tus fotos de Google

1. Descarga tus fotos desde [Google Takeout](https://takeout.google.com/).
2. Copia los archivos descomprimidos a la carpeta de importación en tu Pi:
    * Ruta: `/mnt/ssd/photoprism/import`
3. Ejecuta el importador:

    ```bash
    docker compose exec photoprism photoprism import
    ```

    *Esto moverá las fotos a Azure, las clasificará por fecha y generará las miniaturas.*

### 🔄 Sincronización Automática desde el Móvil

Para que las fotos que haces con el móvil se suban solas (como en Google Photos), recomendamos usar la app **PhotoSync** (iOS/Android) configurada para subir vía WebDAV a tu servidor PhotoPrism.

---

## 🛡️ Seguridad y Recuperación

### 💾 Backups Automáticos

El sistema hace una copia de seguridad de la base de datos **cada noche a las 3 AM** y la sube a Azure (`/backup`).

* **Originales:** Están en Azure (Seguros).
* **Base de datos:** En Azure (Segura).
* **Raspberry Pi:** Si se quema, ¡no pierdes nada!

### 🆘 ¿Cómo recuperar todo ante un desastre?

Si tu Raspberry Pi explota, sigue estos pasos:

1. Compra una nueva Pi y repite la instalación (Pasos 1-4).
2. Asegúrate que Docker está corriendo (`docker compose up -d`).
3. Ejecuta el script de restauración:

    ```bash
    ./scripts/restore_db.sh
    ```

4. El sistema te mostrará los backups disponibles en la nube y restaurará el que elijas.

---

## 🧠 Arquitectura

¿Eres curioso? Consulta el documento de [Arquitectura Técnica](photo_prism_en_raspberry_pi_con_azure_blob_y_cloudflare_tunnel.md) para entender cómo funciona todo por dentro (MariaDB, Cloudflare Tunnels, sistema de caché VFS).
