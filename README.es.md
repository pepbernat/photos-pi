# 📸 Immich en Raspberry Pi (Ultimate Edition)

![Immich + Raspberry Pi](https://img.shields.io/badge/Immich-Raspberry%20Pi-blue?style=for-the-badge&logo=raspberrypi)
![Azure Blob Storage](https://img.shields.io/badge/Storage-Azure%20Blob-0078D4?style=for-the-badge&logo=microsoftazure)
![Cloudflare Tunnel](https://img.shields.io/badge/Access-Cloudflare%20Zero%20Trust-F38020?style=for-the-badge&logo=cloudflare)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

Bienvenido. Este repositorio proporciona una configuración **"Plug & Play"** para desplegar tu propio **Google Photos privado** en una Raspberry Pi, utilizando **Immich** combinado con la escalabilidad de la nube de Azure.

🇺🇸 **Read this in English: [README.md](README.md)**

---

## Tabla de Contenidos

- [Características](#características)
- [Arquitectura](#arquitectura)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Uso y Apps Móviles](#uso-y-apps-m%C3%B3viles)
- [Backups](#backups)
- [Contribuir](#contribuir)
- [Licencia](#licencia)

---

## Características

1. **La mejor alternativa a Google Photos:** Immich ofrece una interfaz moderna, rápida y aplicaciones nativas para iOS y Android con copia de seguridad en segundo plano.
2. **Almacenamiento Ilimitado e Híbrido:**
    - **Azure Blob Storage:** Almacena los originales (Terabytes de fotos a bajo coste).
    - **SSD Local:** Almacena la base de datos y la caché de IA para máxima velocidad.
3. **Acceso Remoto Seguro:** Sin abrir puertos en el router. Accede desde cualquier lugar (`https://fotos.tudominio.com`) gracias a Cloudflare Tunnel.
4. **Resiliencia:** Base de datos robusta (PostgreSQL) y backups automáticos a la nube.
5. **Privacidad Total:** Tus datos, tu control.

## Arquitectura

El sistema utiliza una arquitectura híbrida inteligente para balancear coste y rendimiento.
Para entender cómo funciona bajo el capó, revisa el documento de **[Arquitectura Técnica](docs/architecture.es.md)**.

## Requisitos

- **Hardware:** Raspberry Pi 4 o 5 (Min 4GB RAM, Ideal 8GB).
- **Almacenamiento Local:** Disco SSD USB (Min 128GB). *No uses tarjeta SD para datos.*
- **Nube:** Una cuenta de Azure (Blob Storage) y un dominio en Cloudflare.

## Instalación

Sigue estos pasos para tenerlo funcionando en 15 minutos.

### 1. Clonar el repositorio

Entra por SSH a tu Raspberry Pi y descarga el código:

```bash
git clone https://github.com/pepbernat/Photos-Pi.git
cd Photos-Pi
```

### 2. Preparar el Sistema

Ejecuta el script automático para instalar Docker, Rclone y ajustar permisos:

```bash
./scripts/setup_system.sh
```

## Configuración

Copia la plantilla de configuración:

```bash
cp .env.example .env
nano .env
```

Edita el fichero `.env` con tus contraseñas y tokens.
> 💡 **¿Necesitas el Token de Cloudflare?** Sigue esta **[Guía Paso a Paso](docs/setup-cloudflare.md)**.

### 4. Conectar Azure

Ejecuta el asistente para configurar `rclone` y conectar tu almacenamiento:

```bash
./scripts/setup_rclone.sh
```

### 5. Desplegar

Levanta los servicios con Docker Compose:

```bash
docker compose up -d
```

Espera unos minutos a que inicie. Podrás acceder en `https://fotos.tudominio.com` o `http://<TU-IP-PI>:2283`.

Crea tu cuenta de administrador al acceder por primera vez.

## Uso y Apps Móviles

Descarga la app de Immich para tu móvil:

- **Android:** [Google Play](https://play.google.com/store/apps/details?id=app.immich)
- **iOS:** [App Store](https://apps.apple.com/app/immich/id1677386979)

Introduce la URL de tu servidor (`https://fotos.tudominio.com`) y haz login.

## Backups

El sistema incluye scripts para asegurar que no pierdes nada.

- **Originals:** Almacenados directamente en Azure.
- **Base de Datos:** Se realiza un backup automático cada noche a las 3 AM y se sube a Azure (`/backup`).

### Disaster Recovery

Si tu Raspberry Pi falla, puedes restaurar todo en una instalación limpia ejecutando:

```bash
./scripts/restore_db.sh <fichero_backup>
```

## Contribuir

¡Las contribuciones son bienvenidas! Mira [CONTRIBUTING.md](CONTRIBUTING.md) para empezar.

## Licencia

Este proyecto está bajo la Licencia MIT - mira el fichero [LICENSE](LICENSE) para detalles.
