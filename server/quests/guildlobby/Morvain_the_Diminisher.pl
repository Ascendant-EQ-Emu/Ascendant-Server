# Morvain the Diminisher - Tier Downgrade NPC (Guild Lobby)
# Author: Straps
#
# Strips a tiered item back to its base form. Uses the same tier offset math
# as Khael the Spellforger (300k/500k/700k). Refuses if the player already
# owns the base item (lore conflict) or if no base-form item exists in the DB.

use strict;
use warnings;

our ($npc, $client, $text, %itemcount);

# Tier offsets
my $TIER_1_OFFSET = 300000;
my $TIER_2_OFFSET = 500000;
my $TIER_3_OFFSET = 700000;

# Returns (tier, base_id). tier 0 means "not tiered"
sub get_item_tier_info {
    my ($item_id) = @_;

    # Check highest first
    if ($item_id >= $TIER_3_OFFSET) {
        return (3, $item_id - $TIER_3_OFFSET);
    }
    elsif ($item_id >= $TIER_2_OFFSET) {
        return (2, $item_id - $TIER_2_OFFSET);
    }
    elsif ($item_id >= $TIER_1_OFFSET) {
        return (1, $item_id - $TIER_1_OFFSET);
    }

    return (0, $item_id);
}

sub EVENT_SAY {
    if ($text =~ /hail/i) {
        plugin::Whisper(
            "I am Morvail the Diminisher. Hand me an ascendant item and I will strip it back to its base form.\n" .
            "If restoring it would create a lore conflict, I will refuse and return it."
        );
    }
}

sub EVENT_ITEM {

    # Must be exactly one item
    my @valid_items = grep { $_ && $_ > 0 } keys %itemcount;

    if (scalar(@valid_items) != 1) {
        plugin::Whisper("One item at a time.");
        plugin::return_items(\%itemcount);
        return;
    }

    my $item_id = $valid_items[0];

    # Determine tier/base
    my ($tier, $base_id) = get_item_tier_info($item_id);

    if ($tier == 0) {
        plugin::Whisper("That item has no tiered ascendance for me to remove.");
        plugin::return_items(\%itemcount);
        return;
    }

    # Verify base item exists in DB
    my $base_name = quest::getitemname($base_id);
    unless ($base_name) {
        plugin::Whisper("I cannot find the original form of this item. I will not risk destroying it.");
        plugin::return_items(\%itemcount);
        return;
    }

    # Lore safety (practical): if they already have the base item anywhere, refuse
    # This prevents creating a lore error when summoning the base.
    if ($client->CheckLoreConflict($base_id)) {
        plugin::Whisper("I will not do this. You already possess the base item and this would create a lore problem.");
        plugin::return_items(\%itemcount);
        return;
    }

    # Consume the tier item (handin) and then give base item
    unless (quest::handin(\%itemcount)) {
        plugin::return_items(\%itemcount);
        return;
    }

    $npc->Emote("drains the ascendant power away, leaving only the item’s original form.");

    $client->SummonItem($base_id);
    plugin::Whisper("Done. Your item has been restored.");
}

1;
