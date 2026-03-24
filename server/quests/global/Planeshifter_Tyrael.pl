# Ascendant EQ - Planeshifter Tyrael (Global Expedition NPC)
# This NPC can be placed in any zone and will create expeditions for that zone
# Author: Straps

sub EVENT_SPAWN {
    # Get a random NPC from the zone to copy appearance from
    my @npc_list = $entity_list->GetNPCList();
    
    if (@npc_list) {
        # Pick a random NPC from the zone
        my $random_npc = $npc_list[int(rand(@npc_list))];
        
        if ($random_npc && $random_npc->GetID() != $npc->GetID()) {
            # Copy the appearance of the random NPC
            my $race = $random_npc->GetRace();
            my $gender = $random_npc->GetGender();
            my $texture = $random_npc->GetTexture();
            my $helm_texture = $random_npc->GetHelmTexture();
            my $size = $random_npc->GetSize();
            
            # Cap size at 6.0 to avoid huge models (lava giants, dragons, etc.)
            if ($size > 9.0) {
                $size = 9.0;
            }
            
            $npc->SendIllusionPacket({
                race => $race,
                gender => $gender,
                texture => $texture,
                helmtexture => $helm_texture,
                size => $size
            });
        }
    }
}

sub EVENT_SAY {
    # Get the current zone
    my $current_zone = quest::GetZoneShortName($zoneid);
    my $zone_long_name = quest::GetZoneLongName($current_zone);

    # GM-only commands (work even in maintenance mode)
    if ($client->GetGM()) {
        if ($text =~ /maintenance on/i) {
            plugin::SetMaintenanceMode(1);
            $client->Message(15, "[GM] Maintenance mode ENABLED. Non-GMs are now blocked.");
            return;
        }
        elsif ($text =~ /maintenance off/i) {
            plugin::SetMaintenanceMode(0);
            $client->Message(15, "[GM] Maintenance mode DISABLED. Expeditions are open.");
            return;
        }
        elsif ($text =~ /clear lockout/i) {
            $client->RemoveAllExpeditionLockouts();
            $client->Message(15, "[GM] All your expedition lockouts cleared.");
            return;
        }
    }

    # Block non-GMs if maintenance mode is on
    return if plugin::CheckMaintenanceMode();

    # ---- SLEEPER-SPECIFIC FLOW (Normal + 1.0 Raid + 2.0 Raid) ----
    if ($current_zone eq 'sleeper') {
        if ($text =~ /hail/i) {
            $client->Message(18, "The planes bend to my will. I can bind you to an expedition in $zone_long_name.");
            $client->Message(18, " ");
            $client->Message(18, "  " . quest::saylink("expedition", 1, "[Normal Expedition]") .
                "  Respawning. Raid bosses excluded. 4h lockout.");
            $client->Message(18, "  " . quest::saylink("sleeper 1", 1, "[Sleeper 1.0 Raid]") .
                "  Non-respawning. The Warders stand guard. 16h lockout.");
            $client->Message(18, "  " . quest::saylink("sleeper 2", 1, "[Sleeper 2.0 Raid]") .
                "  Non-respawning. The Ancients have risen. 16h lockout.");
            $client->Message(18, " ");
            $client->Message(18, "  " . quest::saylink("enter", 1, "[Enter]") .
                " your expedition or " . quest::saylink("send group", 1, "[Send Group]"));
            $client->Message(21, "Normal and Raid lockouts are independent. 1.0/2.0 share a lockout | Duration: 7d");
        }
        elsif ($text =~ /sleeper 1/i) {
            my $char_id = $client->CharacterID();
            quest::set_data("sleeper_pending_$char_id", "1", 3600);
            my $result = plugin::CreateExpedition("sleeper", 0, "Sleeper's Tomb", 1, 54, "raid");
            if (!$result) {
                quest::delete_data("sleeper_pending_$char_id");
            }
        }
        elsif ($text =~ /sleeper 2/i) {
            my $char_id = $client->CharacterID();
            quest::set_data("sleeper_pending_$char_id", "2", 3600);
            my $result = plugin::CreateExpedition("sleeper", 0, "Sleeper's Tomb", 1, 54, "raid");
            if (!$result) {
                quest::delete_data("sleeper_pending_$char_id");
            }
        }
        elsif ($text =~ /expedition/i) {
            plugin::CreateExpedition("", 0, "", 1, 54, "normal");
        }
        elsif ($text =~ /enter/i) {
            plugin::TeleportToExpedition();
        }
        elsif ($text =~ /send group/i) {
            plugin::TeleportGroupToExpedition();
        }
        return;
    }

    # ---- GENERIC FLOW (all other zones) ----
    my $has_raid = plugin::HasRaidTier($current_zone);

    if ($text =~ /hail/i) {
        $client->Message(18, "The planes bend to my will. I can bind you to an expedition in $zone_long_name.");

        if ($has_raid) {
            # Two-tier zone — menu with both tiers
            $client->Message(18, " ");
            $client->Message(18, "  " . quest::saylink("expedition", 1, "[Normal Expedition]") .
                "  Respawning. Raid bosses excluded. 4h lockout.");
            $client->Message(18, "  " . quest::saylink("raid", 1, "[Raid Expedition]") .
                "  Non-respawning. Full zone with raid bosses. 16h lockout.");
            $client->Message(18, " ");
            $client->Message(18, "  " . quest::saylink("enter", 1, "[Enter]") .
                " your expedition or " . quest::saylink("send group", 1, "[Send Group]"));
            $client->Message(21, "Lockouts are independent | Duration: 7d | One active expedition at a time.");
        }
        else {
            # Normal-only zone — single option
            $client->Message(18, "What would you like to do? Create a new " .
                quest::saylink("expedition", 1) . "? Perhaps you wish to " .
                quest::saylink("enter", 1) . " it now? Or maybe " .
                quest::saylink("send group", 1) . "?");
            $client->Message(21, "Lockout: 4h | Duration: 7d | One active expedition at a time.");
        }
    }
    elsif ($text =~ /raid/i) {
        if ($has_raid) {
            plugin::CreateExpedition("", 0, "", 1, 54, "raid");
        }
        else {
            $client->Message(13, "This zone does not offer raid expeditions.");
        }
    }
    elsif ($text =~ /expedition/i) {
        plugin::CreateExpedition("", 0, "", 1, 54, "normal");
    }
    elsif ($text =~ /enter/i) {
        plugin::TeleportToExpedition();
    }
    elsif ($text =~ /send group/i) {
        plugin::TeleportGroupToExpedition();
    }
}

sub EVENT_ITEM {
    plugin::return_items(\%itemcount);
}