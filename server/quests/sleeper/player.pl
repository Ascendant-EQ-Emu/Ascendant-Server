# Sleeper's Tomb - Instance Initialization
# Sets spawn conditions based on expedition mode selected by Planeshifter Tyrael
# Mode 1 = Sleeper 1.0 Raid (Warders up, Ancients off)
# Mode 2 = Sleeper 2.0 Raid (Warders off, Ancients up)
# Normal expedition = neither (both conditions default 0, raid targets excluded)

sub EVENT_ENTERZONE {
    my $inst_id = $instanceid || 0;

    # Fallback: get it from the expedition object
    my $exp = $client->GetExpedition();
    if (!$inst_id && $exp) {
        $inst_id = $exp->GetInstanceID() || 0;
    }

    quest::debug("Sleeper EVENT_ENTERZONE: inst_id=$inst_id");

    # Only run in instances
    return if !$inst_id || $inst_id == 0;

    # Initialization guard — only run once per instance lifetime
    my $init_key = "sleeper_init_$inst_id";
    if (quest::get_data($init_key)) {
        quest::debug("Sleeper Instance $inst_id: Already initialized, skipping");
        return;
    }

    # Look up the pending mode from expedition members' character IDs
    my $mode = 0;

    # First try the entering client
    $mode = quest::get_data("sleeper_pending_" . $client->CharacterID()) || 0;

    # If not found, scan all expedition members
    if (!$mode && $exp) {
        my $members = $exp->GetMembers();
        if ($members) {
            foreach my $name (keys %$members) {
                my $cid = $members->{$name};
                $mode = quest::get_data("sleeper_pending_$cid") || 0;
                if ($mode) {
                    quest::debug("Sleeper Instance $inst_id: Found mode=$mode from member $name (char=$cid)");
                    last;
                }
            }
        }
    }

    quest::debug("Sleeper Instance $inst_id: Resolved mode=$mode");

    if ($mode == 2) {
        # Sleeper 2.0 Raid: Warders off, Ancients up
        quest::spawn_condition("sleeper", $inst_id, 1, 0);
        quest::spawn_condition("sleeper", $inst_id, 2, 1);
        quest::debug("Sleeper Instance $inst_id: Mode 2 (Ancients) — conditions set");
    }
    elsif ($mode == 1) {
        # Sleeper 1.0 Raid: Warders up, Ancients off
        quest::spawn_condition("sleeper", $inst_id, 1, 1);
        quest::spawn_condition("sleeper", $inst_id, 2, 0);
        quest::debug("Sleeper Instance $inst_id: Mode 1 (Warders) — conditions set");
    }
    # else: Normal expedition — both conditions stay at 0 (no warders, no ancients)

    # Mark as initialized
    quest::set_data($init_key, "1", 604800);
}
