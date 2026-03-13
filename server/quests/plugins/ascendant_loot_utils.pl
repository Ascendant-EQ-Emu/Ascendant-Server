##############################################################################
# Ascendant Loot Utils - Config + Shared Logic
##############################################################################
# Active expansion config, level block resolution, tier upgrade rolls,
# and pool merging. All functions are subs (plugin requirement).
##############################################################################

#=============================================================================
# CONFIGURATION - Active Expansions
#=============================================================================
# Add expansion names here as they unlock. Order matters for level block
# priority (later expansions override earlier ones for overlapping ranges).

sub active_expansions {
    return ('classic', 'kunark', 'velious');
}

#=============================================================================
# CONFIGURATION - Tier Upgrade Chances
#=============================================================================

sub rare_tier_config {
    return {
        enable    => 1,
        t3_chance => 0.06,   # 6% Ascendant
        t2_chance => 0.15,   # 15% Exalted
        t1_chance => 0.30,   # 30% Greater
        max_rare_upgrades => 1,  # Max T2/T3 per NPC
    };
}

sub raid_tier_config {
    return {
        enable    => 1,
        t3_chance => 0.10,   # 10% Ascendant
        t2_chance => 0.20,   # 20% Exalted
        t1_chance => 0.40,   # 40% Greater
        max_rare_upgrades => 1,  # Max T2/T3 per boss
    };
}

sub common_tier_config {
    return {
        enable    => 1,
        t3_chance => 0.06,   # 6% Ascendant
        t2_chance => 0.15,   # 15% Exalted
        t1_chance => 0.30,   # 30% Greater
        max_rare_upgrades => 1,
    };
}

#=============================================================================
# Dispatch helpers + zone-to-expansion resolution
#=============================================================================

sub _expansion_pool_dispatch {
    my $exp = shift;
    if ($exp eq 'classic') { return plugin::classic_rare_pools(); }
    if ($exp eq 'kunark')  { return plugin::kunark_rare_pools(); }
    if ($exp eq 'velious') { return plugin::velious_rare_pools(); }
    return undef;
}

sub _expansion_blocks_dispatch {
    my $exp = shift;
    if ($exp eq 'classic') { return plugin::classic_level_blocks(); }
    if ($exp eq 'kunark')  { return plugin::kunark_level_blocks(); }
    if ($exp eq 'velious') { return plugin::velious_level_blocks(); }
    return undef;
}

sub _expansion_raid_dispatch {
    my $exp = shift;
    if ($exp eq 'classic') { return plugin::classic_raid_config(); }
    if ($exp eq 'kunark')  { return plugin::kunark_raid_config(); }
    return undef;
}

sub _expansion_zone_dispatch {
    my $exp = shift;
    if ($exp eq 'classic') { return plugin::classic_zone_ids(); }
    if ($exp eq 'kunark')  { return plugin::kunark_zone_ids(); }
    if ($exp eq 'velious') { return plugin::velious_zone_ids(); }
    return undef;
}

sub _expansion_raid_pool_dispatch {
    my $exp = shift;
    if ($exp eq 'velious') { return plugin::velious_raid_pools(); }
    return undef;
}

sub _expansion_raid_blocks_dispatch {
    my $exp = shift;
    if ($exp eq 'velious') { return plugin::velious_raid_level_blocks(); }
    return undef;
}

#=============================================================================
# zone_to_expansion($zoneid) - Returns which expansion a zone belongs to
# Returns expansion name string or undef if zone not mapped (no bonus loot)
#=============================================================================

sub zone_to_expansion {
    my $zoneid = shift;
    return undef unless $zoneid;

    foreach my $exp (plugin::active_expansions()) {
        my $zones = _expansion_zone_dispatch($exp);
        next unless $zones;
        return $exp if exists $zones->{$zoneid};
    }

    # Unknown zone = no bonus loot
    return undef;
}

sub get_merged_pool {
    my $level  = shift;
    my $zoneid = shift;
    my @merged = ();

    # Determine which expansion this zone belongs to
    my $zone_exp = plugin::zone_to_expansion($zoneid);

    # Unknown zone = no bonus loot
    return @merged unless $zone_exp;

    # Only pull items from that expansion's pools
    my $pools  = _expansion_pool_dispatch($zone_exp);
    my $blocks = _expansion_blocks_dispatch($zone_exp);
    if ($pools && $blocks) {
        foreach my $b (@$blocks) {
            if ($level >= $b->{min} && $level <= $b->{max}) {
                my $block_id = $b->{block};
                if (exists $pools->{$block_id}) {
                    push @merged, @{$pools->{$block_id}};
                }
            }
        }
    }

    return @merged;
}

#=============================================================================
# get_merged_raid_pool($level, $zoneid) - Level-banded raid pool (Velious)
#=============================================================================

sub get_merged_raid_pool {
    my $level  = shift;
    my $zoneid = shift;
    my @merged = ();

    my $zone_exp = plugin::zone_to_expansion($zoneid);
    return @merged unless $zone_exp;

    my $pools  = _expansion_raid_pool_dispatch($zone_exp);
    my $blocks = _expansion_raid_blocks_dispatch($zone_exp);
    if ($pools && $blocks) {
        foreach my $b (@$blocks) {
            if ($level >= $b->{min} && $level <= $b->{max}) {
                my $block_id = $b->{block};
                if (exists $pools->{$block_id}) {
                    push @merged, @{$pools->{$block_id}};
                }
            }
        }
    }

    return @merged;
}

#=============================================================================
# get_merged_raid_config() - Merge raid configs from all active expansions
#=============================================================================

sub get_merged_raid_config {
    my %merged_zones;
    my @merged_boss_names;
    my %merged_groups;
    my %merged_boss_groups;
    my $group_offset = 0;

    foreach my $exp (plugin::active_expansions()) {
        my $config = _expansion_raid_dispatch($exp);
        next unless $config;

        # Merge zones
        if ($config->{zones}) {
            foreach my $z (keys %{$config->{zones}}) {
                $merged_zones{$z} = 1;
            }
        }

        # Merge boss names
        if ($config->{boss_names}) {
            push @merged_boss_names, @{$config->{boss_names}};
        }

        # Merge groups (offset group IDs to avoid collisions)
        if ($config->{groups}) {
            foreach my $gid (keys %{$config->{groups}}) {
                my $new_gid = $gid + $group_offset;
                $merged_groups{$new_gid} = $config->{groups}{$gid};
            }
        }

        # Merge boss_groups mapping
        if ($config->{boss_groups}) {
            foreach my $bname (keys %{$config->{boss_groups}}) {
                my $new_gid = $config->{boss_groups}{$bname} + $group_offset;
                $merged_boss_groups{$bname} = $new_gid;
            }
        }

        # Offset for next expansion (use 100 per expansion to avoid collisions)
        $group_offset += 100;
    }

    return {
        zones       => \%merged_zones,
        boss_names  => \@merged_boss_names,
        groups      => \%merged_groups,
        boss_groups => \%merged_boss_groups,
    };
}

#=============================================================================
# roll_tier_upgrade($item_id, $tier_cfg, $rare_count_ref, $dbh)
# Returns: upgraded item ID (or original if no upgrade)
#=============================================================================

sub roll_tier_upgrade {
    my $item_id        = shift;
    my $tier_cfg       = shift;
    my $rare_count_ref = shift;  # reference to scalar tracking rare upgrades
    my $dbh            = shift;

    return $item_id unless $tier_cfg->{enable} && $dbh;

    my $sql = q{
        SELECT tier_code, variant_item_id
        FROM item_tier_map
        WHERE base_item_id = ?
        ORDER BY tier_code ASC
    };

    my $sth = $dbh->prepare($sql);
    $sth->execute($item_id);

    my %tier_variants;
    while (my ($tier_code, $variant_id) = $sth->fetchrow_array()) {
        $tier_variants{$tier_code} = $variant_id if $tier_code && $variant_id;
    }
    $sth->finish();

    return $item_id unless %tier_variants;

    my $max_rare = $tier_cfg->{max_rare_upgrades} || 1;

    # Roll for T3 (Ascendant)
    if (exists $tier_variants{3} && rand() < $tier_cfg->{t3_chance}) {
        if ($$rare_count_ref < $max_rare) {
            $$rare_count_ref++;
            quest::debug("Tier upgrade: T3 (Ascendant) -> item $tier_variants{3}");
            return $tier_variants{3};
        }
    }
    # Roll for T2 (Exalted)
    elsif (exists $tier_variants{2} && rand() < $tier_cfg->{t2_chance}) {
        if ($$rare_count_ref < $max_rare) {
            $$rare_count_ref++;
            quest::debug("Tier upgrade: T2 (Exalted) -> item $tier_variants{2}");
            return $tier_variants{2};
        }
    }
    # Roll for T1 (Greater)
    elsif (exists $tier_variants{1} && rand() < $tier_cfg->{t1_chance}) {
        quest::debug("Tier upgrade: T1 (Greater) -> item $tier_variants{1}");
        return $tier_variants{1};
    }

    return $item_id;
}

#=============================================================================
# get_loot_dbh() - Get database handle for tier lookups
#=============================================================================

sub get_loot_dbh {
    return plugin::LoadMysql() if defined &plugin::LoadMysql;
    return undef;
}

return 1;
