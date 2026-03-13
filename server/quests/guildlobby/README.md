# Ascendant EQ — Guild Lobby NPCs

The Guild Lobby (`guildlobby`, zone 344) is the central hub. All custom NPC scripts here provide the core server services players interact with daily.

## NPC Index

### Economy & Rewards
| NPC | File | Role |
|-----|------|------|
| Exarch Valeth | `Exarch_Valeth.pl` | Ascendant Benediction vendor — extends server-wide buffs (haste, healing, speed, thought) using Marks of Ascendance. Also sells Expedition Port Passes and trades Buff Bag Kits |
| Harley Wynn | `Harley_Wynn.pl` | Lucky Coin gambling — buy coins for plat, hand them in for tiered random prizes. Roll logic in `plugins/ascendant_gambling.pl` |
| Haliax Greycloak | `Haliax_Greycloak.pl` | AA credit display and redemption — shows per-class/per-tier credit grid, bulk or targeted redemption for unspent AA points. Also handles old tome buyback |

### Item Progression
| NPC | File | Role |
|-----|------|------|
| Khael the Spellforger | `Khael_the_Spellforger.pl` | Item tier upgrades — consumes an Ancient Shard + item to attempt base→T1→T2→T3 upgrade (70%/55%/35% success) |
| Morvain the Diminisher | `Morvain_the_Diminisher.pl` | Item tier downgrade — strips tiered items back to base form with lore safety checks |
| Aurelian Stoneward | `Aurelian_Stoneward.pl` | Expansion completion tracker — tracks raid boss kills per era (Classic/Kunark/Velious) and awards one-time rewards |

### AA Training (Insight System)
| NPC | File | Role |
|-----|------|------|
| 16 Guild Masters | `Alendar_Dawnsworn.pl` (and 15 others) | Shared script — auto-detects trainer class from NPC class ID. Handles tome turn-in, credit tracking, and AA purchasing via `plugins/ascendant_insight_trainer.pl` |

The guild masters all use identical scripts. NPC class 20-35 maps to player class 1-16 (`$npc->GetClass() - 19`). Deploy one copy per guild master NPC name.

**Guild Master NPCs**: Alendar Dawnsworn, Caldrin Azure, Elyndra Farwatch, Fenrick Lyresong, Grohm Spiritbinder, Karesh Wildsoul, Krag Bloodfury, Lyrielle Mindlace, Merion Valcrest, Mortivar Scholar, Shen Kai, Silas Quickveil, Thalwyn Rootseer, Tharok Ironbound, Velorin Ashweave, Vorath Duskblade

### Transportation
| NPC | File | Role |
|-----|------|------|
| Spirekeeper Aethen | `Spirekeeper_Aethen.pl` | Wizard spire teleporter — Classic + Kunark destinations, level-gated planar zones |
| Circlekeeper Aurin | `Circlekeeper_Aurin.pl` | Druid ring teleporter — Classic + Kunark destinations |
| Nyra Silvermark | (in `global/`) | Bazaar ↔ Guild Lobby shuttle |

Both porters also support expedition teleport for players with an Expedition Port Pass.

### Information & Utility
| NPC | File | Role |
|-----|------|------|
| Chronicler Elodin | `Chronicler_Elodin.pl` | Server guide — popup-based info on all major systems |
| The Temporary Reprieve | `the_temporary_reprieve.pl` | Refund vendor — claims pending tome/AA/plat refunds as Gold Tokens (alt currency 17) |
| Guardian Velldro | `Guardian_Velldro.pl` | Proximity signal NPC — triggers client signals on enter/exit for idle detection |

### Standard EQEmu NPCs
| NPC | File | Role |
|-----|------|------|
| A Corpse Harvester | `A_Corpse_Harvester.pl` | Corpse summon service |
| A Shrewd Banker | `A_Shrewd_Banker.pl` | Banking NPC |
| Tavid Dennant | `Tavid_Dennant.pl` | Standard NPC |

### Zone Player Script
| File | Role |
|------|------|
| `player.pl` | Handles guild lobby door clicks (guild hall entry), out-of-bounds respawn, and signal processing |

## Author

Straps
