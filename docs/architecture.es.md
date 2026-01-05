# 📸 PhotoPrism en Raspberry Pi con Azure Blob Storage y Cloudflare Tunnel

[🔙 Volver al README](../README.es.md)

---

## 1. Objetivo del proyecto

El objetivo de este proyecto es **reemplazar Google Photos** por una solución:

- ✅ **Open‑source**
- ✅ Auto‑gestionada (self‑hosted)
- ✅ Ejecutándose en una **Raspberry Pi**
- ✅ Capaz de manejar **terabytes de fotos/vídeos** sin discos locales grandes
- ✅ Accesible desde Internet **sin IP fija ni apertura de puertos**
- ✅ Con almacenamiento de originales y backups en **Azure Blob Storage**
- ✅ Base de datos robusta (**MariaDB**) y optimización de **IA**

La solución elegida es **PhotoPrism**, desplegado mediante **Docker**, usando:

- **SSD USB local** → sistema base, base de datos (rendimiento) y caché
- **Azure Blob Storage** → fotos/vídeos originales y backups de base de datos
- **Cloudflare Tunnel** → acceso remoto seguro mediante subdominio

---

## 2. Requisitos y restricciones

### 2.1 Requisitos funcionales

- Importar toda la librería actual de **Google Photos**
- Mantener los **metadatos (fechas, ubicación)** en la medida de lo posible
- Poder navegar, buscar y visualizar fotos/vídeos desde web
- Escalar a varios TB sin redimensionar hardware local
- Detección de caras y clasificación de imágenes (IA) activada

### 2.2 Requisitos no funcionales

- No depender de IP pública fija
- No abrir puertos en el router
- Minimizar puntos de fallo (especialmente la SD)
- Mantener una arquitectura comprensible y mantenible

### 2.3 Restricciones técnicas

- PhotoPrism **requiere almacenamiento local** para:
  - miniaturas
  - caché
  - base de datos de alto rendimiento
  
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
├── SSD USB (EXT4) /mnt/ssd
│   ├── /photoprism/storage   (thumbnails, cache)
│   ├── /photoprism/database  (MariaDB data files)
│   └── /photoprism/import    (staging)
│
└── Azure Blob Storage (montado con rclone) /mnt/azurephotos
    ├── /originals            (fotos y vídeos, TBs)
    └── /backup               (dumps diarios de MariaDB)
```

---

## 4. Decisiones técnicas clave

### 4.1 Por qué SSD USB y no tarjeta SD

- PhotoPrism realiza **muchas escrituras pequeñas y constantes**
- Las tarjetas SD se degradan y ofrecen bajo IOPS
- Necesario para MariaDB

➡️ El SSD USB es **obligatorio** para un sistema estable.

### 4.2 Por qué Azure Blob Storage

- Escala prácticamente ilimitada
- Coste predecible
- Alta durabilidad
- Integrable mediante **rclone** como filesystem

➡️ Permite tener **TB de fotos** y **Backups centralizados** con solo **decenas de GB locales**.

### 4.3 Por qué rclone mount

- Compatible nativamente con Azure Blob
- Estable y ampliamente usado
- Permite a PhotoPrism trabajar como si fuera un disco local

### 4.4 Por qué MariaDB (y no SQLite)

- **Rendimiento superior** para librerías grandes (miles de fotos)
- Mejor gestión de concurrencia (evita bloqueos de base de datos)
- Mayor robustez ante corrupción de datos
- Estándar en despliegues de producción

### 4.5 Por qué Cloudflare Tunnel

- No requiere IP fija
- No requiere NAT ni puertos abiertos
- TLS automático
- Muy adecuado para homelabs

---

## 5. Preparación del sistema

### 5.1 Requisitos hardware

- Raspberry Pi 4 o 5 (mínimo 4 GB RAM recomendado, ideal 8GB para IA)
- SSD USB 3.0 (recomendado: **128 GB o superior**)
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

Crear carpetas dentro del montaje si no existen:

```bash
mkdir -p /mnt/azurephotos/originals
mkdir -p /mnt/azurephotos/backup
```

---

## 8. Despliegue con Docker Compose (Actualizado)

Incluye MariaDB y configuración de IA optimizada.

```yaml
services:
  mariadb:
    image: mariadb:11
    restart: unless-stopped
    command: mariadbd --innodb-buffer-pool-size=512M --transaction-isolation=READ-COMMITTED --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --max-connections=512 --innodb-rollback-on-timeout=OFF --innodb-lock-wait-timeout=120
    volumes:
      - /mnt/ssd/photoprism/database:/var/lib/mysql
    environment:
      MARIADB_AUTO_UPGRADE: "1"
      MARIADB_INITDB_SKIP_TZINFO: "1"
      MARIADB_DATABASE: photoprism
      MARIADB_USER: photoprism
      MARIADB_PASSWORD: CAMBIAR_DB_PASSWORD
      MARIADB_ROOT_PASSWORD: CAMBIAR_ROOT_PASSWORD

  photoprism:
    image: photoprism/photoprism:latest
    container_name: photoprism
    restart: unless-stopped
    depends_on:
      - mariadb
    ports:
      - "2342:2342"
    environment:
      PHOTOPRISM_ADMIN_PASSWORD: CAMBIAR_ADMIN_PASSWORD
      PHOTOPRISM_SITE_URL: https://fotos.tudominio.com/
      
      # Rutas de almacenamiento
      PHOTOPRISM_STORAGE_PATH: /photoprism/storage
      PHOTOPRISM_ORIGINALS_PATH: /photoprism/originals
      
      # Configuración de Base de Datos (MariaDB)
      PHOTOPRISM_DATABASE_DRIVER: mysql
      PHOTOPRISM_DATABASE_SERVER: mariadb:3306
      PHOTOPRISM_DATABASE_NAME: photoprism
      PHOTOPRISM_DATABASE_USER: photoprism
      PHOTOPRISM_DATABASE_PASSWORD: CAMBIAR_DB_PASSWORD
      
      # Configuración de IA y Metadatos
      PHOTOPRISM_DISABLE_FACES: "false"        # Activar reconocimiento facial
      PHOTOPRISM_DISABLE_CLASSIFICATION: "false" # Activar clasificación de imagen
      PHOTOPRISM_SIDECAR_YAML: "true"          # Guardar metadatos en YAML junto a originales (Backup resiliente)
      PHOTOPRISM_THUMB_FILTER: "lanczos"       # Mejor calidad de thumbnails
      PHOTOPRISM_DETECT_NSFW: "false"          # Opcional, según preferencia
      
    volumes:
      - /mnt/ssd/photoprism/storage:/photoprism/storage
      - /mnt/azurephotos/originals:/photoprism/originals
  
  cloudflared:
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    command: tunnel run
    environment:
      TUNNEL_TOKEN: TU_TOKEN_DE_CLOUDFLARE
```

```bash
docker compose up -d
```

---

## 9. Estrategia de Backups Automáticos

Para cumplir con el requisito de que **todo el storage crítico esté en Azure**, implementamos un backup automático de la base de datos MariaDB hacia el contenedor de Azure.

Crear un script en la Raspberry Pi `/home/pi/backup_db.sh`:

```bash
#!/bin/bash
# Definir timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/mnt/azurephotos/backup"
KEEP_DAYS=7

# Verificar que el montaje de Azure está activo
if mountpoint -q /mnt/azurephotos; then
    # Volcar base de datos directamente a Azure
    docker exec mariadb mariadb-dump -u photoprism -pCAMBIAR_DB_PASSWORD photoprism > "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"
    
    # Comprimir (opcional, ahorra espacio y transferencia, aunque rclone maneja bien archivos grandes)
    gzip "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"
    
    # Limpiar backups antiguos (mayores a 7 días)
    find "$BACKUP_DIR" -name "db_backup_*.sql.gz" -mtime +$KEEP_DAYS -delete
else
    echo "Error: Azure no está montado"
fi
```

Añadir al cron (`crontab -e`) para ejecutar cada noche a las 3 AM:

```cron
0 3 * * * /bin/bash /home/pi/backup_db.sh
```

Con esto, tanto los **originales** como la **base de datos** residen en Azure Blob Storage. Si la Raspberry Pi o el SSD mueren, no se pierden datos, solo la caché generada.

---

## 10. Migración desde Google Photos

### 10.1 Exportación

- Usar **Google Takeout**
- Exportar únicamente *Google Photos*

### 10.2 Extracción

```bash
unzip '*.zip' -d /mnt/ssd/photoprism/import
```

### 10.3 Importación y Clasificación

Al tener activada la IA y MariaDB, el proceso de importación analizará caras y objetos.

```bash
# Mover archivos de import a originales en Azure y indexar
docker compose exec photoprism photoprism import
```

Esto procesará las fotos en el SSD y las moverá a `/photoprism/originals` (que apunta a Azure), creando las miniaturas en el SSD.

---

## 11. Acceso remoto con Cloudflare Tunnel

*(Sin cambios en la configuración del túnel, ver sección 8 para docker compose)*

---

## 12. Riesgos y mitigaciones

| Riesgo | Mitigación |
| :--- | :--- |
| Corrupción SD | SSD USB obligatorio |
| Latencia Azure | Caché VFS + thumbnails locales |
| Pérdida DB Local | **MariaDB + Backup diario automático a Azure** |
| Fallo de Hardware Pi | Reemplazar Pi, reinstalar Docker y restaurar backup de Azure |

---

## 13. Evoluciones futuras

- Replicación de Azure a otro proveedor (Backup Geo-redundante adicional)

---

## 14. Conclusión

Esta arquitectura **Plug & Play** permite:

- Reemplazar Google Photos con una experiencia de usuario rica (IA, Mapas)
- Escalar a varios TB gracias a Azure Blob Storage
- Dormir tranquilo sabiendo que **todos los datos persistentes** (Fotos + DB) están seguros en la nube
- Mantener la velocidad de acceso local gracias al SSD y MariaDB

Es un sistema robusto, escalable y privado.
