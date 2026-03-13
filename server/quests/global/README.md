# Ascendant EQ — Global Scripts

Global scripts run for every zone on the server. They handle the core gameplay hooks that drive loot, scaling, buffs, tokens, and other cross-zone systems.

## Core Files

| File | Purpose |
|------|---------|
| `global_player.pl` | All player events: zone entry (aura reapply, MoA timer start, anti-warp), combat (MoA kill roll), timers (online MoA roll, alt currency check), casting (Crystalize Essence, Marked Passage, Buff Satchel wand) |
| `global_npc.pl` | All NPC events: spawn (tier loot randomization, mischief-style bonus loot), death (tome + gem drops, MoA combat hook, encounter scaling disengage), combat (dynamic encounter scaling engage/rescan), say (pet commands) |

## Custom Global NPCs

| NPC | File | Role |
|-----|------|------|
| Planeshifter Tyrael | `Planeshifter_Tyrael.pl` | Expedition NPC — can be placed in any zone, creates instanced expeditions for that zone. Copies a random local NPC appearance. Supports Sleeper's Tomb dual-mode (1.0 Warders / 2.0 Ancients) |
| Nyra Silvermark | `Nyra_Silvermark.pl` | Bazaar ↔ Guild Lobby transport shuttle. Context-aware destination based on current zone |

## Spell Scripts (`spells/`)

| Spell | File | Purpose |
|-------|------|---------|
| 26508 (Marked Passage) | `spells/26508.pl` | Bookmark teleport — first cast marks location and ports to Guild Lobby, second cast returns to marked spot (expedition-instance aware) |
| 27086 (Transmute Experience) | `spells/27086.pl` | AA-to-Lucky-Coin conversion — deducts 3 AA points, summons a Lucky Coin for Harley Wynn's gambling |

## Design Documentation

| File | Purpose |
|------|---------|
| `velious_dynamic_encounter_scaling_design_brief.md` | Design rationale and tuning goals for the dynamic encounter scaling system. Covers composition scoring, solo/group regimes, and stat modification approach |

## How Systems Connect

```
Player zones in
  → global_player.pl EVENT_ENTERZONE
    → ApplyAscendantAuras() — checks benediction timers, applies active buffs
    → MoA_StartOnlineTimer() — begins random 45-75min Mark award timer
    → Marked Passage bucket cleanup

Player kills NPC
  → global_npc.pl EVENT_DEATH
    → Illegible tome + gem drop rolls
    → MoA_TryCombatRoll() — 1-in-2000 chance for combat Mark

NPC spawns
  → global_npc.pl EVENT_SPAWN
    → GetLootList() tier randomization (base items → T1/T2/T3)
    → Mischief-style bonus loot (rare, common, raid)

NPC enters combat (Velious+ zones)
  → global_npc.pl EVENT_COMBAT
    → plugin::ScaleEncounter() — dynamic stat adjustment based on group composition
    → 12s rescan timer for upward-only mid-combat rescaling
```

## Author

Straps
