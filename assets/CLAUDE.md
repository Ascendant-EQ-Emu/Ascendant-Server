# Assets — Notes for Claude

## Required DB Migrations (spells_new table)

The following SQL scripts in `assets/scripts/sql/` make direct changes to the
`spells_new` table. They must be re-run any time the database is wiped or a
fresh PEQ base import is applied.

| Script | What it does |
|---|---|
| `01_normalize_spell_classes.sql` | Sets all 16 `classesX` fields to the minimum non-255 level across classes (normalizes so all classes share the lowest level requirement) |
| `03_set_min_cast_level.sql` | Sets all `classesX` to `1` so any character level can cast/scribe any spell |
| `04_remove_spell_reagents.sql` | Sets `components1-4` to `-1` and `component_counts1-4` to `0` so spells cast without consuming reagents (e.g. Animate Dead no longer needs Bone Chips) |

### How to re-apply

```bash
cd /home/papa/akk-stack
for f in assets/scripts/sql/01_normalize_spell_classes.sql \
          assets/scripts/sql/03_set_min_cast_level.sql \
          assets/scripts/sql/04_remove_spell_reagents.sql; do
    docker exec -i akk-stack-mariadb-1 mysql -ueqemu -pDPFS00Lw8s2H5sdLFAwOI7VTg61BnW8 peq < "$f"
    echo "Applied: $f"
done
```

> Note: `02_remove_vendor_spells.sql` is also in that directory but does not
> touch `spells_new` — check its contents before re-applying.

## Client File Distribution

After any DB migration that touches spell classes or levels, regenerate the
client-side spell file and distribute it to players:

```bash
docker exec akk-stack-eqemu-server-1 \
  perl /home/eqemu/server/../assets/scripts/generate_spell_pool.pl
```

Output: `server/export/spells_us_norequirements.txt`
Players must copy this to their EQ client directory as `spells_us.txt` to
memorize spells without class/level restrictions.
