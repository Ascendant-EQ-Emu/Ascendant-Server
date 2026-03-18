#!/usr/bin/env bash
set -euo pipefail

SRC_CODE="/opt/akk-stack/code/"
SRC_SERVER="/opt/akk-stack/server/"
DEST_ROOT="/home/straps/ascendant-server-repo"
DEST_CODE="$DEST_ROOT/code/"
DEST_SERVER="$DEST_ROOT/server/"
DEST_DB="$DEST_ROOT/database"

ENV_FILE="/home/straps/.sync-db.env"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
else
  echo "Missing env file: $ENV_FILE"
  exit 1
fi

: "${DB_CONTAINER:?DB_CONTAINER is not set in $ENV_FILE}"
: "${DB_NAME:?DB_NAME is not set in $ENV_FILE}"
: "${DB_USER:?DB_USER is not set in $ENV_FILE}"
: "${DB_PASS:?DB_PASS is not set in $ENV_FILE}"

DB_EXPORT_FILE_GZ="$DEST_DB/ascendant_content.sql.gz"

DATA_TABLES=(
  aa_ability
  aa_custom_mapping
  aa_rank_effects
  aa_rank_prereqs
  aa_ranks
  alternate_currency
  base_data
  char_create_combinations
  char_create_point_allocations
  db_str
  doors
  global_loot
  items
  lootdrop
  lootdrop_entries
  loottable
  loottable_entries
  merchantlist
  npc_faction
  npc_faction_entries
  npc_spells
  npc_spells_effects
  npc_spells_effects_entries
  npc_spells_entries
  npc_types
  npc_types_tint
  object
  object_contents
  pets
  player_titlesets
  rule_sets
  rule_values
  skill_caps
  spawn2
  spawn2_disabled
  spawn_condition_values
  spawn_conditions
  spawn_events
  spawnentry
  spawngroup
  spells_new
  start_zones
  task_activities
  tasks
  tasksets
  tier_defs
  titles
  tradeskill_recipe
  tradeskill_recipe_entries
  variables
  zone
  zone_flags
  zone_points
  zone_state_spawns
)

SCHEMA_ONLY_TABLES=(
  login_server_account_links
)

mkdir -p "$DEST_CODE" "$DEST_SERVER" "$DEST_DB"

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

echo "Exporting compressed database content to $DB_EXPORT_FILE_GZ..."

{
  echo "-- Ascendant content export"
  echo "-- Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "SET FOREIGN_KEY_CHECKS=0;"
  echo

  docker exec "$DB_CONTAINER" mysqldump \
    -u"$DB_USER" -p"$DB_PASS" \
    --single-transaction \
    --skip-comments \
    --routines \
    --triggers \
    "$DB_NAME" \
    "${DATA_TABLES[@]}"

  echo

  docker exec "$DB_CONTAINER" mysqldump \
    -u"$DB_USER" -p"$DB_PASS" \
    --no-data \
    --skip-comments \
    "$DB_NAME" \
    "${SCHEMA_ONLY_TABLES[@]}"

  echo
  echo "SET FOREIGN_KEY_CHECKS=1;"
} | gzip -9 > "$DB_EXPORT_FILE_GZ"

echo "Done."
echo "Created:"
echo "  $DB_EXPORT_FILE_GZ"
echo
echo "Review changes with:"
echo "  cd $DEST_ROOT && git status"