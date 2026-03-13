##############################################################################
# Common Mob Bonus Loot Plugin (Expansion-Aware)
##############################################################################
# Purpose: 1% chance for ANY mob to drop a bonus item from merged
#          expansion pools. Uses shared tier upgrade logic.
#
# Called from global_npc.pl:
#   plugin::common_mob_bonus_loot($npc, $npc_level, $zoneid);
##############################################################################

sub common_mob_bonus_loot {
    my $npc = shift;
    my $level = shift;
    my $zoneid = shift;

    # Configuration: 1% chance for bonus loot
    my $bonus_chance = 1;

    # Roll for bonus loot chance
    return unless (int(rand(100)) < $bonus_chance);

    # Get item pool for this level restricted to the zone's expansion
    my @item_pool = plugin::get_merged_pool($level, $zoneid);

    return if (scalar(@item_pool) == 0);

    # Select random item from pool
    my $selected_item = $item_pool[int(rand(scalar(@item_pool)))];

    # Get tier config and DB handle
    my $tier_cfg = plugin::common_tier_config();
    my $dbh = plugin::get_loot_dbh() if $tier_cfg->{enable};
    my $rare_count = 0;

    if ($tier_cfg->{enable} && $dbh) {
        $selected_item = plugin::roll_tier_upgrade($selected_item, $tier_cfg, \$rare_count, $dbh);
    }

    # Add the item
    $npc->AddItem($selected_item, 1);
    quest::debug("Common mob bonus loot: Added item $selected_item (NPC level $level)");
}

return 1;
