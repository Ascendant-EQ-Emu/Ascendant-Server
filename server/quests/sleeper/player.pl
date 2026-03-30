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

    # Look up mode from the expedition leader's pending key (set by Planeshifter Tyrael)
    # Only the leader's key is checked to avoid stale keys from other raid members
    my $mode = 0;
    if ($exp) {
        my $leader_name = $exp->GetLeaderName();
        my $members = $exp->GetMembers();
        if ($leader_name && $members && exists $members->{$leader_name}) {
            my $leader_cid = $members->{$leader_name};
            $mode = quest::get_data("sleeper_pending_$leader_cid") || 0;
            quest::debug("Sleeper Instance $inst_id: Leader=$leader_name cid=$leader_cid mode=$mode");
        }
    }
    # Fallback: try the entering client's key
    if (!$mode) {
        $mode = quest::get_data("sleeper_pending_" . $client->CharacterID()) || 0;
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
