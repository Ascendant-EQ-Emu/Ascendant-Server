# Velious Dynamic Encounter Scaling Design Brief

## Objective

Design a **dynamic encounter scaling system** for Velious raid and named content that preserves each NPC’s original identity while making encounters generally **solo/duo-able** for a wide range of classes and compositions.

The system should:

- keep harder mobs harder than easier mobs
- avoid permanent database rewrites of Velious NPC stats
- use contextual information at engage/combat time
- help weaker solo/duo compositions without trivializing content
- become somewhat harder for larger groups or raids
- be resistant to simple player exploits

---

## Core Design Principles

### 1. Preserve NPC identity
Do not replace the NPC with generic stats. The system should scale **from the NPC’s original values**, not overwrite them with universal targets.

Examples:
- scaled HP = original HP × multiplier
- scaled max hit = original max hit × multiplier
- scaled ATK = original ATK × multiplier
- scaled resist = original resist + delta

This ensures strong Velious raid mobs still feel stronger than weaker Velious targets.

### 2. Do not permanently retune the database
Avoid solving this by globally lowering Velious mobs in the DB. Instead, apply scaling dynamically through encounter logic at spawn, aggro, or combat-time hooks.

### 3. Do not scale from everyone in zone
Do not use total zone population as the primary input. That is easy to manipulate with:
- parked alts
- AFK players
- dead players
- people zoning through
- players stepping in and out to influence difficulty

Scale based on **actual encounter participants** only.

### 4. Do not scale from gear inspection
Avoid querying inventory, weapon damage, or current gear as the main balancing model. It is noisy, hard to tune, and weakens the sense of progression. Use **class/archetype capability** instead.

### 5. Keep the number of modified stats small
For v1, only modify the most important and stable encounter knobs. Avoid changing too many combat variables at once.

---

## High-Level Model

Each encounter consists of:

1. **Base NPC identity** from the database
2. **Encounter profile** assigned to the NPC
3. **Participant scan** at engage time
4. **Dynamic scaling package** computed from the attacking composition
5. **Optional upward-only rescan** during combat if additional participants join

---

## Encounter Profiles

Each eligible Velious NPC should be assigned one encounter profile.

### Bruiser
Used for melee-centric raid or named bosses.

Primary scaling levers:
- HP
- min hit
- max hit
- ATK
- optionally accuracy

### Caster
Used for spell-heavy, AE-heavy, or resist-intensive bosses.

Primary scaling levers:
- HP
- resists
- spell/AE pressure
- possibly some incoming melee reduction

### Hybrid
Used for bosses with both meaningful melee and spell pressure.

Primary scaling levers:
- HP
- min/max hit
- ATK
- moderate resist adjustments

---

## Participant Detection Rules

At engage time, identify the **active encounter participants**.

Include:
- the top aggro player
- players on the hate list
- nearby group or raid members within a defined encounter radius
- pet owners
- possibly players providing meaningful healing/support to those on hate

Do not include:
- random players elsewhere in the zone
- dead or AFK characters not contributing
- parked alts outside the encounter area

---

## Scaling Lifecycle

### On Spawn
- initialize encounter state
- assign or load encounter profile
- mark NPC as not yet scaled

### On Aggro
- gather active participants
- compute composition scores
- snapshot original NPC stats
- apply scaling package
- mark encounter as scaled

### During Combat
- every 10–15 seconds:
  - rescan active participants
  - if more real participants joined, modestly increase difficulty
  - do **not** lower difficulty mid-fight

### On Reset / Wipe / Death
- clear encounter state
- allow next engage to recompute scaling fresh

---

## Composition Scoring Model

Do not balance around exact items or character gear. Balance around the kind of team engaging the encounter.

Use these dimensions:

- **Durability**
- **Sustain**
- **Damage pressure**
- **Fragile caster presence**

These scores represent what the participants are likely able to handle.

---

## Example Class Weights

These are starting weights for tuning, not final truth.

### Durability
- Warrior / Shadowknight / Paladin / Monk = 1.00
- Ranger / Rogue / Beastlord / Bard = 0.80
- Cleric / Shaman / Druid = 0.70
- Mage / Necro = 0.60
- Enchanter / Wizard = 0.45

### Sustain
- Cleric = 1.00
- Shaman / Necro = 0.85
- Druid / Paladin / Shadowknight = 0.75
- Mage / Beastlord / Bard = 0.55
- Monk / Rogue / Wizard / Enchanter = 0.35
- Warrior = 0.20

### Damage Pressure
- Monk / Rogue / Wizard / Mage / Necro = 0.95
- Ranger / Beastlord / Shadowknight = 0.80
- Paladin / Shaman / Enchanter / Bard = 0.60
- Cleric / Warrior / Druid = 0.45

---

## Example Synergy Bonuses

Apply modest synergy bumps for particularly stable or effective compositions.

Examples:
- tank + healer = +0.15
- pet class + healer = +0.10
- monk + shaman = +0.12
- fragile caster solo = fragile flag
- fragile caster duo = partial fragile flag

These bonuses should help the scaling engine recognize that some duos are dramatically stronger than their individual classes imply.

---

## Outputs the Scaling Engine Should Produce

The engine should compute three main outputs.

### 1. Survival Pressure
Determines whether the participant(s) can survive the encounter.

Primary stats to adjust:
- `min_hit`
- `max_hit`
- `atk`
- optionally `accuracy`

### 2. Time-to-Kill Pressure
Determines whether the encounter length is reasonable for the composition.

Primary stats to adjust:
- `max_hp`
- optionally `ac`

### 3. Caster Viability
Determines whether fragile caster-oriented comps can realistically function.

Primary stats to adjust:
- magic resist
- fire resist
- cold resist
- poison resist
- disease resist
- optionally spell/AE cadence for caster bosses

---

## Preferred Stats to Modify in v1

### Use these first
- max HP
- min hit
- max hit
- ATK
- resist deltas

### Possible later additions
- accuracy
- spell cadence
- AE cadence
- regen

### Avoid in v1
Avoid unless absolutely necessary:
- level changes
- attack delay changes
- heavy special ability rewrites
- gear-based scaling formulas

---

## Desired Encounter Behavior by Composition

### Solo fragile caster
Should receive:
- noticeably lower boss HP
- significantly reduced incoming spike damage
- meaningfully reduced resists
- possibly lighter spell/AE pressure on caster bosses

### Solo sturdy melee
Should receive:
- moderate reductions only
- enough challenge to still feel meaningful
- less assistance on incoming melee than fragile casters receive

### Strong duo with sustain
Should receive:
- close to intended “good duo challenge”
- only moderate scaling relief

### Larger group or raid
Should receive:
- modest upward HP scaling
- modest upward damage scaling
- little or no resist reduction

---

## Example Outcome Philosophy

These values are examples of intent, not final balance numbers.

### Monk solo
- HP: 80% of stock
- max hit: 85% of stock
- resists: near stock

### Wizard solo
- HP: 65% of stock
- max hit: 55% of stock
- resists: significantly lowered

### Monk + Shaman
- HP: 90% of stock
- max hit: 90% of stock
- resists: slight reduction

### Warrior + Cleric
- HP: 100% of stock
- max hit: 92% of stock
- resists: stock or very slight reduction

### Full group / raid
- HP: 110–140% of stock
- max hit: 100–115% of stock
- resists: stock or slightly higher

---

## Formula Design Guidance

Use clamped multipliers and deltas.

### Inputs
- encounter profile
- participant count
- durability score
- sustain score
- damage score
- fragile caster flag

### Outputs
- HP multiplier
- melee damage multiplier
- ATK multiplier
- resist delta package

### General tuning logic
- HP should be driven mostly by **damage pressure** and **participant count**
- incoming melee should be driven mostly by **durability** and **sustain**
- resist reductions should be driven mostly by **fragile caster presence**

The system should be conservative, stable, and easy to tune.

---

## Anti-Exploit Rules

### 1. Lock scaling on engage
Once the encounter meaningfully starts, snapshot the composition and apply the initial scale.

### 2. Only allow upward changes during combat
If additional players truly join the encounter, the NPC may scale upward modestly. If players leave, the NPC should **not** scale downward until reset.

### 3. Count only real participants
Only count nearby players, hate participants, pet owners, or meaningful support actions.

### 4. Ignore total zone population
Do not let raw zone population influence normal encounter difficulty.

### 5. Do not balance around gear inspection
Gear-based scaling is too noisy and too easy to distort.

---

## Recommended Architecture

### Data / Configuration Layer
Use data-driven configuration for:
- eligible NPCs
- encounter profile assignments
- class/archetype weights
- synergy bonuses
- scaling caps and clamps
- optional per-NPC overrides

### Runtime Encounter State
For each active encounter, track:
- original HP
- original min hit
- original max hit
- original ATK
- original resist values
- encounter profile
- whether scaling has been applied
- participant count
- current scale tier or scale package

---

## Suggested Initial Scope

Start with a narrow v1.

### Apply to
- Velious raid bosses
- Velious key named encounters
- not all trash mobs initially

### v1 scaling knobs
- max HP
- min hit
- max hit
- ATK
- resist deltas

### v1 behavior
- detect encounter participants
- compute composition scores
- apply one-time engage scaling
- optionally rescan upward only during combat

---

## Development Phases

### Phase 1 — Framework
Build:
- encounter state storage
- participant scan logic
- profile assignment system
- original-stat snapshot logic

### Phase 2 — Scaling Engine
Implement:
- class/archetype weight tables
- durability/sustain/damage scoring
- synergy bonuses
- scaling formulas
- stat application via dynamic NPC modification

### Phase 3 — Encounter Locking and Rescans
Add:
- engage lock
- upward-only combat rescans
- wipe/reset/death cleanup

### Phase 4 — Tuning
Tune against representative solo and duo comps, especially:
- sturdy melee solo
- fragile caster solo
- common strong duos
- full group / raid cases

### Phase 5 — Expansion
Optionally expand to:
- more named mobs
- per-NPC overrides
- caster boss spell cadence adjustments
- special cases for outlier encounters

---

## Testing Plan

Test against multiple Velious bosses using representative compositions.

### Solo
- Monk
- Shadowknight
- Cleric
- Wizard
- Mage
- Necro
- Enchanter

### Duos
- Monk + Shaman
- Warrior + Cleric
- Mage + Cleric
- Necro + Shaman
- Paladin + Druid
- Enchanter + Cleric

### Group / Raid
- melee-heavy group
- caster-heavy group
- mixed raid

### Measure
- survivability
- fight length
- caster viability
- whether the boss still feels like itself
- whether the scaling is easy to cheese
- whether stronger comps remain meaningfully advantaged

---

## Success Criteria

The system is successful if:

- most intended Velious raid/named encounters become realistically solo/duo-able
- fragile classes receive meaningful help without trivializing the content
- stronger classes and stronger duos still feel stronger
- raids do not instantly flatten content
- hard mobs remain harder than easier mobs
- the system is stable, tunable, and not easy to exploit
- future tuning can happen through config changes instead of constant script rewrites

---

## Implementation Expectations for the Coding AI

The implementation should aim for:

- a reusable shared scaling engine
- minimal per-NPC script duplication
- data-driven encounter profiles
- data-driven class/archetype weights
- scaling from original NPC values
- clear separation between:
  - participant detection
  - scoring
  - multiplier calculation
  - stat application
  - encounter state management

The coding AI should determine the concrete code design and scripting details, but the above behavior and constraints should guide implementation.

---

## Concise Summary

Build a dynamic Velious encounter scaling system that preserves each NPC’s original identity while making raid and named encounters solo/duo-able by applying encounter-time stat adjustments based on the actual participants engaging the NPC. Use archetype-based scoring for durability, sustain, damage, and fragile caster presence; assign each NPC a bruiser/caster/hybrid profile; and adjust only a small set of core stats in v1 (HP, min/max hit, ATK, resists). Lock the initial scale on engage, allow only upward adjustments if more real participants join, and always scale from the mob’s original values so stronger bosses remain stronger than weaker ones.
