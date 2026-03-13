##############################################################################
# Rare/Named Mob Bonus Loot Plugin (Expansion-Aware)
##############################################################################
# Purpose: Guaranteed bonus loot for rare/named spawns from merged
#          expansion pools. Uses shared tier upgrade logic.
#
# Called from global_npc.pl:
#   plugin::rare_levelblock_loot($npc, $npc_level, $zoneid);
##############################################################################

sub rare_levelblock_loot {
    my $npc = shift;
    my $level = shift;
    my $zoneid = shift;

    # Configuration: Drop chances
    my $first_item_chance = 100;   # 100% = always drop 1 item
    my $second_item_chance = 25;   # 25% chance for a 2nd item

    # Get item pool for this level restricted to the zone's expansion
    my @item_pool = plugin::get_merged_pool($level, $zoneid);

    return if (scalar(@item_pool) == 0);

    # Get tier config and DB handle
    my $tier_cfg = plugin::rare_tier_config();
    my $dbh;
    $dbh = plugin::get_loot_dbh() if $tier_cfg->{enable};
    my $rare_item_upgraded = 0;

    # First item drop (guaranteed if chance = 100)
    if (int(rand(100)) < $first_item_chance) {
        my $selected_item = $item_pool[int(rand(scalar(@item_pool)))];

        if ($tier_cfg->{enable} && $dbh) {
            $selected_item = plugin::roll_tier_upgrade($selected_item, $tier_cfg, \$rare_item_upgraded, $dbh);
        }

        $npc->AddItem($selected_item, 1);
        quest::debug("Mischief bonus loot: Added item $selected_item (NPC level $level)");
    }

    # Second item drop (optional, based on second_item_chance)
    if (int(rand(100)) < $second_item_chance) {
        my $selected_item = $item_pool[int(rand(scalar(@item_pool)))];

        if ($tier_cfg->{enable} && $dbh) {
            $selected_item = plugin::roll_tier_upgrade($selected_item, $tier_cfg, \$rare_item_upgraded, $dbh);
        }

        $npc->AddItem($selected_item, 1);
        quest::debug("Mischief bonus loot: Added 2nd item $selected_item (NPC level $level)");
    }
}

my @kunark_shaman_spells = (
    7722, 66221, 7725, 66220, 19537, 19538, 7728, 7734, 7724,
    19530, 7721, 7731, 7727, 7723, 19531, 7741, 7739, 7740,
    7726, 19200, 19498, 7729, 19499, 7730, 7720
);

sub kunark_spell_bonus_loot {
    my ($npc, $level, $zoneid) = @_;

    return unless $level > 50;

    my $kunark_zones = plugin::kunark_zone_ids();
    return unless $kunark_zones->{$zoneid};

    # 1 in 15 chance
    return unless int(rand(15)) == 0;

    my $selected = $kunark_shaman_spells[int(rand(scalar(@kunark_shaman_spells)))];
    $npc->AddItem($selected, 1);
    quest::debug("Kunark spell bonus loot: Added item $selected (NPC level $level, zone $zoneid)");
}

return 1;
