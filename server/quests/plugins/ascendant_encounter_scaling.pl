# ascendant_encounter_scaling.pl - Dynamic Encounter Scaling System
#
# Scales NPC stats at combat engage based on player group/raid composition.
# Replaces static scaling for configured expansion zones (Velious first).
# Classic/Kunark zones keep their existing flat nerfs via global_npc.pl.
#
# Profile assignment is automatic from DB flags:
#   IsRaidTarget() -> raid profile
#   IsRareSpawn()  -> named profile
#   else           -> trash profile
#
# Author: Straps

use POSIX qw(floor);
use List::Util qw(min max sum);

# =============================================================================
# MASTER KILL SWITCH — set to 0 to disable all dynamic scaling instantly
# =============================================================================
my $SCALING_ENABLED = 1;

# =============================================================================
# EXPANSION ZONE CONFIG
# =============================================================================
my %EXPANSION_ZONES = (
    velious => {
        110 => 1,  # iceclad
        111 => 1,  # frozenshadow
        112 => 1,  # velketor
        113 => 1,  # kael
        114 => 1,  # skyshrine
        115 => 1,  # thurgadina
        116 => 1,  # eastwastes
        117 => 1,  # cobaltscar
        118 => 1,  # greatdivide
        119 => 1,  # wakening
        120 => 1,  # westwastes
        121 => 1,  # crystal
        123 => 1,  # necropolis
        124 => 1,  # templeveeshan
        125 => 1,  # sirens
        126 => 1,  # mischiefplane
        127 => 1,  # growthplane
        128 => 1,  # sleeper
        129 => 1,  # thurgadinb
    },
);

# Build a flat lookup: zone_id => 1 for quick eligibility checks
my %SCALING_ZONES;
foreach my $exp (keys %EXPANSION_ZONES) {
    foreach my $zid (keys %{$EXPANSION_ZONES{$exp}}) {
        $SCALING_ZONES{$zid} = 1;
    }
}

# =============================================================================
# NPC EXCLUSIONS — specific npc_type_ids to never scale
# =============================================================================
my %NPC_EXCLUDE = (
    # Add specific NPC type IDs here if needed, e.g.:
    # 128060 => 1,  # "A warning" trigger mob
);

# =============================================================================
# CLASS WEIGHTS — EQ class IDs to archetype scoring
#
# Each class gets a score in three dimensions:
#   durability: how well they can take hits (tanking, self-healing, mitigation)
#   sustain:    how well they can sustain through long fights (healing, regen)
#   damage:     raw damage output capability
#
# Scale: 0.0 (none) to 1.0 (best in class)
# =============================================================================
my %CLASS_WEIGHTS = (
    1  => { durability => 1.00, sustain => 0.15, damage => 0.70 },  # Warrior
    2  => { durability => 0.85, sustain => 0.90, damage => 0.30 },  # Cleric
    3  => { durability => 0.70, sustain => 0.60, damage => 0.75 },  # Paladin
    4  => { durability => 0.60, sustain => 0.50, damage => 0.70 },  # Ranger
    5  => { durability => 0.80, sustain => 0.30, damage => 0.80 },  # Shadowknight
    6  => { durability => 0.50, sustain => 0.75, damage => 0.50 },  # Druid
    7  => { durability => 0.75, sustain => 0.20, damage => 0.85 },  # Monk
    8  => { durability => 0.40, sustain => 0.15, damage => 0.65 },  # Bard
    9  => { durability => 0.55, sustain => 0.15, damage => 0.75 },  # Rogue
    10 => { durability => 0.55, sustain => 0.80, damage => 0.45 },  # Shaman
    11 => { durability => 0.30, sustain => 0.50, damage => 0.55 },  # Necromancer
    12 => { durability => 0.20, sustain => 0.10, damage => 1.00 },  # Wizard
    13 => { durability => 0.35, sustain => 0.40, damage => 0.65 },  # Magician
    14 => { durability => 0.25, sustain => 0.35, damage => 0.50 },  # Enchanter
    15 => { durability => 0.60, sustain => 0.20, damage => 0.75 },  # Beastlord
    16 => { durability => 0.45, sustain => 0.10, damage => 0.70 },  # Berserker
);

# Classes considered "fragile casters" — get extra resist relief
my %FRAGILE_CASTERS = (
    11 => 1,  # Necromancer
    12 => 1,  # Wizard
    13 => 1,  # Magician
    14 => 1,  # Enchanter
);

# =============================================================================
# SYNERGY BONUSES — class combinations that are stronger than sum of parts
#
# If all listed classes are present in the encounter, add the bonus to the
# composition score. This nudges scaling slightly upward (harder) for
# synergistic combos so they don't trivialize content.
# =============================================================================
my @SYNERGY_RULES = (
    # Tank + Healer = strong duo foundation
    { classes => [1, 2],  bonus => 0.10 },  # Warrior + Cleric
    { classes => [3, 2],  bonus => 0.08 },  # Paladin + Cleric
    { classes => [5, 2],  bonus => 0.08 },  # SK + Cleric
    { classes => [1, 10], bonus => 0.08 },  # Warrior + Shaman
    { classes => [7, 10], bonus => 0.08 },  # Monk + Shaman
    # Pet class + Healer
    { classes => [13, 2],  bonus => 0.07 }, # Mage + Cleric
    { classes => [11, 10], bonus => 0.07 }, # Necro + Shaman
    # Enchanter combos (CC + sustain)
    { classes => [14, 2],  bonus => 0.06 }, # Enchanter + Cleric
    { classes => [14, 10], bonus => 0.06 }, # Enchanter + Shaman
);

# =============================================================================
# PROFILE TUNING TABLES
#
# Each profile defines floor/ceiling multipliers for each stat category.
# The engine interpolates between floor (solo fragile) and ceiling (capped group)
# based on composition score and participant count.
#
# hp_solo_floor:    HP multiplier for weakest solo composition
# hp_solo_ceiling:  HP multiplier for strongest solo composition
# hp_group_cap:     HP multiplier cap for large groups (curve flattens here)
# melee_solo_floor: min_hit/max_hit multiplier for weakest solo
# melee_solo_ceil:  min_hit/max_hit multiplier for strongest solo
# melee_group_cap:  melee multiplier cap for large groups
# atk_solo_floor:   ATK multiplier for weakest solo
# atk_group_cap:    ATK multiplier cap for large groups
# resist_solo_min:  resist delta for weakest solo (negative = easier)
# resist_solo_max:  resist delta for strongest solo
# resist_group_cap: resist delta cap for large groups
# =============================================================================
my %PROFILE_TUNING = (
    raid => {
        hp_solo_floor    => 0.30,
        hp_solo_ceiling  => 0.58,
        hp_group_base    => 0.62,
        hp_group_cap     => 0.80,
        melee_solo_floor => 0.30,
        melee_solo_ceil  => 0.55,
        melee_group_base => 0.55,
        melee_group_cap  => 0.65,
        atk_solo_floor   => 0.40,
        atk_group_base   => 0.55,
        atk_group_cap    => 0.70,
        resist_solo_min  => -132,
        resist_solo_max  => -42,
        resist_group_base => -30,
        resist_group_cap => -6,
    },
    named => {
        hp_solo_floor    => 0.35,
        hp_solo_ceiling  => 0.60,
        hp_group_base    => 0.65,
        hp_group_cap     => 0.80,
        melee_solo_floor => 0.35,
        melee_solo_ceil  => 0.60,
        melee_group_base => 0.60,
        melee_group_cap  => 0.72,
        atk_solo_floor   => 0.45,
        atk_group_base   => 0.60,
        atk_group_cap    => 0.75,
        resist_solo_min  => -108,
        resist_solo_max  => -22,
        resist_group_base => -18,
        resist_group_cap => -4,
    },
    trash => {
        hp_solo_floor    => 0.50,
        hp_solo_ceiling  => 0.75,
        hp_group_base    => 0.78,
        hp_group_cap     => 0.90,
        melee_solo_floor => 0.50,
        melee_solo_ceil  => 0.75,
        melee_group_base => 0.75,
        melee_group_cap  => 0.85,
        atk_solo_floor   => 0.55,
        atk_group_base   => 0.75,
        atk_group_cap    => 0.85,
        resist_solo_min  => -66,
        resist_solo_max  => -14,
        resist_group_base => -10,
        resist_group_cap => -2,
    },
);

# =============================================================================
# LEVEL-BASED MINIMUM STAT FLOORS
#
# After percentage scaling, enforce these minimums so mobs with low base stats
# don't feel trivial. Values are multiplied by NPC level.
#   min_hit = level * factor
#   max_hit = level * factor
# =============================================================================
my %STAT_FLOORS = (
    raid => {
        min_hit_per_level => 2.5,
        max_hit_per_level => 6.0,
    },
    named => {
        min_hit_per_level => 2.0,
        max_hit_per_level => 5.0,
    },
    trash => {
        min_hit_per_level => 1.5,
        max_hit_per_level => 3.5,
    },
);

# Rescan timer interval (seconds)
my $RESCAN_INTERVAL = 12;

# Group size where the scaling curve starts to flatten
my $GROUP_CAP_START = 6;

# Maximum participant count for scaling purposes (anything above treated as this)
my $MAX_PARTICIPANTS = 6;

# =============================================================================
# PUBLIC API — called from global_npc.pl
# =============================================================================

# -----------------------------------------------------------------------------
# IsScalingZone($zoneid) — returns 1 if this zone uses dynamic scaling
# Called from EVENT_SPAWN to gate old static scaling
# -----------------------------------------------------------------------------
sub IsScalingZone {
    my ($zid) = @_;
    return 0 unless $SCALING_ENABLED;
    return exists $SCALING_ZONES{$zid} ? 1 : 0;
}

# -----------------------------------------------------------------------------
# EncounterScaling_OnEngage($npc) — called when NPC enters combat
# Determines profile, snapshots stats, scores composition, applies scaling
# -----------------------------------------------------------------------------
sub EncounterScaling_OnEngage {
    my ($npc) = @_;
    return unless $SCALING_ENABLED;
    return unless $npc;

    quest::debug("[EncScaling] OnEngage called for: " . $npc->GetCleanName() . " (NPCID=" . $npc->GetNPCTypeID() . ")");

    # Skip pets, level 1 trigger mobs, excluded NPCs
    if ($npc->IsPet()) {
        quest::debug("[EncScaling] SKIP: pet");
        return;
    }
    if ($npc->GetLevel() <= 1) {
        quest::debug("[EncScaling] SKIP: level <= 1");
        return;
    }
    if (exists $NPC_EXCLUDE{$npc->GetNPCTypeID()}) {
        quest::debug("[EncScaling] SKIP: excluded NPC");
        return;
    }

    # Check zone eligibility
    my $zoneid = plugin::val('$zoneid');
    if (!exists $SCALING_ZONES{$zoneid}) {
        quest::debug("[EncScaling] SKIP: zone $zoneid not in scaling zones");
        return;
    }

    # Already scaled? Don't re-apply
    my $scaled_flag = $npc->GetEntityVariable('enc_scaled');
    return if $scaled_flag && $scaled_flag eq '1';

    # Determine profile from DB flags
    my $profile = _get_profile($npc);

    # Snapshot original stats before any modification
    _snapshot_stats($npc);

    # Find the engaging client
    my $primary_client;

    # Try NPC's current target first
    my $target = $npc->GetTarget();
    if ($target && $target->IsClient()) {
        $primary_client = $target->CastToClient();
    }

    # Fallback: scan hate list (covers pet-pull, proximity aggro, etc.)
    if (!$primary_client) {
        my @hate_list = $npc->GetHateList();
        foreach my $ent (@hate_list) {
            next unless $ent;
            my $h_ent = $ent->GetEnt();
            if ($h_ent && $h_ent->IsClient()) {
                $primary_client = $h_ent->CastToClient();
                last;
            }
        }
    }

    if (!$primary_client) {
        quest::debug("[EncScaling] SKIP: " . $npc->GetCleanName() . " — no client found on target or hate list");
        return;
    }

    # Count in-zone group/raid members and gather class list
    my ($participant_count, $class_list_ref) = _count_participants($primary_client);

    # Score the composition
    my $comp_score = _score_composition($class_list_ref);

    # Check for synergy bonuses
    $comp_score += _check_synergies($class_list_ref);

    # Clamp composition score to [0.0, 1.0]
    $comp_score = max(0.0, min(1.0, $comp_score));

    # Compute multipliers based on profile, participant count, and comp score
    my $mults = _compute_multipliers($profile, $participant_count, $comp_score);

    # Apply the scaling
    _apply_scaling($npc, $mults, $profile);

    # Store state
    $npc->SetEntityVariable('enc_scaled', '1');
    $npc->SetEntityVariable('enc_profile', $profile);
    $npc->SetEntityVariable('enc_participants', "$participant_count");
    $npc->SetEntityVariable('enc_comp_score', sprintf("%.3f", $comp_score));

    # Start rescan timer
    quest::settimer('enc_rescan', $RESCAN_INTERVAL);

    quest::debug("[EncScaling] ENGAGE: " . $npc->GetCleanName()
        . " profile=$profile participants=$participant_count"
        . " comp=" . sprintf("%.3f", $comp_score)
        . " hp_mult=" . sprintf("%.3f", $mults->{hp})
        . " melee_mult=" . sprintf("%.3f", $mults->{melee})
        . " atk_mult=" . sprintf("%.3f", $mults->{atk})
        . " resist_delta=" . sprintf("%.0f", $mults->{resist_delta})
    );
}

# -----------------------------------------------------------------------------
# EncounterScaling_OnDisengage($npc) — called when NPC leaves combat
# Restores original stats and cleans up state
# -----------------------------------------------------------------------------
sub EncounterScaling_OnDisengage {
    my ($npc) = @_;
    return unless $npc;

    my $scaled = $npc->GetEntityVariable('enc_scaled');
    return unless $scaled && $scaled eq '1';

    quest::stoptimer('enc_rescan');
    _restore_stats($npc);

    # Clean up entity variables
    $npc->SetEntityVariable('enc_scaled', '0');
    $npc->DeleteEntityVariable('enc_profile');
    $npc->DeleteEntityVariable('enc_participants');
    $npc->DeleteEntityVariable('enc_comp_score');

    quest::debug("[EncScaling] DISENGAGE: " . $npc->GetCleanName() . " — stats restored");
}

# -----------------------------------------------------------------------------
# EncounterScaling_Rescan($npc) — called on timer during combat
# Re-checks participant count; if increased, scales UP only (capped)
# -----------------------------------------------------------------------------
sub EncounterScaling_Rescan {
    my ($npc) = @_;
    return unless $npc;
    return unless $SCALING_ENABLED;

    my $scaled = $npc->GetEntityVariable('enc_scaled');
    return unless $scaled && $scaled eq '1';

    # Find a client from the hate list for participant detection
    my $primary_client;
    my @hate_list = $npc->GetHateList();
    foreach my $ent (@hate_list) {
        next unless $ent;
        my $h_ent = $ent->GetEnt();
        if ($h_ent && $h_ent->IsClient()) {
            $primary_client = $h_ent->CastToClient();
            last;
        }
    }
    return unless $primary_client;
    my ($new_count, $class_list_ref) = _count_participants($primary_client);

    my $old_count = int($npc->GetEntityVariable('enc_participants') || 1);

    # Only scale UP, never down
    if ($new_count > $old_count) {
        my $profile = $npc->GetEntityVariable('enc_profile') || 'trash';
        my $comp_score = _score_composition($class_list_ref);
        $comp_score += _check_synergies($class_list_ref);
        $comp_score = max(0.0, min(1.0, $comp_score));

        my $mults = _compute_multipliers($profile, $new_count, $comp_score);

        # Restore to original first, then re-apply with new multipliers
        _restore_stats($npc);
        _apply_scaling($npc, $mults, $profile);

        $npc->SetEntityVariable('enc_participants', "$new_count");
        $npc->SetEntityVariable('enc_comp_score', sprintf("%.3f", $comp_score));

        quest::debug("[EncScaling] RESCAN UP: " . $npc->GetCleanName()
            . " $old_count -> $new_count participants"
            . " hp_mult=" . sprintf("%.3f", $mults->{hp})
        );
    }
}

# =============================================================================
# INTERNAL FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# _get_profile($npc) — determine scaling profile from DB flags
# -----------------------------------------------------------------------------
sub _get_profile {
    my ($npc) = @_;

    if ($npc->IsRaidTarget()) {
        return 'raid';
    } elsif ($npc->IsRareSpawn()) {
        return 'named';
    }
    return 'trash';
}

# -----------------------------------------------------------------------------
# _snapshot_stats($npc) — store original stats in entity variables
# -----------------------------------------------------------------------------
sub _snapshot_stats {
    my ($npc) = @_;

    $npc->SetEntityVariable('enc_orig_max_hp',  $npc->GetMaxHP());
    $npc->SetEntityVariable('enc_orig_min_hit', $npc->GetMinDMG());
    $npc->SetEntityVariable('enc_orig_max_hit', $npc->GetMaxDMG());
    $npc->SetEntityVariable('enc_orig_atk',     $npc->GetATK());
    $npc->SetEntityVariable('enc_orig_mr',      $npc->GetMR());
    $npc->SetEntityVariable('enc_orig_fr',      $npc->GetFR());
    $npc->SetEntityVariable('enc_orig_cr',      $npc->GetCR());
    $npc->SetEntityVariable('enc_orig_pr',      $npc->GetPR());
    $npc->SetEntityVariable('enc_orig_dr',      $npc->GetDR());
    $npc->SetEntityVariable('enc_orig_heal_scale', '100');
}

# -----------------------------------------------------------------------------
# _restore_stats($npc) — restore original stats from entity variable snapshot
# -----------------------------------------------------------------------------
sub _restore_stats {
    my ($npc) = @_;

    my $orig_hp  = $npc->GetEntityVariable('enc_orig_max_hp');
    return unless defined $orig_hp && $orig_hp > 0;

    my $orig_min = $npc->GetEntityVariable('enc_orig_min_hit');
    my $orig_max = $npc->GetEntityVariable('enc_orig_max_hit');
    my $orig_atk = $npc->GetEntityVariable('enc_orig_atk');
    my $orig_mr  = $npc->GetEntityVariable('enc_orig_mr');
    my $orig_fr  = $npc->GetEntityVariable('enc_orig_fr');
    my $orig_cr  = $npc->GetEntityVariable('enc_orig_cr');
    my $orig_pr  = $npc->GetEntityVariable('enc_orig_pr');
    my $orig_dr  = $npc->GetEntityVariable('enc_orig_dr');

    $npc->ModifyNPCStat("max_hp",  "$orig_hp");
    $npc->ModifyNPCStat("min_hit", "$orig_min");
    $npc->ModifyNPCStat("max_hit", "$orig_max");
    $npc->ModifyNPCStat("atk",     "$orig_atk");
    $npc->ModifyNPCStat("mr",      "$orig_mr");
    $npc->ModifyNPCStat("fr",      "$orig_fr");
    $npc->ModifyNPCStat("cr",      "$orig_cr");
    $npc->ModifyNPCStat("pr",      "$orig_pr");
    $npc->ModifyNPCStat("dr",      "$orig_dr");
    $npc->ModifyNPCStat("heal_scale", "100");

    # Restore HP to full (original max)
    $npc->SetHP(int($orig_hp));
}

# -----------------------------------------------------------------------------
# _count_participants($client) — count in-zone group/raid members
# Returns ($count, \@class_ids)
# Uses the same pattern as GetGroupOrRaidMembers in ascendant_expeditions.pl
# -----------------------------------------------------------------------------
sub _count_participants {
    my ($client) = @_;
    my $entity_list = plugin::val('$entity_list');
    my @class_ids;

    # Check raid first
    my $raid = $client->GetRaid();
    if ($raid) {
        for (my $i = 0; $i < 72; $i++) {
            my $cid = $raid->GetMember($i);
            next unless $cid;
            my $m = $entity_list->GetClientByCharID($cid);
            if ($m) {
                push @class_ids, $m->GetClass();
            }
        }
        my $count = scalar(@class_ids) || 1;
        return ($count, \@class_ids);
    }

    # Check group
    my $group = $client->GetGroup();
    if ($group) {
        for (my $i = 0; $i < 6; $i++) {
            my $m = $group->GetMember($i);
            if ($m) {
                push @class_ids, $m->GetClass();
            }
        }
        my $count = scalar(@class_ids) || 1;
        return ($count, \@class_ids);
    }

    # Solo
    push @class_ids, $client->GetClass();
    return (1, \@class_ids);
}

# -----------------------------------------------------------------------------
# _score_composition(\@class_ids) — score the group's overall capability
#
# Returns a value from 0.0 (very weak/fragile) to 1.0 (very strong/tanky).
# This drives how much relief the mob gets — lower score = more relief.
#
# For solo: directly uses that class's weights.
# For groups: averages weights with a bonus for diversity.
# -----------------------------------------------------------------------------
sub _score_composition {
    my ($class_list_ref) = @_;
    my @classes = @{$class_list_ref};
    return 0.3 unless @classes;  # fallback

    my $count = scalar(@classes);

    # Gather weight sums
    my ($dur_sum, $sus_sum, $dmg_sum) = (0, 0, 0);
    my $fragile_count = 0;
    my %unique_classes;

    foreach my $cid (@classes) {
        my $w = $CLASS_WEIGHTS{$cid};
        next unless $w;
        $dur_sum += $w->{durability};
        $sus_sum += $w->{sustain};
        $dmg_sum += $w->{damage};
        $fragile_count++ if exists $FRAGILE_CASTERS{$cid};
        $unique_classes{$cid} = 1;
    }

    # Average each dimension
    my $dur_avg = $dur_sum / $count;
    my $sus_avg = $sus_sum / $count;
    my $dmg_avg = $dmg_sum / $count;

    # Weighted composite: durability matters most for survivability,
    # sustain second (can you outlast the mob), damage least (just affects TTK)
    my $raw_score = ($dur_avg * 0.45) + ($sus_avg * 0.35) + ($dmg_avg * 0.20);

    # Diversity bonus: groups with more unique classes are stronger
    if ($count > 1) {
        my $diversity = scalar(keys %unique_classes) / $count;
        $raw_score += $diversity * 0.05;
    }

    # All-fragile penalty: if everyone is a fragile caster, reduce score
    if ($count > 0 && $fragile_count == $count) {
        $raw_score *= 0.75;
    }

    return max(0.0, min(1.0, $raw_score));
}

# -----------------------------------------------------------------------------
# _check_synergies(\@class_ids) — check for synergy bonuses
# Returns additional score bonus (0.0 if no synergies match)
# -----------------------------------------------------------------------------
sub _check_synergies {
    my ($class_list_ref) = @_;
    my %present;
    foreach my $cid (@{$class_list_ref}) {
        $present{$cid} = 1;
    }

    my $bonus = 0;
    foreach my $rule (@SYNERGY_RULES) {
        my $all_present = 1;
        foreach my $req_class (@{$rule->{classes}}) {
            unless (exists $present{$req_class}) {
                $all_present = 0;
                last;
            }
        }
        $bonus += $rule->{bonus} if $all_present;
    }

    return $bonus;
}

# -----------------------------------------------------------------------------
# _compute_multipliers($profile, $participant_count, $comp_score)
#
# Returns a hashref with: hp, melee, atk, resist_delta
#
# The scaling curve works in two regimes:
#   1. Solo/small (1-2): interpolate between floor and ceiling based on comp_score
#      Lower comp_score = more relief (closer to floor)
#   2. Group+ (3+): scale upward from 1.0 toward cap, with diminishing returns
#      Curve flattens above GROUP_CAP_START participants
# -----------------------------------------------------------------------------
sub _compute_multipliers {
    my ($profile, $count, $comp_score) = @_;
    my $t = $PROFILE_TUNING{$profile} || $PROFILE_TUNING{trash};

    # Clamp participant count
    $count = max(1, min($MAX_PARTICIPANTS, $count));

    my ($hp_mult, $melee_mult, $atk_mult, $resist_delta);

    if ($count <= 2) {
        # --- SOLO/DUO REGIME ---
        # comp_score 0.0 (fragile) -> floor (most relief)
        # comp_score 1.0 (tanky)   -> ceiling (least relief)
        # For duo, slightly less relief than solo
        my $duo_factor = ($count == 2) ? 0.15 : 0.0;

        $hp_mult    = _lerp($t->{hp_solo_floor}, $t->{hp_solo_ceiling},
                            $comp_score + $duo_factor);
        $melee_mult = _lerp($t->{melee_solo_floor}, $t->{melee_solo_ceil},
                            $comp_score + $duo_factor);
        $atk_mult   = _lerp($t->{atk_solo_floor}, 1.0,
                            $comp_score + $duo_factor);
        $resist_delta = _lerp($t->{resist_solo_min}, $t->{resist_solo_max},
                              $comp_score + $duo_factor);
    } else {
        # --- GROUP/RAID REGIME ---
        # Scale from 1.0 upward toward cap using diminishing returns
        # Uses a log curve so 3->6 is a bigger jump than 12->18
        my $group_progress = _group_curve($count);

        $hp_mult    = _lerp($t->{hp_group_base}, $t->{hp_group_cap}, $group_progress);
        $melee_mult = _lerp($t->{melee_group_base}, $t->{melee_group_cap}, $group_progress);
        $atk_mult   = _lerp($t->{atk_group_base}, $t->{atk_group_cap}, $group_progress);
        $resist_delta = _lerp($t->{resist_group_base}, $t->{resist_group_cap}, $group_progress);
    }

    # Final clamps
    $hp_mult    = max(0.20, min($t->{hp_group_cap}, $hp_mult));
    $melee_mult = max(0.20, min($t->{melee_group_cap}, $melee_mult));
    $atk_mult   = max(0.30, min($t->{atk_group_cap}, $atk_mult));

    return {
        hp           => $hp_mult,
        melee        => $melee_mult,
        atk          => $atk_mult,
        resist_delta => $resist_delta,
    };
}

# -----------------------------------------------------------------------------
# _group_curve($count) — diminishing returns curve for group scaling
# Returns 0.0 (at 3 participants) to ~1.0 (at MAX_PARTICIPANTS)
# Flattens significantly above GROUP_CAP_START
# -----------------------------------------------------------------------------
sub _group_curve {
    my ($count) = @_;
    return 0.0 if $count <= 2;

    # Shift so 3 participants = 0
    my $x = $count - 2;
    my $max_x = $MAX_PARTICIPANTS - 2;

    # Logarithmic curve: fast rise early, flattens late
    # log(1+x) / log(1+max_x) gives 0..1 range with diminishing returns
    my $progress = log(1 + $x) / log(1 + $max_x);

    return max(0.0, min(1.0, $progress));
}

# -----------------------------------------------------------------------------
# _lerp($a, $b, $t) — linear interpolation, clamped to [0,1] for $t
# -----------------------------------------------------------------------------
sub _lerp {
    my ($a, $b, $t) = @_;
    $t = max(0.0, min(1.0, $t));
    return $a + ($b - $a) * $t;
}

# -----------------------------------------------------------------------------
# _apply_scaling($npc, $mults, $profile) — apply multipliers to NPC stats
# -----------------------------------------------------------------------------
sub _apply_scaling {
    my ($npc, $mults, $profile) = @_;

    # Get original stats from snapshot
    my $orig_hp  = int($npc->GetEntityVariable('enc_orig_max_hp')  || $npc->GetMaxHP());
    my $orig_min = int($npc->GetEntityVariable('enc_orig_min_hit') || $npc->GetMinDMG());
    my $orig_max = int($npc->GetEntityVariable('enc_orig_max_hit') || $npc->GetMaxDMG());
    my $orig_atk = int($npc->GetEntityVariable('enc_orig_atk')     || $npc->GetATK());

    # HP
    my $new_hp = max(1, int($orig_hp * $mults->{hp}));
    $npc->ModifyNPCStat("max_hp", "$new_hp");
    $npc->SetHP($new_hp);

    # Melee damage — apply percentage then enforce level-based floors
    # Floors scale with composition score: fragile solos get softer floors
    my $level = $npc->GetLevel();
    my $floors = $STAT_FLOORS{$profile} || $STAT_FLOORS{trash};
    my $comp = $npc->GetEntityVariable('enc_comp_score') || 0.5;
    my $floor_scale = 0.5 + (0.5 * $comp);  # 0.5 at comp=0, 1.0 at comp=1

    my $min_floor = int($level * $floors->{min_hit_per_level} * $floor_scale);
    my $max_floor = int($level * $floors->{max_hit_per_level} * $floor_scale);

    my $new_min = max($min_floor, int($orig_min * $mults->{melee}));
    my $new_max = max($max_floor, int($orig_max * $mults->{melee}));
    $new_max = max($new_min, $new_max);
    $npc->ModifyNPCStat("min_hit", "$new_min");
    $npc->ModifyNPCStat("max_hit", "$new_max");

    # ATK
    my $new_atk = max(1, int($orig_atk * $mults->{atk}));
    $npc->ModifyNPCStat("atk", "$new_atk");

    # Heal Scale — scale heals proportionally with HP so heals don't negate damage
    my $new_heal_scale = max(10, int(100 * $mults->{hp}));
    $npc->ModifyNPCStat("heal_scale", "$new_heal_scale");

    # Resists — additive delta from original values
    my $delta = int($mults->{resist_delta});
    if ($delta != 0) {
        foreach my $resist_type ('mr', 'fr', 'cr', 'pr', 'dr') {
            my $orig_key = 'enc_orig_' . $resist_type;
            my $orig_val = int($npc->GetEntityVariable($orig_key) || 0);
            my $new_val  = max(0, $orig_val + $delta);
            $npc->ModifyNPCStat($resist_type, "$new_val");
        }
    }
}

1;
