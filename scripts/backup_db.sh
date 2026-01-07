#!/bin/bash
# Backup script for Immich (PostgreSQL)
# Definir timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/mnt/azurephotos/backup"
KEEP_DAYS=7

# Verificar que el montaje de Azure está activo
if mountpoint -q /mnt/azurephotos; then
    echo "Starting backup to $BACKUP_DIR..."
    
    # Crear directorio si no existe (aunque debería estar en azure)
    mkdir -p "$BACKUP_DIR"

    # Volcar base de datos directamente a Azure
    # Usamos docker exec para ejecutar pg_dumpall dentro del contenedor
    docker exec immich_postgres pg_dumpall -c -U postgres | gzip > "$BACKUP_DIR/db_backup_immich_$TIMESTAMP.sql.gz"
    
    echo "Backup completed: $BACKUP_DIR/db_backup_immich_$TIMESTAMP.sql.gz"

    # Limpiar backups antiguos (mayores a 7 días)
    echo "Cleaning up backups older than $KEEP_DAYS days..."
    find "$BACKUP_DIR" -name "db_backup_immich_*.sql.gz" -mtime +$KEEP_DAYS -delete
else
    echo "Error: Azure no está montado en /mnt/azurephotos"
    exit 1
fi
