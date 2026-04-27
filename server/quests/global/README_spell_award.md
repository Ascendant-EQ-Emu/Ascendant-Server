# Custom Spell Unlock System

## Architecture

```
Event:  event_level_up
          │
          ▼
    spell_award.on_level_up(client)
          │
          ├─ [already awarded this level?] → show reminder of existing offer or skip
          ├─ [filter pool] → spells where level ≤ char_level, not already scribed
          ├─ [pick 3 random] → Fisher-Yates partial shuffle
          ├─ [persist] → eq.set_data("sa_pending:{char_id}", "id1,id2,id3:level")
          └─ [display] → chat window numbered menu

Event:  event_say  (player says "1", "2", or "3")
          │
          ▼
    spell_award.on_say(client, message)
          │
          ├─ [validate] → pending offer exists?
          ├─ [award] → SummonItem(scroll_id) or ScribeSpell(spell_id, slot)
          ├─ [lock] → eq.set_data("sa_done:{char_id}", "...,level")
          └─ [clear] → eq.delete_data("sa_pending:{char_id}")
```

## Data Bucket Keys

| Key | Value | Purpose |
|-----|-------|---------|
| `sa_done:{char_id}` | `"1,5,10,..."` | Levels where award was already given |
| `sa_pending:{char_id}` | `"100,200,300:5"` | Current unanswered offer (spells + level) |

Stored in EQEmu's `data_buckets` table. No schema changes required.

## Files

| File | Purpose |
|------|---------|
| `global/spell_pool.lua` | Generated pool of 10,839 eligible spells (auto-generated) |
| `global/spell_award.lua` | Core award logic module |
| `global/global_player.lua` | Entry points: `event_level_up`, `event_say` |
| `assets/scripts/generate_spell_pool.pl` | Regenerates spell_pool.lua from DB |
| `assets/scripts/sql/01_normalize_spell_classes.sql` | Makes all spells class-universal |
| `assets/scripts/sql/02_remove_vendor_spells.sql` | Removes scrolls from all vendors |

## Regenerating the Spell Pool

Run after any spell DB changes:
```bash
docker exec akk-stack-eqemu-server-1 \
  perl /home/eqemu/server/../assets/scripts/generate_spell_pool.pl
```
Then reload zones (they pick up the new module on zone restart).

## Anti-Exploit Guarantee

The `sa_done:{char_id}` bucket persists permanently. Even if a character delevel/relevels,
their level is already in the list and the award is skipped. The bucket can only be
cleared by a GM via `#databucket delete sa_done:{char_id}`.
