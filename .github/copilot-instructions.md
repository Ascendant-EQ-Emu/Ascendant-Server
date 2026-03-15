# Copilot Review Instructions

When reviewing pull requests for this repository, prioritize **server stability, gameplay correctness, exploit prevention, and backward compatibility** over style preferences.

## Primary Review Priorities

Focus on:

- Server crashes, null dereferences, invalid pointers, unsafe casts, and memory safety issues
- Logic that could cause **zone-wide impact**, mass disconnects, item loss, dupes, corrupted state, or unintended rewards
- Changes that could introduce **exploits**, especially around:
  - item creation or duplication
  - parcel/mail systems
  - trade systems
  - currency handling
  - quest turn-ins
  - NPC hand-ins
  - merchant purchases
  - loot distribution
  - database write paths
  - account/login flows
- Regressions that could break classic EQEmu behavior or existing custom content
- Performance risks in hot paths such as:
  - combat
  - hate list processing
  - movement
  - entity iteration
  - quest/global event processing
  - zone boot or world login flows

## Repository Context

This repository is for a custom EQEmu server with live gameplay implications.

When reviewing, assume:

- Small bugs can become player-facing exploits
- Silent failures are dangerous
- Backward compatibility matters for existing database content, quests, and scripts
- Many systems are interconnected across:
  - C++ server code
  - Perl/Lua quest scripts
  - SQL/database schema or content
  - rules and configuration
  - login/world/zone interactions

## C++ Review Guidance

Be especially strict on:

- Null handling and pointer safety
- Bounds checks and container safety
- Use-after-free or invalid object lifetime assumptions
- Thread-safety or shared-state assumptions where relevant
- Missing validation on client-driven values
- Integer overflow, underflow, signed/unsigned mismatches
- Unsafe assumptions around IDs, counts, slot values, charges, stack sizes, or quantities
- Error handling for database queries, packet parsing, and state transitions
- Logic that can be triggered repeatedly without guardrails

When reviewing gameplay code, check whether the change could unintentionally affect:

- all clients in zone
- all NPCs
- pets
- raid/group members
- expedition or instance members
- aggro/hate calculations
- item reward loops
- AA, XP, faction, or currency gains

## Quest Script Review Guidance

For Perl or Lua quest scripts, focus on:

- Missing validation of turn-ins, hand-ins, quantities, item IDs, and character state
- Reward duplication or repeatable abuse
- Global or zone-wide side effects
- Timer misuse or event loops that may spam or hang
- Unchecked assumptions about entity existence, client validity, or NPC state
- Hand-in logic that could accept null, zero, or malformed values
- Item, currency, AA, title, or flag rewards without proper gating
- Inconsistent cleanup of globals, data buckets, or quest state

Call out any script that could be abused by relogging, trading, zoning, multi-questing, or packet timing.

## Database / SQL Review Guidance

Be strict on:

- Unsafe query construction
- Missing escaping or parameterization
- Updates/inserts that may affect more rows than intended
- Incorrect joins that could duplicate rewards or corrupt state
- Migration changes that break existing server content
- Schema assumptions that may not hold on existing databases
- Changes to loot, merchants, spawn tables, hand-ins, or progression flags that could have broad live impact

If a change touches currency, inventory, parcels, loot, or character data, review it as high risk.

## Gameplay / Design Awareness

When reviewing gameplay-related PRs, check for unintended impacts to:

- progression pacing
- class balance
- custom AAs
- skill caps
- combat formulas
- pet behavior
- loot rarity
- raid targets
- instance access
- progression flags
- alt currency or donation-linked systems

Flag changes that appear technically valid but would likely create imbalance, trivialize content, or bypass intended progression.

## Preferred Review Style

Prefer concise, high-signal comments that include:

1. the issue
2. why it matters in an EQEmu/live-server context
3. a suggested fix or safer alternative

Good comments should focus on correctness, exploitability, stability, and maintainability.

## Deprioritize

Do not focus heavily on minor style or formatting issues unless they affect:

- readability
- correctness
- maintainability
- debugging
- consistency in a sensitive subsystem

## Extra Attention Areas

Pay extra attention to PRs touching:

- inventory
- trading
- parcels
- quests
- loot
- merchants
- spells
- combat
- pets
- instances / dynamic zones
- loginserver / account linking
- character saves
- rules
- data buckets
- alt currency
- reward systems
- packet handling
- database repositories

## Exploit Review Bias

Review suspiciously whenever a PR involves:

- quantities
- charges
- stack merges or splits
- item deletion or creation
- hand-ins
- duplicate callbacks
- repeated event triggers
- client-provided values
- missing transaction boundaries
- reward logic without idempotency checks

Assume players may intentionally try edge cases.

## Final Review Heuristic

Ask:

- Can this crash a server process?
- Can this be exploited by players?
- Can this duplicate items, currency, or rewards?
- Can this affect more players than intended?
- Can this silently corrupt character or world state?
- Can this break existing custom content or progression?
- Is there a safer, more defensive implementation?

If yes, call it out clearly.
