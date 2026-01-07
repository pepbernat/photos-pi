# 📸 Immich en Raspberry Pi con Azure Blob Storage y Cloudflare Tunnel

[🔙 Volver al README](../README.es.md)

---

## 1. Objetivo del proyecto

El objetivo de este proyecto es **reemplazar Google Photos** por una solución:

- ✅ **Open‑source** (Immich)
- ✅ Auto‑gestionada (self‑hosted)
- ✅ Ejecutándose en una **Raspberry Pi**
- ✅ Capaz de manejar **terabytes de fotos/vídeos** sin discos locales grandes
- ✅ Accesible desde Internet **sin IP fija ni apertura de puertos**
- ✅ Con almacenamiento de originales y backups en **Azure Blob Storage**
- ✅ Base de datos robusta (**PostgreSQL**) y optimización de **IA**

La solución elegida es **Immich**, (anteriormente PhotoPrism), desplegado mediante **Docker**, usando:

- **SSD USB local** → sistema base, base de datos (Postgres/Redis) y caché de Machine Learning.
- **Azure Blob Storage** → fotos/vídeos originales y backups de base de datos.
- **Cloudflare Tunnel** → acceso remoto seguro mediante subdominio.

---

## 2. Requisitos y restricciones

### 2.1 Requisitos funcionales

- Copia de seguridad automática desde móviles (Android/iOS).
- Mantener los **metadatos (fechas, ubicación)** en la medida de lo posible.
- Poder navegar, buscar y visualizar fotos/vídeos desde web y app móvil.
- Escalar a varios TB sin redimensionar hardware local.
- Detección de caras y clasificación de imágenes (IA activada).

### 2.2 Requisitos no funcionales

- No depender de IP pública fija.
- No abrir puertos en el router.
- Minimizar puntos de fallo (especialmente la SD).
- Mantener una arquitectura comprensible y mantenible.

### 2.3 Restricciones técnicas

- Immich requiere **base de datos PostgreSQL con extensión pgvector**.
- Immich **requiere almacenamiento local rápido** para:
  - Cache de modelos de Machine Learning.
  - Base de datos y Redis.
  
➡️ **No es posible** ejecutar Immich de forma fluida sin un disco local fiable (SSD).

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
│   ├── /immich/postgres      (PostgreSQL data files)
│   ├── /immich/model-cache   (Cache de modelos IA)
│   └── /immich/redis         (Redis data)
│
└── Azure Blob Storage (montado con rclone) /mnt/azurephotos
    ├── /originals            (Fotos antiguas y nuevas subidas de Immich)

    └── /backup               (Dumps diarios de Postgres)
```

---

## 4. Decisiones técnicas clave

### 4.1 Cambio a Immich

Immich ofrece una experiencia mucho más cercana a Google Photos que PhotoPrism, con apps móviles nativas que realizan *background backup*, gestión multi-usuario real, y una interfaz extremadamente rápida.

### 4.2 Por qué SSD USB y no tarjeta SD

- Immich y PostgreSQL realizan **muchas escrituras**.
- Las tarjetas SD se degradan y ofrecen bajo IOPS.

➡️ El SSD USB es **obligatorio** para un sistema estable.

### 4.3 Por qué rclone mount

- Permite que Immich vea el almacenamiento de Azure como una carpeta local.
- Usamos la carpeta antigua de `/originals` como una **Librería Externa** en Immich, evitando mover TBs de datos.

### 4.4 Por qué Cloudflare Tunnel

- No requiere IP fija ni puertos abiertos.
- Gestiona TLS automáticamente.

---

## 5. Preparación del sistema

### 5.1 Requisitos hardware

- Raspberry Pi 4 o 5 (mínimo 4 GB RAM recomendado, ideal 8GB para IA).
- SSD USB 3.0 (recomendado: **128 GB o superior**).

### 5.2 Sistema operativo

- Raspberry Pi OS **64‑bit**.
- Docker + Docker Compose.

---

## 6. Preparación del almacenamiento local (SSD)

Estructura usada en el SSD local:

```text
/mnt/ssd/immich/
├── postgres
└── model-cache
```

---

## 7. Azure Blob Storage

Se mantiene la configuración existente, montada en `/mnt/azurephotos`.

Dentro de Azure tendremos:

- `/originals`: Almacén unificado para fotos antiguas y nuevas subidas.

---

## 8. Despliegue con Docker Compose

Incluye Immich Server, Microservices, Machine Learning, Redis y PostgreSQL.

Ver `docker-compose.yml` en la raíz del repositorio para la definición completa de servicios.

```bash
docker compose up -d
```

---

## 9. Estrategia de Backups Automáticos

Para cumplir con el requisito de que **todo el storage crítico esté en Azure**, implementamos un backup automático de PostgreSQL hacia Azure.

Script: `/scripts/backup_db.sh`

- Usa `pg_dumpall`.
- Comprime el resultado.
- Guarda en `/mnt/azurephotos/backup`.
- Mantiene los últimos 7 días.

---

## 10. Migración de Datos (Legacy)

Dado que la base de datos de PhotoPrism (MariaDB) no es compatible con Immich (Postgres), y la estructura de archivos es diferente:

1. **Fotos Existentes:**
   - En Immich, ir a Administración -> Librerías Externas.
   - Crear una nueva librería apuntando a `/usr/src/app/external/originals`.
   - Immich escaneará y catalogará estas fotos sin moverlas.

2. **Nuevas Fotos:**
   - Se subirán via App Móvil o Web.
   - Se guardarán en `/mnt/azurephotos/originals`.

---

## 11. Riesgos y mitigaciones

| Riesgo | Mitigación |
| :--- | :--- |
| Corrupción SD | SSD USB obligatorio |
| Latencia Azure | Caché local + Thumbnails generados localmente |
| Pérdida DB Local | **Backup diario automático de Postgres a Azure** |
| Fallo de Hardware Pi | Reemplazar Pi, reinstalar Docker y restaurar backup de Azure |

---

## 12. Conclusión

Esta arquitectura modernizada con **Immich**:

- Ofrece la mejor experiencia de usuario "Google Photos like".
- Mantiene la escalabilidad de Azure Blob Storage.
- Asegura la persistencia de datos (Fotos + DB) fuera de la Pi.
