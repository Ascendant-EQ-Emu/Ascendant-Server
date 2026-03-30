# Ascendant EQ - Expedition System Plugin
# Provides functions for creating and managing expeditions
# Author: Straps

use strict;
use warnings;

# -----------------------------------------------------------------------------
# Maintenance Mode — set to 1 to block non-GMs, 0 to allow everyone
# -----------------------------------------------------------------------------
my $MAINTENANCE_MODE = 0;

sub SetMaintenanceMode {
    $MAINTENANCE_MODE = shift;
}

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
# Creates a new expedition for the requesting client's zone.
# Flow: pre-check lockouts → pre-check active expeditions → create DZ →
#       on success only: AddReplayLockout (covers all members + future joins)
# Mode: "normal" (default) = respawning, no raid bosses, 4h lockout
#       "raid"             = non-respawning, all NPCs, 16h lockout
# 4 hours = 14400 seconds | 16 hours = 57600 seconds | 7 days = 604800 seconds
# -----------------------------------------------------------------------------
sub CreateExpedition {
    my ($zone_name, $zone_version, $expedition_name, $min_players, $max_players, $mode) = @_;

    $mode ||= 'normal';

    my $client      = plugin::val('$client');
    my $zoneid      = plugin::val('$zoneid');
    my $entity_list = plugin::val('$entity_list');

    # Maintenance gate
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

    # Raid mode: append ": Raid" to expedition name for independent lockout
    if ($mode eq 'raid') {
        $expedition_name .= ": Raid";
    }

    # Set defaults
    $zone_version ||= $config->{zone_version} || 0;
    $min_players  ||= 1;
    $max_players  ||= 54;

    my $raid  = $client->GetRaid();
    my $group = $client->GetGroup();

    # -------------------------------------------------------------------------
    # STEP 1: Gather in-zone Client objects for pre-check messaging.
    # -------------------------------------------------------------------------
    my @in_zone_clients;

    if ($raid) {
        my @client_list = $entity_list->GetClientList();
        foreach my $m (@client_list) {
            next unless $m;
            push @in_zone_clients, $m if $raid->IsRaidMember($m);
        }
    } elsif ($group) {
        for (my $i = 0; $i < 6; $i++) {
            my $m = $group->GetMember($i);
            next unless $m;
            push @in_zone_clients, $m;
        }
    } else {
        push @in_zone_clients, $client;
    }

    # -------------------------------------------------------------------------
    # STEP 2: Pre-check lockouts (queries DB, covers offline/out-of-zone).
    # This is informational — CreateExpedition also validates internally.
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
        my @locked_names;
        foreach my $m (@in_zone_clients) {
            if ($m->HasExpeditionLockout($expedition_name, "Replay Timer")) {
                push @locked_names, $m->GetCleanName();
            }
        }

        my $who = @locked_names
            ? join(", ", @locked_names)
            : $raid ? "a raid member (offline/out-of-zone)" : "a group member (offline/out-of-zone)";

        $client->Message(13, "Cannot create expedition — locked out: $who.");
        $client->Message(13, "No expedition was created and no lockouts were applied.");
        return 0;
    }

    # -------------------------------------------------------------------------
    # STEP 3: Pre-check in-zone members for an active expedition.
    # (No cross-zone API; the server also rejects if it finds one.)
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
    # STEP 4: Create the expedition. Returns undef on failure.
    # The server validates lockouts + active expeditions for ALL raid/group
    # members (including offline/out-of-zone) and sends its own messages.
    # -------------------------------------------------------------------------
    my $dz = $client->CreateExpedition(
        $zone_name, $zone_version, 604800,
        $expedition_name, $min_players, $max_players
    );

    if (!$dz) {
        $client->Message(13, "Expedition creation failed. No lockouts were applied.");
        return 0;
    }

    # -------------------------------------------------------------------------
    # STEP 5: Success — apply lockout + configure DZ properties.
    # AddReplayLockout covers ALL expedition members (including out-of-zone
    # raid members) and auto-applies to anyone who joins later.
    # -------------------------------------------------------------------------
    my $lockout_seconds = ($mode eq 'raid') ? 57600 : 14400;
    my $lockout_label   = ($mode eq 'raid') ? '16 hours' : '4 hours';
    $dz->AddReplayLockout($lockout_seconds);

    # Safe return: where players go when DZ expires / they're kicked
    my $safe_x = quest::GetZoneSafeX($zoneid);
    my $safe_y = quest::GetZoneSafeY($zoneid);
    my $safe_z = quest::GetZoneSafeZ($zoneid);
    my $safe_h = quest::GetZoneSafeHeading($zoneid);
    $dz->SetSafeReturn($zone_name, $safe_x, $safe_y, $safe_z, $safe_h);

    # Zone-in location override (if configured in expedition config)
    # raid_entry_override applies only to raid mode; entry_override applies to all modes
    my $entry = ($mode eq 'raid' && $config->{raid_entry_override})
                ? $config->{raid_entry_override}
                : $config->{entry_override};
    if ($entry) {
        $dz->SetZoneInLocation($entry->{x}, $entry->{y}, $entry->{z}, $entry->{h});
    }

    my $member_count = $dz->GetMemberCount();
    my $mode_label   = ($mode eq 'raid') ? 'Raid' : 'Normal';
    $client->Message(2, "Expedition created: $expedition_name ($mode_label)");
    $client->Message(2, "Lockout: $lockout_label ($member_count members) | Duration: 7 days");
    $client->Message(2, "Say " . quest::saylink("enter", 1, "'enter'") . " to go alone or " .
                        quest::saylink("send group", 1, "'send group'") . " to bring everyone.");

    return 1;
}

# -----------------------------------------------------------------------------
# TeleportToExpedition
# Sends the calling client to their active expedition instance.
# Uses MovePCDynamicZone which respects SetZoneInLocation.
# -----------------------------------------------------------------------------
sub TeleportToExpedition {
    my $client = plugin::val('$client');
    my $zoneid = plugin::val('$zoneid');

    my $expedition = $client->GetExpedition();
    if (!$expedition) {
        $client->Message(13, "You are not part of any active expedition.");
        return 0;
    }

    my $dz_zone_id = $expedition->GetZoneID();
    if (!$dz_zone_id) {
        $client->Message(13, "Failed to retrieve expedition zone information.");
        return 0;
    }

    # Verify the expedition is for this zone
    if ($dz_zone_id != $zoneid) {
        my $exp_zone_name = quest::GetZoneLongName(quest::GetZoneShortName($dz_zone_id));
        $client->Message(13, "Your active expedition is for $exp_zone_name, not this zone.");
        return 0;
    }

    my $dz_zone_name = quest::GetZoneShortName($dz_zone_id);
    $client->MovePCDynamicZone($dz_zone_name);
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

    my $dz_zone_id = $expedition->GetZoneID();
    if (!$dz_zone_id) {
        $client->Message(13, "Failed to retrieve expedition zone information.");
        return 0;
    }

    if ($dz_zone_id != $zoneid) {
        my $exp_zone_name = quest::GetZoneLongName(quest::GetZoneShortName($dz_zone_id));
        $client->Message(13, "Your active expedition is for $exp_zone_name, not this zone.");
        return 0;
    }

    my $dz_zone_name = quest::GetZoneShortName($dz_zone_id);
    my @expedition_members = plugin::GetAllExpeditionMembers($client);
    if (!@expedition_members) {
        $client->Message(13, "No expedition members found in this zone.");
        return 0;
    }

    my $count = 0;
    foreach my $member_client (@expedition_members) {
        if ($member_client) {
            $member_client->MovePCDynamicZone($dz_zone_name);
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

    my $dz_zone_id = $expedition->GetZoneID();
    if (!$dz_zone_id) {
        $client->Message(13, "Failed to retrieve expedition zone information.");
        return 0;
    }

    my $dz_zone_name = quest::GetZoneShortName($dz_zone_id);
    $client->MovePCDynamicZone($dz_zone_name);
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

    my $dz_zone_id = $expedition->GetZoneID();
    if (!$dz_zone_id) {
        $client->Message(13, "Failed to retrieve expedition zone information.");
        return 0;
    }

    my $group = $client->GetGroup();
    if (!$group) {
        $client->Message(13, "You are not in a group. Use 'just me' to go alone.");
        return 0;
    }

    my $dz_zone_name = quest::GetZoneShortName($dz_zone_id);
    my $count = 0;
    for (my $i = 0; $i < 6; $i++) {
        my $m = $group->GetMember($i);
        next unless $m;

        if (!plugin::HasExpeditionPortPass($m)) {
            $m->Message(13, "You do not have the Expedition Port Pass and cannot be sent to the expedition.");
            $client->Message(13, $m->GetCleanName() . " does not have the Expedition Port Pass — skipped.");
            next;
        }

        $m->MovePCDynamicZone($dz_zone_name);
        $m->Message(2, "Teleporting to the expedition...");
        $count++;
    }

    $client->Message(2, "Sent $count member(s) to the expedition.");
    return 1;
}

return 1;
