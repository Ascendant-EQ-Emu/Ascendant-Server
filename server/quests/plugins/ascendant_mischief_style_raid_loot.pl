##############################################################################
# Raid Boss Mischief-Style Loot Plugin (Expansion-Aware)
##############################################################################
# Purpose: Add 2-3 bonus items from shared raid boss loot pool.
#          Merges raid configs from all active expansions.
#          Supports per-boss raid groups (boss drops from its group's pool).
#
# Called from global_npc.pl in EVENT_SPAWN:
#   plugin::raid_boss_bonus_loot($npc, $zoneid);
##############################################################################

sub raid_boss_bonus_loot {
    my $npc = shift;
    my $zoneid = shift;

    return unless $npc;
    return unless $zoneid;

    # Get merged raid config from all active expansions
    my $raid_cfg = plugin::get_merged_raid_config();

    # Check if we're in a raid zone
    return unless exists $raid_cfg->{zones}{$zoneid};

    my $npc_name = $npc->GetCleanName();

    # Check if this NPC matches a raid boss name and find its group
    my $matched_boss = '';
    my $raid_group_id = 0;

    foreach my $pattern (@{$raid_cfg->{boss_names}}) {
        if ($npc_name =~ /\Q$pattern\E/i) {
            $matched_boss = $pattern;
            # Look up which group this boss belongs to
            if (exists $raid_cfg->{boss_groups}{$pattern}) {
                $raid_group_id = $raid_cfg->{boss_groups}{$pattern};
            }
            last;
        }
    }

    return unless $matched_boss;

    # Get the item pool for this boss's group
    my @item_pool;
    if ($raid_group_id && exists $raid_cfg->{groups}{$raid_group_id}) {
        @item_pool = @{$raid_cfg->{groups}{$raid_group_id}};
    } else {
        # Fallback: combine all groups into one pool
        foreach my $gid (keys %{$raid_cfg->{groups}}) {
            push @item_pool, @{$raid_cfg->{groups}{$gid}};
        }
    }

    return if (scalar(@item_pool) == 0);

    # Configuration
    my $min_items = 1;
    my $max_items = 3;
    my $num_items = $min_items + int(rand($max_items - $min_items + 1));

    quest::debug("RAID BOSS BONUS: $npc_name (group $raid_group_id) will drop $num_items bonus items");

    # Get tier config and DB handle
    my $tier_cfg = plugin::raid_tier_config();
    my $dbh = plugin::get_loot_dbh() if $tier_cfg->{enable};
    my $rare_item_upgraded = 0;

    # Add the bonus items
    for (my $i = 0; $i < $num_items; $i++) {
        my $selected_item = $item_pool[int(rand(scalar(@item_pool)))];

        if ($tier_cfg->{enable} && $dbh) {
            $selected_item = plugin::roll_tier_upgrade($selected_item, $tier_cfg, \$rare_item_upgraded, $dbh);
        }

        $npc->AddItem($selected_item, 1);
        quest::debug("RAID BOSS BONUS: Added item $selected_item to $npc_name");
    }
}

##############################################################################
# Level-Banded Raid Loot (Velious+)
##############################################################################
# Purpose: Add 2-3 bonus items from level-banded raid pool for IsRaidTarget
#          NPCs in expansion zones that use level-block raid pools.
#
# Called from global_npc.pl in EVENT_SPAWN:
#   plugin::raid_levelblock_loot($npc, $npc_level, $zoneid);
##############################################################################

sub raid_levelblock_loot {
    my $npc    = shift;
    my $level  = shift;
    my $zoneid = shift;

    return unless $npc;
    return unless $level;
    return unless $zoneid;

    # Get item pool for this level restricted to the zone's expansion
    my @item_pool = plugin::get_merged_raid_pool($level, $zoneid);

    return if (scalar(@item_pool) == 0);

    # Configuration: 1-3 items
    my $min_items = 1;
    my $max_items = 3;
    my $num_items = $min_items + int(rand($max_items - $min_items + 1));

    my $npc_name = $npc->GetCleanName();
    quest::debug("RAID LEVELBLOCK BONUS: $npc_name (level $level, zone $zoneid) will drop $num_items bonus items from pool of " . scalar(@item_pool));

    # Get tier config and DB handle
    my $tier_cfg = plugin::raid_tier_config();
    my $dbh;
    $dbh = plugin::get_loot_dbh() if $tier_cfg->{enable};
    my $rare_item_upgraded = 0;

    # Add the bonus items
    for (my $i = 0; $i < $num_items; $i++) {
        my $selected_item = $item_pool[int(rand(scalar(@item_pool)))];

        if ($tier_cfg->{enable} && $dbh) {
            $selected_item = plugin::roll_tier_upgrade($selected_item, $tier_cfg, \$rare_item_upgraded, $dbh);
        }

        $npc->AddItem($selected_item, 1);
        quest::debug("RAID LEVELBLOCK BONUS: Added item $selected_item to $npc_name");
    }

    # Secondary ultra-rare roll (1/250 chance)
    my $ultra_rare_pool = plugin::velious_ultra_rare_pool();
    if ($level >= 70 && $ultra_rare_pool && scalar(@$ultra_rare_pool) > 0 && int(rand(250)) == 0) {
        my $ultra_item = $ultra_rare_pool->[int(rand(scalar(@$ultra_rare_pool)))];
        $npc->AddItem($ultra_item, 1);
        quest::debug("RAID LEVELBLOCK BONUS: ULTRA-RARE! Added item $ultra_item to $npc_name (1/250 roll)");
    }
}

return 1;
