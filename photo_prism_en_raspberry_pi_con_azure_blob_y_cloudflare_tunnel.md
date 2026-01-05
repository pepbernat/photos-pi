# 📸 PhotoPrism en Raspberry Pi con Azure Blob Storage y Cloudflare Tunnel

## 1. Objetivo del proyecto

El objetivo de este proyecto es **reemplazar Google Photos** por una solución:

- ✅ **Open‑source**
- ✅ Auto‑gestionada (self‑hosted)
- ✅ Ejecutándose en una **Raspberry Pi**
- ✅ Capaz de manejar **terabytes de fotos/vídeos** sin discos locales grandes
- ✅ Accesible desde Internet **sin IP fija ni apertura de puertos**
- ✅ Con almacenamiento de originales en **Azure Blob Storage**

La solución elegida es **PhotoPrism**, desplegado mediante **Docker**, usando:

- **SSD USB local** → base de datos, caché y miniaturas
- **Azure Blob Storage** → fotos y vídeos originales
- **Cloudflare Tunnel** → acceso remoto seguro mediante subdominio

---

## 2. Requisitos y restricciones

### 2.1 Requisitos funcionales

- Importar toda la librería actual de **Google Photos**
- Mantener los **metadatos (fechas, ubicación)** en la medida de lo posible
- Poder navegar, buscar y visualizar fotos/vídeos desde web
- Escalar a varios TB sin redimensionar hardware local

### 2.2 Requisitos no funcionales

- No depender de IP pública fija
- No abrir puertos en el router
- Minimizar puntos de fallo (especialmente la SD)
- Mantener una arquitectura comprensible y mantenible

### 2.3 Restricciones técnicas

- PhotoPrism **requiere almacenamiento local** para:
  - miniaturas
  - caché
  - índices
  - base de datos

➡️ **No es posible** ejecutar PhotoPrism sin ningún disco local fiable.

---

## 3. Arquitectura final

```text
Internet
  │
  ▼
Cloudflare (HTTPS, DNS, Zero Trust)
  │
  ▼
Cloudflare Tunnel (saliente)
  │
  ▼
Raspberry Pi
├── SSD USB (EXT4)
│   ├── /photoprism/storage   (thumbnails, cache, index)
│   ├── /photoprism/database  (SQLite)
│   └── /photoprism/import    (staging)
│
└── Azure Blob Storage (montado con rclone)
    └── /photoprism/originals (fotos y vídeos, TBs)
```

---

## 4. Decisiones técnicas clave

### 4.1 Por qué SSD USB y no tarjeta SD

- PhotoPrism realiza **muchas escrituras pequeñas y constantes**
- Las tarjetas SD:
  - se degradan rápidamente
  - tienen bajo rendimiento IOPS
  - suelen corromperse

➡️ El SSD USB es **obligatorio** para un sistema estable.

### 4.2 Por qué Azure Blob Storage

- Escala prácticamente ilimitada
- Coste predecible
- Alta durabilidad
- Integrable mediante **rclone** como filesystem

➡️ Permite tener **TB de fotos** con solo **decenas de GB locales**.

### 4.3 Por qué rclone mount

- Compatible nativamente con Azure Blob
- Estable y ampliamente usado
- Permite a PhotoPrism trabajar como si fuera un disco local

### 4.4 Por qué SQLite (y no MariaDB)

- Menor complejidad operativa
- Rendimiento suficiente para uso personal/familiar
- Fácil backup

➡️ MariaDB se deja como optimización futura.

### 4.5 Por qué Cloudflare Tunnel

- No requiere IP fija
- No requiere NAT ni puertos abiertos
- TLS automático
- Muy adecuado para homelabs

---

## 5. Preparación del sistema

### 5.1 Requisitos hardware

- Raspberry Pi 4 o 5 (mínimo 4 GB RAM recomendado)
- SSD USB 3.0 (recomendado: **128 GB**)
- Conectividad estable a Internet

### 5.2 Sistema operativo

- Raspberry Pi OS **64‑bit**
- Docker + Docker Compose

---

## 6. Preparación del almacenamiento local (SSD)

```bash
sudo mkfs.ext4 /dev/sda1
sudo mkdir -p /mnt/ssd
sudo mount /dev/sda1 /mnt/ssd
```

Estructura usada:

```text
/mnt/ssd/photoprism/
├── storage
├── database
└── import
```

---

## 7. Azure Blob Storage

### 7.1 Creación

- Crear cuenta de Azure Storage
- Crear un **Blob Container** (ej: `photos`)

### 7.2 Configuración de rclone

```bash
rclone config
```

Crear un remote, por ejemplo: `azureblob`

### 7.3 Montaje del contenedor

```bash
sudo mkdir -p /mnt/azurephotos

rclone mount azureblob:photos /mnt/azurephotos \
  --vfs-cache-mode writes \
  --allow-other \
  --dir-cache-time 72h
```

Este directorio será el **ORIGINALS_PATH** de PhotoPrism.

---

## 8. Despliegue con Docker Compose

```yaml
services:
  photoprism:
    image: photoprism/photoprism:latest
    container_name: photoprism
    restart: unless-stopped
    ports:
      - "2342:2342"
    environment:
      PHOTOPRISM_ADMIN_PASSWORD: CAMBIAR_PASSWORD
      PHOTOPRISM_SITE_URL: https://fotos.tudominio.com/
      PHOTOPRISM_STORAGE_PATH: /photoprism/storage
      PHOTOPRISM_ORIGINALS_PATH: /photoprism/originals
    volumes:
      - /mnt/ssd/photoprism/storage:/photoprism/storage
      - /mnt/ssd/photoprism/database:/photoprism/database
      - /mnt/azurephotos:/photoprism/originals
```

```bash
docker compose up -d
```

---

## 9. Migración desde Google Photos

### 9.1 Exportación

- Usar **Google Takeout**
- Exportar únicamente *Google Photos*

### 9.2 Extracción

```bash
unzip '*.zip' -d /mnt/ssd/photoprism/import
```

### 9.3 Metadatos

Google Photos genera archivos `.json` auxiliares.

Opciones:
- Importar directamente (más rápido)
- Procesar JSON → EXIF con herramientas externas (mejor calidad)

➡️ Se recomienda **hacer primero una importación simple** y refinar después.

### 9.4 Copia a Azure

```bash
rclone copy /mnt/ssd/photoprism/import azureblob:photos
```

---

## 10. Indexación en PhotoPrism

Desde la UI web:

- Library → Index
- Primera indexación puede tardar horas

Después, las indexaciones son incrementales.

---

## 11. Acceso remoto con Cloudflare Tunnel

### 11.1 Crear túnel

- Cloudflare Zero Trust → Tunnels
- Asociar subdominio: `fotos.tudominio.com`

### 11.2 Contenedor cloudflared

```yaml
  cloudflared:
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    command: tunnel run
```

Cloudflare se encarga de:
- HTTPS
- Certificados
- DNS
- Seguridad

---

## 12. Riesgos y mitigaciones

| Riesgo | Mitigación |
|-----|-----------|
| Corrupción SD | SSD USB obligatorio |
| Latencia Azure | Caché VFS + thumbnails locales |
| Pérdida DB | Backups regulares del SSD |
| Subida inicial lenta | Migración por lotes |

---

## 13. Evoluciones futuras

- Migrar SQLite → MariaDB
- Backups automáticos a Azure
- Afinar IA y reconocimiento
- Replicación de Azure a otro proveedor

---

## 14. Conclusión

Esta arquitectura permite:

- Reemplazar Google Photos
- Escalar a varios TB
- Mantener costes y complejidad controlados
- Evitar dependencias de red doméstica

Es un **equilibrio consciente** entre simplicidad, fiabilidad y escalabilidad.

