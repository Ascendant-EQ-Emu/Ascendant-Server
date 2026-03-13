# Ascendant EQ — Custom Plugins

All `ascendant_*.pl` files are custom plugins for the Ascendant server. They are loaded automatically by the EQEmu quest system and called from `global_npc.pl`, `global_player.pl`, and individual NPC scripts.

## Plugin Index

### Loot System
| File | Purpose |
|------|---------|
| `ascendant_loot_pools.pl` | Centralized item pool data for all expansions, organized by level band and raid group |
| `ascendant_loot_utils.pl` | Shared loot logic: active expansion config, level block resolution, tier upgrade rolls |
| `ascendant_mischief_style_loot.pl` | Guaranteed bonus loot for rare/named spawns from merged expansion pools |
| `ascendant_mischief_style_raid_loot.pl` | Bonus items (2-3) for raid bosses from per-boss loot groups |
| `ascendant_common_mob_bonus_loot.pl` | 1% chance for any mob to drop a bonus item from expansion pools |

### Economy & Rewards
| File | Purpose |
|------|---------|
| `ascendant_moa_tokens.pl` | Mark of Ascendance award system — online timer + combat roll, daily/weekly/IP caps |
| `ascendant_gambling.pl` | Tiered gambling loot pools for the Harley Wynn NPC (Lucky Coin system) |

### Character Systems
| File | Purpose |
|------|---------|
| `ascendant_buff_bag_system.pl` | Buff Satchel — 6-slot container + wand that bulk-applies buff scrolls. Also handles Crystalize Essence (XP→scroll forge) |
| `ascendant_pet_bag_system.pl` | Pet equipment bag — auto-equips items to pets on spawn, manages DPS gating, procs, and stat display |
| `ascendant_insight_trainer.pl` | AA Insight Training — tome turn-in, tiered credits, AA browsing/purchasing from guild masters |
| `ascendant_tome_translator.pl` | Class→tome mapping data for the Insight Trainer. Maps class bitmasks to tome item IDs across 3 tiers |

### Encounter System
| File | Purpose |
|------|---------|
| `ascendant_encounter_scaling.pl` | Dynamic encounter scaling — adjusts NPC stats at engage based on group/raid composition. Profile auto-assigned from DB flags (raid/named/trash) |

### Expedition System
| File | Purpose |
|------|---------|
| `ascendant_expeditions.pl` | Expedition creation, teleportation, lockout management, and group handling |
| `ascendant_expedition_config.pl` | Per-zone expedition config — mega-boss exclusions, zone versions, display names |

### Utility
| File | Purpose |
|------|---------|
| `ascendant_antiwarp.pl` | Anti-warp system — movement speed validation to prevent teleport hacking. See `ascendant_antiwarp_readme.md` for setup |

## Tier Offset Convention

Items use additive offsets to determine tier:
- **Base**: original item ID
- **Tier 1 (Greater)**: base + 300,000
- **Tier 2 (Exalted)**: base + 500,000
- **Tier 3 (Ascendant)**: base + 700,000

This convention is shared across Khael the Spellforger, Morvain the Diminisher, and the loot randomization system in `global_npc.pl`.

## Data Storage

Most persistent data uses `quest::get_data` / `quest::set_data` with structured key formats:
- **MoA tokens**: `moa:{charid}:{day}:{type}` with midnight TTL
- **Credits**: `character-{charid}-{bucket}_{class_id}`
- **Pet bag**: `petbag_base:{charid}_{pet_eid}` with 4h TTL
- **Cooldowns**: `crystalize_essence_{charid}` with 6h TTL

## Author

Straps
