# Khael the Spellforger - Item Tier Upgrade NPC (cshome)
# Author: Straps
#
# Mirror of guildlobby/Khael_the_Spellforger.pl — kept in sync.
# See that file for full documentation.

use strict;
use warnings;

# EQEmu globals (REQUIRED under strict)
our ($npc, $client, $text, %itemcount, $popupid);

# -------------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------------
my $SHARD_ID = 9600;

# Tier Offsets (Additive)
my $TIER_1_OFFSET = 300000;
my $TIER_2_OFFSET = 500000;
my $TIER_3_OFFSET = 700000;

# Upgrade Chances (Percentage 0-100)
my $CHANCE_BASE_TO_T1 = 70;
my $CHANCE_T1_TO_T2   = 55;
my $CHANCE_T2_TO_T3   = 35;

my $DETAILS_SAYLINK = quest::saylink("details", 1);

# -------------------------------------------------------------------------
# Helper: Identify Item Tier
# Returns: (tier_level, base_id)
# NOTE: Uses >= to avoid boundary edge cases
# -------------------------------------------------------------------------
sub get_item_tier_info {
    my ($item_id) = @_;

    if ($item_id >= $TIER_3_OFFSET) {
        return (3, $item_id - $TIER_3_OFFSET);
    }
    elsif ($item_id >= $TIER_2_OFFSET) {
        return (2, $item_id - $TIER_2_OFFSET);
    }
    elsif ($item_id >= $TIER_1_OFFSET) {
        return (1, $item_id - $TIER_1_OFFSET);
    }
    else {
        return (0, $item_id);
    }
}

sub EVENT_SAY {
    if ($text =~ /hail/i) {
        plugin::Whisper(
            "I am Khael the Spellforger. I force ancient ascendant power into items using shards long lost to time.\n\n".
            "If you possess an Ancient Shard of Ascendant Power, I may attempt an infusion.\n\n".
            "Say $DETAILS_SAYLINK if you wish to understand the risks."
        );
    }
    elsif ($text =~ /details/i) {
        show_details_popup();
    }
}

sub EVENT_ITEM {

    # Filter out invalid/empty item IDs
    my @valid_items = grep { $_ && $_ > 0 } keys %itemcount;

    # ---------------------------------------------------------------------
    # INFUSION REQUIREMENTS
    # Must be exactly 1 shard + 1 item (check quantities, not just types,
    # to prevent cursor-item duplication exploits)
    # ---------------------------------------------------------------------
    my $shard_count = $itemcount{$SHARD_ID} || 0;
    my $total_items = 0;
    $total_items += ($itemcount{$_} || 0) for @valid_items;

    unless (scalar(@valid_items) == 2 && $shard_count == 1 && $total_items == 2) {
        plugin::Whisper("I require exactly one Ancient Shard and one item to attempt an infusion. Nothing more, nothing less.");
        plugin::return_items(\%itemcount);
        return;
    }

    my ($other_item_id) = grep { $_ != $SHARD_ID } @valid_items;
    unless ($other_item_id) {
        plugin::return_items(\%itemcount);
        return;
    }

    my ($current_tier, $base_id) = get_item_tier_info($other_item_id);

    if ($current_tier >= 3) {
        plugin::Whisper("This item radiates with such intensity that I dare not touch it. It cannot be improved further.");
        plugin::return_items(\%itemcount);
        return;
    }

    my ($target_id, $chance);

    if ($current_tier == 0) {
        $target_id = $base_id + $TIER_1_OFFSET;
        $chance    = $CHANCE_BASE_TO_T1;
    }
    elsif ($current_tier == 1) {
        $target_id = $base_id + $TIER_2_OFFSET;
        $chance    = $CHANCE_T1_TO_T2;
    }
    else {
        $target_id = $base_id + $TIER_3_OFFSET;
        $chance    = $CHANCE_T2_TO_T3;
    }

    # ---------------------------------------------------------------------
    # HARD REJECT: upgraded item must exist
    # This prevents using Khael as a shredder for items that have no tier form.
    # ---------------------------------------------------------------------
    if (!$target_id || $target_id == $other_item_id) {
        plugin::Whisper("The shard finds no path forward for this item.");
        plugin::return_items(\%itemcount);
        return;
    }

    my $target_exists = quest::getitemstat($target_id, 'id');
    unless ($target_exists && $target_exists == $target_id) {
        plugin::Whisper("This item refuses the shard's power. It does not seem to have an ascendant form.");
        plugin::return_items(\%itemcount);
        return;
    }

    # ---------------------------------------------------------------------
    # LORE SAFETY (ITEM-SPECIFIC)
    # Refuse BEFORE consuming shard/item if the result would lore-fail.
    # QuestCheckLoreConflict checks worn, inventory, bank, shared bank,
    # and seated augments — CountItem does NOT check all of these.
    # ---------------------------------------------------------------------
    if ($client->CheckLoreConflict($target_id)) {
        plugin::Whisper("I will not attempt this infusion. You already possess the resulting item, and the lore would reject it.");
        plugin::return_items(\%itemcount);
        return;
    }

    # ---------------------------------------------------------------------
    # Consume items via engine-tracked check_handin (uses %itemcount so
    # the engine knows the items are consumed and won't auto-return them)
    # ---------------------------------------------------------------------
    unless (plugin::check_handin(\%itemcount, $SHARD_ID => 1, $other_item_id => 1)) {
        plugin::return_items(\%itemcount);
        return;
    }

    my $roll = int(rand(100)) + 1;

    # ---------------------------------------------------------------------
    # Success: shard + item consumed, give upgraded item
    # Failure: shard consumed (lost), return original item only
    # ---------------------------------------------------------------------
    if ($roll <= $chance) {
        my $verify = quest::getitemstat($target_id, 'id');
        if ($verify && $verify == $target_id) {
            $npc->Emote("channels raw magical energy into the item... it glows with a blinding light!");
            $client->SummonItem($target_id);
            plugin::Whisper("Success! The ascendant power has taken hold.");
        } else {
            quest::debug("[Khael] SAFETY: target_id=$target_id failed verify, returning items to " . $client->GetCleanName());
            $npc->Emote("channels raw magical energy... but something goes terribly wrong!");
            $client->SummonItem($other_item_id);
            $client->SummonItem($SHARD_ID);
            plugin::Whisper("The infusion was unstable. Your items have been returned.");
        }
    }
    else {
        $npc->Emote("channels raw magical energy... but the power destabilizes and dissipates!");
        $client->SummonItem($other_item_id);
        plugin::Whisper("Failure. The shard has shattered, but your item remains intact.");

        # Track upgrade failures for leaderboard
        my $charid = $client->CharacterID();
        my $fail_key = "leaderboard_upgrade_fails_${charid}";
        my $fails = int(quest::get_data($fail_key) || 0) + 1;
        quest::set_data($fail_key, $fails);

        my $name = $client->GetCleanName();

        # Milestone: 100 fails — "Officially Unlucky"
        if ($fails == 100) {
            quest::enabletitle(414);
            quest::we(15, "$name has failed 100 item upgrades at Khael the Spellforger. They are officially unlucky!");
        }
        # Milestone: 200 fails
        elsif ($fails == 200) {
            quest::enabletitle(415);
            quest::we(15, "$name has failed 200 item upgrades at Khael the Spellforger. Their bad luck is becoming legendary!");
        }
        # Milestone: 350 fails — "Legendary Failure"
        elsif ($fails == 350) {
            quest::enabletitle(412);
            quest::enabletitle(413);
            quest::we(15, "$name has failed 350 item upgrades at Khael the Spellforger. They have experienced a truly legendary amount of failure!");
        }
    }

    plugin::return_items(\%itemcount);
}

sub show_details_popup {
    my $popup_text = "<c \"#FFD700\">⚒ Khael the Spellforger ⚒</c><br><br>"
                   . "I use ancient spellcraft to <b>force ascendant power</b> into mortal items. "
                   . "This process is unstable — power does not always obey.<br><br>"
                   . "<c \"#00FFFF\"><b>Requirements</b></c><br>"
                   . "• One <c \"#FFD700\">Ancient Shard of Ascendant Power</c><br>"
                   . "• One item to infuse<br><br>"
                   . "<c \"#00FFFF\"><b>Upgrade Paths</b></c><br>"
                   . "Base → Tier I → Tier II → Tier III<br><br>"
                   . "<c \"#00FF00\"><b>Success</b></c><br>"
                   . "• Item ascends to the next tier<br>"
                   . "• Shard is consumed<br><br>"
                   . "<c \"#FF9900\"><b>Failure</b></c><br>"
                   . "• Shard is destroyed<br>"
                   . "• Item is returned intact<br><br>"
                   . "<c \"#FF5555\"><b>Warning</b></c><br>"
                   . "Ancient power is finite. Not all shards endure the binding.";

    $client->Popup2("Khael the Spellforger", $popup_text, 0, 0, 0, 0);
}

1;
