# Ascendant EQ - Expedition System Plugin
# Provides functions for creating and managing expeditions
# Author: Straps

use strict;
use warnings;

# -----------------------------------------------------------------------------
# Maintenance Mode — set to 1 to block non-GMs, 0 to allow everyone
# -----------------------------------------------------------------------------
my $MAINTENANCE_MODE = 0;

sub CheckMaintenanceMode {
    my $client = plugin::val('$client');
    if ($MAINTENANCE_MODE) {
        if ($client->GetGM()) {
            $client->Message(15, "[Maintenance Mode Active — GM bypass]");
            return 0;
        }
        $client->Message(13, "Excuse me, I will be back soon! Expeditions are temporarily offline for maintenance.");
        return 1;
    }
    return 0;
}

# -----------------------------------------------------------------------------
# CreateExpedition
# Creates a new expedition for the current zone.
# Flow: gather members → check lockouts → check active expeditions → create
# DZ → assign lockouts. Lockouts are only applied after the DZ is requested.
# 4 hours = 14400 seconds | 7 days = 604800 seconds
# -----------------------------------------------------------------------------
sub CreateExpedition {
    my ($zone_name, $zone_version, $expedition_name, $min_players, $max_players) = @_;

    my $client      = plugin::val('$client');
    my $zoneid      = plugin::val('$zoneid');
    my $entity_list = plugin::val('$entity_list');

    # Maintenance gate — remove or toggle off when done testing
    return 0 if plugin::CheckMaintenanceMode();

    # Use current zone if not specified
    if (!$zone_name || $zone_name eq "") {
        $zone_name = quest::GetZoneShortName($zoneid);
    }

    # Get zone configuration
    my $config = plugin::GetExpeditionConfig($zone_name);

    # Set expedition name
    if (!$expedition_name) {
        $expedition_name = $config->{default_name} || quest::GetZoneLongName($zone_name);
    }

    # Set defaults
    $zone_version ||= $config->{zone_version} || 0;
    $min_players  ||= 1;
    $max_players  ||= 54;

    my $creator_id = $client->CharacterID();
    my $raid  = $client->GetRaid();
    my $group = $client->GetGroup();

    # -------------------------------------------------------------------------
    # STEP 1: Gather in-zone Client objects for pre-checks.
    # Raid: iterate all zone clients, filter by IsRaidMember.
    # Group: GetMember returns Client* (in-zone only).
    # -------------------------------------------------------------------------
    my @in_zone_clients;

    if ($raid) {
        # Raid::GetMember is not a valid API — use GetClientList + IsRaidMember
        my @client_list = $entity_list->GetClientList();
        foreach my $m (@client_list) {
            next unless $m;
            if ($raid->IsRaidMember($m)) {
                push @in_zone_clients, $m;
            }
        }
    } elsif ($group) {
        for (my $i = 0; $i < 6; $i++) {
            my $m = $group->GetMember($i);
            next unless $m;
            push @in_zone_clients, $m;
        }
    } else {
        # Solo
        push @in_zone_clients, $client;
    }

    # -------------------------------------------------------------------------
    # STEP 2: Check members for lockouts.
    # Use DoesAnyMemberHaveExpeditionLockout as the primary check (queries DB,
    # covers offline/out-of-zone). Then try to identify who by name.
    # -------------------------------------------------------------------------
    my $lockout_detected = 0;

    if ($raid) {
        $lockout_detected = $raid->DoesAnyMemberHaveExpeditionLockout($expedition_name, "Replay Timer");
    } elsif ($group) {
        $lockout_detected = $group->DoesAnyMemberHaveExpeditionLockout($expedition_name, "Replay Timer");
    } else {
        $lockout_detected = $client->HasExpeditionLockout($expedition_name, "Replay Timer");
    }

    if ($lockout_detected) {
        # Try to identify who by checking each in-zone client
        my @locked_names;
        foreach my $m (@in_zone_clients) {
            if ($m->HasExpeditionLockout($expedition_name, "Replay Timer")) {
                push @locked_names, $m->GetCleanName();
            }
        }

        my $who = @locked_names
            ? join(", ", @locked_names)
            : $raid ? "a raid member" : "a group member";

        $client->Message(13, "Cannot create expedition — locked out: $who.");
        $client->Message(13, "No expedition was created and no lockouts were applied.");
        return 0;
    }

    # -------------------------------------------------------------------------
    # STEP 3: Check in-zone members for an active expedition.
    # (No cross-zone API for this; the server will also reject if it finds one.)
    # -------------------------------------------------------------------------
    my @has_expedition;
    foreach my $m (@in_zone_clients) {
        my $exp = $m->GetExpedition();
        if ($exp) {
            my $exp_zone = quest::GetZoneLongName(quest::GetZoneShortName($exp->GetZoneID()));
            push @has_expedition, $m->GetCleanName() . " ($exp_zone)";
        }
    }

    if (@has_expedition) {
        my $who = join(", ", @has_expedition);
        $client->Message(13, "Cannot create expedition — already in one: $who.");
        $client->Message(13, "No expedition was created and no lockouts were applied.");
        return 0;
    }

    # -------------------------------------------------------------------------
    # STEP 4: Create the expedition.
    # -------------------------------------------------------------------------
    $client->CreateExpedition($zone_name, $zone_version, 604800, $expedition_name, $min_players, $max_players);

    # -------------------------------------------------------------------------
    # STEP 5: Apply lockouts via DB write for each in-zone member.
    # quest::add_expedition_lockout_by_char_id writes directly to the DB,
    # bypassing the async issue with $client->AddExpeditionLockout.
    # -------------------------------------------------------------------------
    my $count = 0;
    foreach my $m (@in_zone_clients) {
        quest::add_expedition_lockout_by_char_id($m->CharacterID(), $expedition_name, "Replay Timer", 14400);
        $count++;
    }

    $client->Message(2, "Expedition created: $expedition_name");
    $client->Message(2, "Lockout: 4 hours ($count members) | Duration: 7 days");
    $client->Message(2, "Say " . quest::saylink("enter",      1, "'enter'")      . " to go alone or " .
                        quest::saylink("send group", 1, "'send group'") . " to bring everyone.");

    return 1;
}

# -----------------------------------------------------------------------------
# TeleportToExpedition
# Sends the calling client to their active expedition instance.
# -----------------------------------------------------------------------------
sub TeleportToExpedition {
    my $client = plugin::val('$client');
    my $zoneid = plugin::val('$zoneid');

    my $expedition = $client->GetExpedition();
    if (!$expedition) {
        $client->Message(13, "You are not part of any active expedition.");
        return 0;
    }

    my $dz_zone_id     = $expedition->GetZoneID();
    my $dz_instance_id = $expedition->GetInstanceID();

    if (!$dz_zone_id || !$dz_instance_id) {
        $client->Message(13, "Failed to retrieve expedition zone information.");
        return 0;
    }

    if ($dz_zone_id != $zoneid) {
        my $exp_zone_name = quest::GetZoneLongName(quest::GetZoneShortName($dz_zone_id));
        $client->Message(13, "Your active expedition is for $exp_zone_name, not this zone.");
        return 0;
    }

    my $zone_x       = quest::GetZoneSafeX($dz_zone_id);
    my $zone_y       = quest::GetZoneSafeY($dz_zone_id);
    my $zone_z       = quest::GetZoneSafeZ($dz_zone_id);
    my $zone_heading = quest::GetZoneSafeHeading($dz_zone_id);

    # Zone-specific entry point overrides
    my $zone_short = quest::GetZoneShortName($dz_zone_id);
    my %entry_overrides = (
        'chardok'     => { x => 911,  y => -104, z => 104,    h => 400 },
        'dreadlands'  => { x => 5405, y => -841, z => 1251.1, h => 0   },
    );
    if (my $override = $entry_overrides{$zone_short}) {
        $zone_x       = $override->{x};
        $zone_y       = $override->{y};
        $zone_z       = $override->{z};
        $zone_heading = $override->{h};
    }

    $client->MovePCInstance($dz_zone_id, $dz_instance_id, $zone_x, $zone_y, $zone_z, $zone_heading);
    $client->Message(2, "Teleporting to your expedition...");
    return 1;
}

# -----------------------------------------------------------------------------
# TeleportGroupToExpedition
# Sends all in-zone expedition members to the active expedition instance.
# -----------------------------------------------------------------------------
sub TeleportGroupToExpedition {
    my $client      = plugin::val('$client');
    my $entity_list = plugin::val('$entity_list');
    my $zoneid      = plugin::val('$zoneid');

    my $expedition = $client->GetExpedition();
    if (!$expedition) {
        $client->Message(13, "You are not part of any active expedition.");
        return 0;
    }

    my $dz_zone_id     = $expedition->GetZoneID();
    my $dz_instance_id = $expedition->GetInstanceID();

    if (!$dz_zone_id || !$dz_instance_id) {
        $client->Message(13, "Failed to retrieve expedition zone information.");
        return 0;
    }

    if ($dz_zone_id != $zoneid) {
        my $exp_zone_name = quest::GetZoneLongName(quest::GetZoneShortName($dz_zone_id));
        $client->Message(13, "Your active expedition is for $exp_zone_name, not this zone.");
        return 0;
    }

    my $zone_x       = quest::GetZoneSafeX($dz_zone_id);
    my $zone_y       = quest::GetZoneSafeY($dz_zone_id);
    my $zone_z       = quest::GetZoneSafeZ($dz_zone_id);
    my $zone_heading = quest::GetZoneSafeHeading($dz_zone_id);

    # Zone-specific entry point overrides
    my $zone_short_g = quest::GetZoneShortName($dz_zone_id);
    my %entry_overrides_g = (
        'chardok'    => { x => 911,  y => -104, z => 104,    h => 400 },
        'dreadlands' => { x => 5405, y => -841, z => 1251.1, h => 0   },
    );
    if (my $override = $entry_overrides_g{$zone_short_g}) {
        $zone_x       = $override->{x};
        $zone_y       = $override->{y};
        $zone_z       = $override->{z};
        $zone_heading = $override->{h};
    }

    my @expedition_members = plugin::GetAllExpeditionMembers($client);
    if (!@expedition_members) {
        $client->Message(13, "No expedition members found in this zone.");
        return 0;
    }

    my $count = 0;
    foreach my $member_client (@expedition_members) {
        if ($member_client) {
            $member_client->MovePCInstance($dz_zone_id, $dz_instance_id, $zone_x, $zone_y, $zone_z, $zone_heading);
            $member_client->Message(2, "Teleporting to the expedition...");
            $count++;
        }
    }

    $client->Message(2, "Sent $count member(s) to the expedition.");
    return 1;
}

# -----------------------------------------------------------------------------
# GetAllExpeditionMembers
# Returns Client objects for all expedition members currently in this zone.
# -----------------------------------------------------------------------------
sub GetAllExpeditionMembers {
    my $client      = shift;
    my $entity_list = plugin::val('$entity_list');
    my @member_array;

    my $expedition = $client->GetExpedition();
    if ($expedition) {
        my $members = $expedition->GetMembers();
        foreach my $member_name (keys %$members) {
            my $member_charid = $members->{$member_name};
            my $member_client = $entity_list->GetClientByCharID($member_charid);
            push(@member_array, $member_client) if $member_client;
        }
    }

    return @member_array;
}

# -----------------------------------------------------------------------------
# GetGroupOrRaidMembers
# Returns Client objects for all in-zone group/raid members, or just $client
# if solo. Offline and out-of-zone members are NOT included here — use
# DoesAnyMemberHaveExpeditionLockout / add_expedition_lockout_by_char_id for
# those cases instead.
# -----------------------------------------------------------------------------
sub GetGroupOrRaidMembers {
    my $client      = shift;
    my $entity_list = plugin::val('$entity_list');
    my @members;

    # RAID: GetMember() returns char_id
    my $raid = $client->GetRaid();
    if ($raid) {
        for (my $i = 0; $i < 72; $i++) {
            my $cid = $raid->GetMember($i);
            next unless $cid;
            my $m = $entity_list->GetClientByCharID($cid);
            push @members, $m if $m;
        }
        return @members;
    }

    # GROUP: GetMember() returns Client*
    my $group = $client->GetGroup();
    if ($group) {
        for (my $i = 0; $i < 6; $i++) {
            my $m = $group->GetMember($i);
            push @members, $m if $m;
        }
        return @members;
    }

    # SOLO
    return ($client);
}

# -----------------------------------------------------------------------------
# FindMemberWithLockout
# Returns the name of the first group/raid member who holds a lockout for the
# given expedition + event. Queries the DB via char_id so offline and
# out-of-zone members are included. Pass $raid or $group; set the other undef.
# -----------------------------------------------------------------------------
sub FindMemberWithLockout {
    my ($raid, $group, $expedition_name, $event_name) = @_;
    my $entity_list = plugin::val('$entity_list');

    my @char_ids;

    if ($raid) {
        for (my $i = 0; $i < 72; $i++) {
            my $cid = $raid->GetMember($i);
            push @char_ids, $cid if $cid;
        }
    } elsif ($group) {
        for (my $i = 0; $i < 6; $i++) {
            my $m = $group->GetMember($i);
            push @char_ids, $m->CharacterID() if $m;
        }
    }

    foreach my $cid (@char_ids) {
        my $lockout = quest::get_expedition_lockout_by_char_id($cid, $expedition_name, $event_name);
        if ($lockout) {
            # Prefer a live name; fall back to char ID if offline/away
            my $mc = $entity_list->GetClientByCharID($cid);
            return $mc ? $mc->GetCleanName() : "Character #$cid";
        }
    }

    return undef;
}

# -----------------------------------------------------------------------------
# HasExpeditionPortPass
# Returns 1 if the client's account has an expedition port pass stored.
# -----------------------------------------------------------------------------
sub HasExpeditionPortPass {
    my $client  = shift;
    my $acct_id = $client->AccountID();
    return quest::get_data("ascendant_expedition_port_" . $acct_id) ? 1 : 0;
}

# -----------------------------------------------------------------------------
# TeleportToExpeditionFromLobby
# Port-pass gated solo teleport to expedition, usable from the lobby zone.
# No zone match check — the lobby is intentionally a different zone.
# -----------------------------------------------------------------------------
sub TeleportToExpeditionFromLobby {
    my $client = plugin::val('$client');

    if (!plugin::HasExpeditionPortPass($client)) {
        $client->Message(13, "You do not have the Expedition Port Pass. Speak to Exarch Valeth to purchase one.");
        return 0;
    }

    my $expedition = $client->GetExpedition();
    if (!$expedition) {
        $client->Message(13, "You are not part of any active expedition.");
        return 0;
    }

    my $dz_zone_id     = $expedition->GetZoneID();
    my $dz_instance_id = $expedition->GetInstanceID();

    if (!$dz_zone_id || !$dz_instance_id) {
        $client->Message(13, "Failed to retrieve expedition zone information.");
        return 0;
    }

    my $zone_x       = quest::GetZoneSafeX($dz_zone_id);
    my $zone_y       = quest::GetZoneSafeY($dz_zone_id);
    my $zone_z       = quest::GetZoneSafeZ($dz_zone_id);
    my $zone_heading = quest::GetZoneSafeHeading($dz_zone_id);

    $client->MovePCInstance($dz_zone_id, $dz_instance_id, $zone_x, $zone_y, $zone_z, $zone_heading);
    $client->Message(2, "Teleporting to your expedition...");
    return 1;
}

# -----------------------------------------------------------------------------
# TeleportGroupToExpeditionFromLobby
# Port-pass gated group teleport to expedition, usable from the lobby zone.
# Skips members who lack a port pass rather than aborting entirely.
# -----------------------------------------------------------------------------
sub TeleportGroupToExpeditionFromLobby {
    my $client      = plugin::val('$client');
    my $entity_list = plugin::val('$entity_list');

    if (!plugin::HasExpeditionPortPass($client)) {
        $client->Message(13, "You do not have the Expedition Port Pass.");
        return 0;
    }

    my $expedition = $client->GetExpedition();
    if (!$expedition) {
        $client->Message(13, "You are not part of any active expedition.");
        return 0;
    }

    my $dz_zone_id     = $expedition->GetZoneID();
    my $dz_instance_id = $expedition->GetInstanceID();

    if (!$dz_zone_id || !$dz_instance_id) {
        $client->Message(13, "Failed to retrieve expedition zone information.");
        return 0;
    }

    my $group = $client->GetGroup();
    if (!$group) {
        $client->Message(13, "You are not in a group. Use 'just me' to go alone.");
        return 0;
    }

    my $zone_x       = quest::GetZoneSafeX($dz_zone_id);
    my $zone_y       = quest::GetZoneSafeY($dz_zone_id);
    my $zone_z       = quest::GetZoneSafeZ($dz_zone_id);
    my $zone_heading = quest::GetZoneSafeHeading($dz_zone_id);

    my $count = 0;
    for (my $i = 0; $i < 6; $i++) {
        my $m = $group->GetMember($i);
        next unless $m;

        if (!plugin::HasExpeditionPortPass($m)) {
            $m->Message(13, "You do not have the Expedition Port Pass and cannot be sent to the expedition.");
            $client->Message(13, $m->GetCleanName() . " does not have the Expedition Port Pass — skipped.");
            next;
        }

        $m->MovePCInstance($dz_zone_id, $dz_instance_id, $zone_x, $zone_y, $zone_z, $zone_heading);
        $m->Message(2, "Teleporting to the expedition...");
        $count++;
    }

    $client->Message(2, "Sent $count member(s) to the expedition.");
    return 1;
}

return 1;
