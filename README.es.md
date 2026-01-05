# 📸 PhotoPrism en Raspberry Pi (Ultimate Edition)

![PhotoPrism + Raspberry Pi](https://img.shields.io/badge/PhotoPrism-Raspberry%20Pi-blue?style=for-the-badge&logo=raspberrypi)
![Azure Blob Storage](https://img.shields.io/badge/Storage-Azure%20Blob-0078D4?style=for-the-badge&logo=microsoftazure)
![Cloudflare Tunnel](https://img.shields.io/badge/Access-Cloudflare%20Zero%20Trust-F38020?style=for-the-badge&logo=cloudflare)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

¡Bienvenido! Este repositorio ofrece una configuración **"Plug & Play"** para desplegar tu propio **Google Photos privado** en una Raspberry Pi, combinando la potencia de PhotoPrism con la escalabilidad de la nube.

🌍 **Read this in English: [README.md](README.md)**

---

## 📑 Tabla de Contenidos

- [Características](#características)
- [Arquitectura](#arquitectura)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Uso y Apps Móviles](#uso-y-apps-móviles)
- [Copias de Seguridad](#copias-de-seguridad)
- [Contribuir](#contribuir)
- [Licencia](#licencia)

---

## Características

1. **Alternativa Real a Google Photos:** Interfaz web moderna, mapas, reconocimiento facial y búsqueda inteligente por IA.
2. **Almacenamiento Ilimitado e Híbrido:**
    - **Azure Blob Storage:** Para guardar los originales (TB de fotos a bajo coste).
    - **SSD Local:** Para la base de datos y caché, garantizando máxima velocidad.
3. **Acceso Remoto Seguro:** Sin abrir puertos en el router. Tu web será accesible desde cualquier lugar (`https://fotos.tudominio.com`) gracias a Cloudflare Tunnel.
4. **Resiliencia:** Base de datos robusta (MariaDB) y copias de seguridad automáticas en la nube.
5. **Privacidad Total:** Tú controlas tus datos.

## Arquitectura

El sistema utiliza una arquitectura híbrida inteligente para equilibrar coste y rendimiento.
Para entender cómo funciona todo por dentro (MariaDB, Cloudflare Tunnels, sistema de caché VFS), consulta el documento de **[Arquitectura Técnica](docs/architecture.es.md)**.

## Requisitos

- **Hardware:** Raspberry Pi 4 o 5 (Min 4GB RAM, Ideal 8GB).
- **Almacenamiento Local:** Disco SSD USB (Min 128GB). *No uses tarjeta SD para los datos.*
- **Nube:** Una cuenta de Azure (Blob Storage) y un dominio en Cloudflare.

## Instalación

Sigue estos pasos para tenerlo funcionando en 15 minutos.

### 1. Clonar el repositorio

Conéctate por SSH a tu Raspberry Pi y descarga este código:

```bash
git clone https://github.com/pepbernat/Photos-Pi.git
cd Photos-Pi
```

### 2. Preparar el Sistema

Ejecuta el script automático que instala Docker, Rclone y ajusta los permisos:

```bash
./scripts/setup_system.sh
```

### 3. Configuración

Copia la plantilla de configuración:

```bash
cp .env.example .env
nano .env
```

Edita el archivo `.env` con tus contraseñas y tokens.
> 💡 **¿Necesitas el Token de Cloudflare?** Sigue esta **[Guía Paso a Paso](docs/setup-cloudflare.es.md)**.

### 4. Conectar Azure

Ejecuta el asistente para configurar `rclone` y conectar tu almacenamiento:

```bash
./scripts/setup_rclone.sh
```

### 5. Desplegar

Arranca los servicios con Docker Compose:

```bash
docker compose up -d
```

Espera unos minutos a que inicie. Podrás acceder en `https://fotos.tudominio.com` o `http://<IP-DE-TU-PI>:2342`.

- **Usuario:** `admin`
- **Password:** La que definiste en el archivo `.env`.

## Uso y Apps Móviles

### PWA Oficial (Recomendado)

La interfaz web es una PWA (Progressive Web App). Abre tu sitio en Chrome/Safari y pulsa **"Añadir a Pantalla de Inicio"** para usarla como una app nativa a pantalla completa.

### Apps de Terceros

- **Android:** [Gallery for PhotoPrism](https://play.google.com/store/apps/details?id=com.photoprism.gallery)
- **iOS:** [PhotoSync](https://www.photosync-app.com/) (Ideal para subir fotos automáticamente).

## Copias de Seguridad

El sistema incluye scripts para asegurar que no pierdas nada.

- **Originales:** Se guardan directamente en Azure.
- **Base de Datos:** Se realiza un backup automático cada noche a las 3 AM que se sube a Azure (`/backup`).

### Recuperación ante desastres

Si tu Raspberry Pi falla, puedes restaurar todo en una nueva instalación ejecutando:

```bash
./scripts/restore_db.sh
```

## Contribuir

¡Las contribuciones son bienvenidas! Consulta [CONTRIBUTING.md](CONTRIBUTING.md) para saber cómo empezar.

## Licencia

Este proyecto está bajo la Licencia MIT - mira el archivo [LICENSE](LICENSE) para más detalles.
