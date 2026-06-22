#!/bin/bash
# Database backup script for EQEmu server
set -e

BACKUP_DIR="/backups"
DB_HOST="${DB_HOST:-mariadb}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-eqemu}"
DB_PASS="${DB_PASS:-eqemu}"
DB_NAME="${DB_NAME:-peq}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}-${TIMESTAMP}.sql.gz"

echo "[$(date)] Starting database backup..."

mysqldump \
    -h "$DB_HOST" \
    -P "$DB_PORT" \
    -u "$DB_USER" \
    -p"$DB_PASS" \
    --single-transaction \
    --routines \
    --triggers \
    "$DB_NAME" | gzip > "$BACKUP_FILE"

echo "[$(date)] Backup saved to: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"

# Clean up old backups
if [ "$RETENTION_DAYS" -gt 0 ]; then
    DELETED=$(find "$BACKUP_DIR" -name "*.sql.gz" -mtime +"$RETENTION_DAYS" -print -delete | wc -l)
    if [ "$DELETED" -gt 0 ]; then
        echo "[$(date)] Removed $DELETED backup(s) older than $RETENTION_DAYS days"
    fi
fi

echo "[$(date)] Backup complete."
