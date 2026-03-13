# Ascendant Tome Translator Plugin
# Author: Straps
#
# Maps class bitmasks to illegible tome item IDs across three tiers (Greater/Exalted/Ascendant).
# Multi-class tomes are keyed by combined bitmask so a single tome entry can serve
# multiple classes (e.g. Paladin+Shadowknight share certain melee AAs).
# Called by the Insight Trainer system when awarding random tomes for a class/tier.

sub GetRandomClassTome {
    my $class = shift;
    my $tier = shift;
    
    # Convert class number to bitmask
    my %class_to_bitmask = (
        1 => 1,      # Warrior
        2 => 2,      # Cleric
        3 => 4,      # Paladin
        4 => 8,      # Ranger
        5 => 16,     # Shadow Knight
        6 => 32,     # Druid
        7 => 64,     # Monk
        8 => 128,    # Bard
        9 => 256,    # Rogue
        10 => 512,   # Shaman
        11 => 1024,  # Necromancer
        12 => 2048,  # Wizard
        13 => 4096,  # Magician
        14 => 8192,  # Enchanter
        15 => 16384, # Beastlord
        16 => 32768, # Berserker
    );
    
    my $class_bitmask = $class_to_bitmask{$class};
    
    # Tome arrays by class bitmask and tier
    # Populated from aa_custom_mapping table
    # Format: $tomes{class_bitmask}{tier} = [array of tome_item_ids]
    
    my %tomes = ();
    
    # Balanced tome distribution — no duplicates, even per-class split
    # Per-class counts: WAR 6/6/5, CLR 5/5/5, PAL 6/6/5, RNG 5/4/4, SHD 7/7/7,
    #   DRU 4/4/4, MNK 5/5/4, BRD 4/4/3, ROG 2/2/2, SHM 4/3/3,
    #   NEC 6/6/6, WIZ 5/5/5, MAG 8/8/7, ENC 4/3/3, BST 6/5/5, BER 5/5/4
    # Forced T3: Dire Charm (all 3), Leech Touch, Soul Abrasion, Theft of Life

    # Tier 1 (Greater)
    $tomes{1}{1} = [121623];                            # Warrior (Area Taunt)
    $tomes{2}{1} = [121635, 121685, 121726, 121784];   # Cleric (Divine Retribution, Hastened Divinity, Sanctuary, Divine Avatar)
    $tomes{4}{1} = [121645, 121688];                    # Paladin (Holy Steed, Hastened Piety)
    $tomes{8}{1} = [121763, 121799];                    # Ranger (Archery Mastery, Guardian of the Forest)
    $tomes{9}{1} = [121747];                            # Warrior, Ranger (Strengthened Strike)
    $tomes{16}{1} = [121621, 121703];                   # Shadowknight (Abyssal Steed, Intense Hatred)
    $tomes{20}{1} = [121620, 121734, 121810];           # Paladin, Shadowknight (2 Hand Bash, Speed of the Knight, Knight's Advantage)
    $tomes{32}{1} = [121757];                           # Druid (Viscid Roots)
    $tomes{40}{1} = [121670];                           # Ranger, Druid (Entrap)
    $tomes{64}{1} = [121674, 121748, 121779];           # Monk (Eye Gouge, Strikethrough, Destructive Force)
    $tomes{128}{1} = [121680, 121791];                  # Bard (Fleet of Foot, Fading Memories)
    $tomes{448}{1} = [121657];                          # Monk, Bard, Rogue (Acrobatics)
    $tomes{512}{1} = [121690, 121756, 121770];          # Shaman (Hastened Rabidity, Virulent Paralysis, Cannibalization)
    $tomes{1024}{1} = [121627, 121722, 121792];         # Necromancer (Call to Corpse, Quickening of Death, Feigned Minion)
    $tomes{1026}{1} = [121647];                         # Cleric, Necromancer (Innate Invis to Undead)
    $tomes{2048}{1} = [121749, 121809, 121815];         # Wizard (Strong Root, Improved Familiar, Mind Crash)
    $tomes{2080}{1} = [121801];                         # Druid, Wizard (Hastened Exodus)
    $tomes{4096}{1} = [121641, 121666, 121788, 121804, 121807]; # Magician (Elem Form: Water, Elem Agility, Elem Fury, Heart of Ice, Host of Elements)
    $tomes{6176}{1} = [121822];                         # Druid, Wizard, Magician (Quick Damage)
    $tomes{8192}{1} = [121631, 121649, 121707, 121786]; # Enchanter (Color Shock, Permanent Illusion, Mind Over Matter, Doppelganger)
    $tomes{16384}{1} = [121697, 121766, 121816];        # Beastlord (Hobble of Spirits, Bestial Alignment, Paragon of Spirit)
    $tomes{21504}{1} = [121648];                        # Necromancer, Magician, Beastlord (Mend Companion)
    $tomes{22032}{1} = [121658];                        # Shadowknight, Shaman, Necromancer, Magician, Beastlord (Advanced Pet Discipline)
    $tomes{32768}{1} = [121624, 121637, 121753];        # Berserker (Blood Pact, Echoing Cries, Untamed Rage)
    $tomes{544}{1} = [121626];                          # Druid, Shaman (Call of the Wild)
    $tomes{32769}{1} = [121744, 121793, 121825];        # Warrior, Berserker (Stalwart Endurance, Flurry, Rampage)
    $tomes{49629}{1} = [121716];                        # Multi (Physical Enhancement)

    # Tier 2 (Exalted)
    $tomes{1}{2} = [121687, 121818, 121834];            # Warrior (Hastened Instigation, Planar Durability, Sturdiness)
    $tomes{2}{2} = [121628, 121654, 121689, 121752, 121785]; # Cleric (Celestial Hammer, Turn Undead, Hastened Purification, Touch of the Divine, Divine Resurrection)
    $tomes{4}{2} = [121622, 121656, 121718];            # Paladin (Act of Valor, Valiant Steed, Purification)
    $tomes{8}{2} = [121765, 121808];                    # Ranger (Auspice of the Hunter, Hunter's Attack Power)
    $tomes{16}{2} = [121655, 121774];                   # Shadowknight (Unholy Steed, Consumption of the Soul)
    $tomes{20}{2} = [121676, 121746];                   # Paladin, Shadowknight (Fearless, Steadfast Will)
    $tomes{32}{2} = [121669, 121833];                   # Druid (Enhanced Root, Spirit of the Wood)
    $tomes{40}{2} = [121646];                           # Ranger, Druid (Innate Camouflage)
    $tomes{64}{2} = [121644, 121698, 121750, 121826];   # Monk (Heightened Awareness, Imitate Death, Stunning Kick, Rapid Strikes)
    $tomes{128}{2} = [121625, 121729, 121797];          # Bard (Boastful Bellow, Shield of Notes, Furious Refrain)
    $tomes{256}{2} = [121650];                          # Rogue (Purge Poison)
    $tomes{512}{2} = [121762, 121824];                  # Shaman (Ancestral Aid, Rabid Bear)
    $tomes{1024}{2} = [121632, 121758, 121812];         # Necromancer (Dead Mesmerization, Wake the Dead, Life Burn)
    $tomes{1040}{2} = [121633];                         # Shadowknight, Necromancer (Death Peace)
    $tomes{2048}{2} = [121691, 121769, 121813, 121821]; # Wizard (Hastened Root, Call of Xuzl, Mana Blast, Prolonged Destruction)
    $tomes{2080}{2} = [121672];                         # Druid, Wizard (Exodus)
    $tomes{4096}{2} = [121639, 121642, 121667, 121794, 121805, 121823]; # Magician (Elem Form: Earth, Elem Pact, Elem Alacrity, Frenzied Burnout, Heart of Stone, Quick Summoning)
    $tomes{8192}{2} = [121686, 121733, 121787];         # Enchanter (Hastened Gathering, Soothing Words, Eldritch Rune)
    $tomes{16384}{2} = [121767, 121844];                # Beastlord (Bestial Frenzy, Warder's Alacrity)
    $tomes{16841}{2} = [121761];                        # Warrior, Ranger, Monk, Bard, Rogue, Beastlord (Ambidexterity)
    $tomes{21504}{2} = [121827];                        # Necromancer, Magician, Beastlord (Replenish Companion)
    $tomes{22032}{2} = [121715];                        # Shadowknight, Shaman, Necromancer, Magician, Beastlord (Pet Discipline)
    $tomes{32768}{2} = [121652, 121777];                # Berserker (Throwing Mastery, Dead Aim)
    $tomes{32769}{2} = [121708, 121836];                # Warrior, Berserker (Mithaniel's Binding, Tactical Mastery)
    $tomes{32788}{2} = [121817];                        # Paladin, Shadowknight, Berserker (Planar Durability)

    # Tier 3 (Ascendant)
    $tomes{1}{3} = [121759, 121820, 121846];            # Warrior (War Cry, Press the Attack, Warlord's Tenacity)
    $tomes{2}{3} = [121629, 121660, 121720, 121783, 121790]; # Cleric (Celestial Regeneration, Bestow Divine Aura, Purify Soul, Divine Arbitration, Exquisite Benediction)
    $tomes{4}{3} = [121636, 121683, 121731];            # Paladin (Divine Stun, Hand of Piety, Slay Undead)
    $tomes{8}{3} = [121630, 121789, 121819];            # Ranger (Coat of Thistles, Endless Quiver, Precision of the Pathfinder)
    $tomes{16}{3} = [121811, 121831, 121839];           # Shadowknight (Leech Touch, Soul Abrasion, Touch of the Cursed)
    $tomes{20}{3} = [121699, 121755];                   # Paladin, Shadowknight (Immobilizing Bash, Vicious Smash)
    $tomes{32}{3} = [121711, 121781, 121847];           # Druid (Nature's Boon, Dire Charm, Wrath of the Wild)
    $tomes{64}{3} = [121719, 121775, 121837];           # Monk (Purify Body, Crippling Strike, Technique of Master Wu)
    $tomes{128}{3} = [121776, 121800];                  # Bard (Dance of Blades, Harmonious Attack)
    $tomes{256}{3} = [121671];                          # Rogue (Escape)
    $tomes{512}{3} = [121743, 121768, 121832];          # Shaman (Spiritual Channeling, Call of the Ancients, Spirit Call)
    $tomes{1024}{3} = [121675, 121764, 121782, 121835]; # Necromancer (Fear Storm, Army of the Dead, Dire Charm, Swarm of Decay)
    $tomes{1040}{3} = [121778, 121838];                 # Shadowknight, Necromancer (Death's Fury, Theft of Life)
    $tomes{2048}{3} = [121738, 121795, 121814, 121843]; # Wizard (Spell Casting Fury Mastery, Frenzied Devastation, Mana Burn, Ward of Destruction)
    $tomes{2080}{3} = [121721];                         # Druid, Wizard (Quick Evacuation)
    $tomes{4096}{3} = [121638, 121640, 121653, 121668, 121803, 121806, 121829]; # Magician (Elem Form: Air, Elem Form: Fire, Turn Summoned, Elem Durability, Heart of Flames, Heart of Vapor, Servant of Ro)
    $tomes{8192}{3} = [121745, 121780, 121798];         # Enchanter (Stasis, Dire Charm, Gather Mana)
    $tomes{16384}{3} = [121677, 121725, 121796, 121845]; # Beastlord (Feral Swipe, Roar of Thunder, Frenzy of Spirit, Warder's Fury)
    $tomes{16841}{3} = [121830];                        # Warrior, Ranger, Monk, Bard, Rogue, Beastlord (Sinister Strikes)
    $tomes{32768}{3} = [121634, 121692, 121828];        # Berserker (Desperation, Hastened War Cry, Savage Spirit)
    $tomes{32769}{3} = [121802];                        # Warrior, Berserker (Hastened Rampage)
        
    # Collect all tomes that match this class and tier
    # Check both exact class match AND multi-class tomes that include this class
    my @available_tomes = ();
    
    foreach my $tome_bitmask (keys %tomes) {
        # Check if this tier exists for this bitmask
        if (exists $tomes{$tome_bitmask}{$tier}) {
            # Check if the class bitmask includes our class (bitwise AND)
            if (($tome_bitmask & $class_bitmask) == $class_bitmask) {
                # This tome is usable by our class, add all tomes from this bitmask/tier
                push @available_tomes, @{$tomes{$tome_bitmask}{$tier}};
            }
        }
    }
    
    # Return random tome from available tomes
    if (scalar @available_tomes > 0) {
        my $random_index = int(rand(scalar @available_tomes));
        return $available_tomes[$random_index];
    }
    
    # No tomes found for this class/tier
    return 0;
}

return 1;
