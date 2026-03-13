#!/usr/bin/env bash
set -euo pipefail

SRC_CODE="/opt/akk-stack/code/"
SRC_SERVER="/opt/akk-stack/server/"
DEST_ROOT="/home/straps/ascendant-server-repo"
DEST_CODE="$DEST_ROOT/code/"
DEST_SERVER="$DEST_ROOT/server/"

mkdir -p "$DEST_CODE" "$DEST_SERVER"

echo "Syncing code..."
rsync -av --delete \
  --exclude='.git' \
  "$SRC_CODE" "$DEST_CODE"

echo "Syncing server..."
rsync -av --delete \
  --exclude='.git' \
  --exclude='eqemu_config.json' \
  --exclude='login.json' \
  --exclude='nohup.out' \
  --exclude='*.log' \
  --exclude='logs/' \
  --exclude='*.sql' \
  --exclude='*.sql.gz' \
  --exclude='*.bak' \
  --exclude='*.dump' \
  --exclude='backups/' \
  --exclude='dumps/' \
  --exclude='shared/hotfix_items' \
  --exclude='shared/items' \
  --exclude='bin/spire' \
  --exclude='talkeq.conf' \
  --exclude='talkeq_guilds.txt' \
  --exclude='talkeq_users.txt' \
  --exclude='talkeq-linux' \
  "$SRC_SERVER" "$DEST_SERVER"

echo "Done."
echo "Review changes with:"
echo "  cd $DEST_ROOT && git status"