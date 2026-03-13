# Ascendant EQ - Buff Satchel System
# 6-slot container that stores buff scrolls, activated by clicking the Ascendant Buff Wand
# Scrolls are attunable (tradeable until first use, then no-drop)

package plugin;

use strict;
use warnings;

# Item IDs
my $BUFF_SATCHEL_ID = 17672;
my $BUFF_WAND_SPELL_ID = 17782;  # "Go, Go, Ascendant Buff Bag!"

my $CRYSTALIZE_COOLDOWN_SEC = 21600;  # 6 hours
my $CRYSTALIZE_XP_COST_PCT  = 0.65;   # 65% of current level's XP
my $CRYSTALIZE_MIN_LEVEL     = 50;

# Crystalize Essence spell ID => scroll item ID it creates
my %FORGE_SPELLS = (
    26716 => 17665,  # Crystalize Essence: Aegolism       => Ascendant Scroll: Aegolism
    26717 => 17666,  # Crystalize Essence: Chloroplast     => Ascendant Scroll: Chloroplast
    26718 => 17667,  # Crystalize Essence: Focus           => Ascendant Scroll: Focus
    26719 => 17668,  # Crystalize Essence: Clarity         => Ascendant Scroll: Clarity
    26720 => 17669,  # Crystalize Essence: Damage Shield   => Ascendant Scroll: Damage Shield
    26721 => 17670,  # Crystalize Essence: Dead Man Floating => Ascendant Scroll: Dead Man Floating
    26722 => 17671,  # Crystalize Essence: Strength of Nature => Ascendant Scroll: Strength of Nature
);

# Scroll item ID => buff spell ID
my %SCROLL_SPELLS = (
    17665 => 1447,   # Ascendant Scroll: Aegolism       (Cleric)
    17666 => 145,    # Ascendant Scroll: Chloroplast     (Druid)
    17667 => 1432,   # Ascendant Scroll: Focus           (Shaman)
    17668 => 1693,   # Ascendant Scroll: Clarity         (Enchanter)
    17669 => 412,    # Ascendant Scroll: Damage Shield   (Magician)
    17670 => 457,    # Ascendant Scroll: Dead Man Floating (Necromancer)
    17671 => 1397,   # Ascendant Scroll: Strength of Nature (Ranger)
);

# Scroll item ID => display name (for messages)
my %SCROLL_NAMES = (
    17665 => 'Aegolism',
    17666 => 'Chloroplast',
    17667 => 'Focus of Spirit',
    17668 => 'Clarity II',
    17669 => 'Shield of Lava',
    17670 => 'Dead Man Floating',
    17671 => 'Strength of Nature',
);

sub GetSatchelClaspSpellID {
    return $BUFF_WAND_SPELL_ID;
}

sub ApplyBuffsFromSatchel {
    my $client = shift;
    return unless $client;

    my $satchel = FindBuffSatchel($client);
    unless ($satchel) {
        $client->Message(13, "You do not have an Ascendant Buff Satchel in your inventory or bank.");
        return;
    }

    my $applied = 0;

    for my $slot (0..5) {
        my $item = $satchel->GetItem($slot);
        next unless $item;

        my $item_id = $item->GetID();
        my $spell_id = $SCROLL_SPELLS{$item_id};
        next unless $spell_id;

        my $buff_name = $SCROLL_NAMES{$item_id} || "Unknown Buff";

        # Apply the buff at level 50, duration 3600 (60 minutes)
        $client->ApplySpell($spell_id, 3600, 50, 0, 0);
        my $pet = $client->GetPet();
        if ($pet) {
            $pet->ApplySpellBuff($spell_id, 3600, 50);
        }
        $client->Message(18, "Your satchel pulses with power... $buff_name applied!");
        $applied++;
    }

    if ($applied == 0) {
        $client->Message(13, "Your Ascendant Buff Satchel contains no valid scrolls.");
    } else {
        $client->Message(18, "Ascendant Buff Satchel applied $applied buff(s)!");
    }

    return $applied;
}

sub FindBuffSatchel {
    my $client = shift;

    # Search general inventory slots (23-32)
    for my $slot (23..32) {
        my $item = $client->GetItemAt($slot);
        next unless $item;
        if ($item->GetID() == $BUFF_SATCHEL_ID) {
            return $item;
        }
    }

    # Search bank slots (2000-2023)
    for my $slot (2000..2023) {
        my $item = $client->GetItemAt($slot);
        next unless $item;
        if ($item->GetID() == $BUFF_SATCHEL_ID) {
            return $item;
        }
    }

    return undef;
}

sub IsCrystalizeSpell {
    my $sid = shift;
    return exists $FORGE_SPELLS{$sid};
}

sub CrystalizeEssence {
    my ($client, $spell_id) = @_;
    return unless $client;

    my $scroll_id = $FORGE_SPELLS{$spell_id};
    return unless $scroll_id;

    my $name = $client->GetCleanName();
    my $level = $client->GetLevel();

    # Level check
    if ($level < $CRYSTALIZE_MIN_LEVEL) {
        $client->Message(13, "You must be at least level $CRYSTALIZE_MIN_LEVEL to crystalize essence.");
        return;
    }

    # Cooldown check
    my $cd_key = "crystalize_essence_" . $client->CharacterID();
    my $on_cd = quest::get_data($cd_key);
    if ($on_cd) {
        $client->Message(13, "Your essence is still recovering. You cannot crystalize again yet.");
        return;
    }

    # XP cost: 65% of the XP band for the current level only
    my $current_exp = $client->GetEXP();
    my $level_start = $client->GetEXPForLevel($level);
    my $level_end   = $client->GetEXPForLevel($level + 1);
    my $level_band  = $level_end - $level_start;
    my $cost        = int($level_band * $CRYSTALIZE_XP_COST_PCT);
    my $new_exp     = $current_exp - $cost;

    # Preserve AA XP, SetEXP handles de-leveling automatically
    $client->SetEXP($new_exp, $client->GetAAExp());

    # Summon the scroll
    $client->SummonItem($scroll_id);

    # Start cooldown
    quest::set_data($cd_key, "1", $CRYSTALIZE_COOLDOWN_SEC);

    # Get scroll name for message
    my $scroll_name = $SCROLL_NAMES{$scroll_id} || "Unknown";
    $client->Message(18, "You focus your essence and crystalize a scroll of $scroll_name!");
    $client->Message(13, "The effort drains you of significant experience.");
}

return 1;
