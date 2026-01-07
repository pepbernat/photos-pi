#!/bin/bash
# Script de restauración para Immich (PostgreSQL)

if [ -z "$1" ]; then
    echo "Uso: $0 <archivo_backup.sql.gz>"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: El archivo $BACKUP_FILE no existe"
    exit 1
fi

echo "ADVERTENCIA: Esto sobrescribirá la base de datos actual de Immich."
read -p "¿Estás seguro? (s/N): " confirm

if [[ $confirm == [sS] || $confirm == [sS][iI] ]]; then
    echo "Restaurando desde $BACKUP_FILE..."
    gunzip -c "$BACKUP_FILE" | docker exec -i immich_postgres psql -U postgres -d immich
    echo "Restauración completada."
else
    echo "Cancelado."
fi
