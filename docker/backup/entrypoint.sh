#!/bin/bash
# Set up cron schedule and run
set -e

BACKUP_SCHEDULE="${BACKUP_SCHEDULE:-0 */6 * * *}"

echo "[$(date)] Setting up backup cron: $BACKUP_SCHEDULE"

# Write environment to file so cron can source it
env | grep -E '^(DB_|BACKUP_)' > /etc/backup.env

# Create cron job
echo "$BACKUP_SCHEDULE root . /etc/backup.env; /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1" > /etc/cron.d/eqemu-backup
chmod 0644 /etc/cron.d/eqemu-backup
crontab /etc/cron.d/eqemu-backup

# Run an initial backup on startup
echo "[$(date)] Running initial backup..."
/usr/local/bin/backup.sh

# Start cron in foreground
echo "[$(date)] Starting cron daemon..."
touch /var/log/backup.log
cron
exec tail -f /var/log/backup.log
