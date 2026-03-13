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

    # ---- SLEEPER-SPECIFIC FLOW (two modes) ----
    if ($current_zone eq 'sleeper') {
        if ($text =~ /hail/i) {
            $client->Message(18, "The Sleeper's Tomb holds great power... and great danger.");
            $client->Message(18, "Which era do you wish to experience?");
            $client->Message(18, "  " . quest::saylink("sleeper 1", 1, "Sleeper 1.0") . " - The Warders stand guard. The Sleeper yet slumbers.");
            $client->Message(18, "  " . quest::saylink("sleeper 2", 1, "Sleeper 2.0") . " - The Ancients have risen. The Sleeper has been freed.");
            $client->Message(18, "Or " . quest::saylink("enter", 1) . " your expedition, or " . quest::saylink("send group", 1) . ".");
            $client->Message(21, "Lockout: 4h (shared) | Duration: 7d | One active expedition at a time.");
        }
        elsif ($text =~ /sleeper 1/i) {
            my $char_id = $client->CharacterID();
            quest::set_data("sleeper_pending_$char_id", "1", 3600);
            my $result = plugin::CreateExpedition("sleeper", 0, "Sleeper's Tomb", 1, 54);
            if ($result) {
                quest::debug("Sleeper: Stored pending mode=1 for char=$char_id");
                $client->Message(2, "Mode: Sleeper 1.0 (Warders)");
            } else {
                quest::delete_data("sleeper_pending_$char_id");
            }
        }
        elsif ($text =~ /sleeper 2/i) {
            my $char_id = $client->CharacterID();
            quest::set_data("sleeper_pending_$char_id", "2", 3600);
            my $result = plugin::CreateExpedition("sleeper", 0, "Sleeper's Tomb", 1, 54);
            if ($result) {
                quest::debug("Sleeper: Stored pending mode=2 for char=$char_id");
                $client->Message(2, "Mode: Sleeper 2.0 (Ancients)");
            } else {
                quest::delete_data("sleeper_pending_$char_id");
            }
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
    if ($text =~ /hail/i) {
        $client->Message(18, "The planes bend to my will. I can bind you to an expedition in $zone_long_name.");
        $client->Message(18,  " What would you like to do?  Create a new " . quest::saylink("expedition", 1) . "? Perhaps you wish to " . quest::saylink("enter", 1) . " it now? Or maybe " . quest::saylink("send group", 1) . "?");
        $client->Message(21, "Lockout: 4h | Duration: 7d | One active expedition at a time.");
    }
    elsif ($text =~ /expedition/i) {
        plugin::CreateExpedition("", 0, "", 1, 54);
    }
    elsif ($text =~ /enter/i) {
        plugin::TeleportToExpedition();
    }
    elsif ($text =~ /send group/i) {
        plugin::TeleportGroupToExpedition();
    }
}

=pod
sub EVENT_SAY {
    # Get the current zone
    my $current_zone = quest::GetZoneShortName($zoneid);
    my $zone_long_name = quest::GetZoneLongName($current_zone);
    
        if ($text =~ /hail/i) {
            $client->Message(18, "The planes bend to my will. I can bind you to an expedition in $zone_long_name.");
            $client->Message(18,  " What would you like to do?  Create a new " . quest::saylink("expedition", 1) . "? Perhaps you wish to " . quest::saylink("enter", 1) . " it now? Or maybe " . quest::saylink("send group", 1) . "?");
            $client->Message(21, "Lockout: 4h | Duration: 7d | One active expedition at a time.");
        }


    elsif ($text =~ /expedition/i) {
        # Create expedition for current zone
        plugin::CreateExpedition("", 0, "", 1, 54);
    }
    elsif ($text =~ /enter/i) {
        plugin::TeleportToExpedition();
    }
    elsif ($text =~ /send group/i) {
        plugin::TeleportGroupToExpedition();
    }
}
=cut

sub EVENT_ITEM {
    plugin::return_items(\%itemcount);
}

sub EVENT_TIMER {
    if ($timer_name eq "apply_lockout") {
        quest::stoptimer("apply_lockout");
        plugin::ApplyPendingLockouts();
    }
}