sub EVENT_SPAWN {
    my $spawn_id = $npc->GetSpawnPointID();

    # Personal spawned copy: no spawnpoint, so set depop timer
    if (!$spawn_id || $spawn_id == 0) {
        quest::settimer("personal_depop", 900); # 15 minutes
    }
}

sub EVENT_SAY {
    return unless $text =~ /hail/i;

    my $spawn_id = $npc->GetSpawnPointID();

    # Spawned personal copies should not spawn more copies
    if (!$spawn_id || $spawn_id == 0) {
        quest::say("I am already a personal training dummy.");
        return;
    }

    my $charid = $client->CharacterID();
    my $npcid  = $npc->GetNPCTypeID();

    my $lock_key = "personal_dummy_${npcid}_${charid}";

    my %qglobals = plugin::var('qglobals');

    if (defined $qglobals{$lock_key}) {
        quest::say("You already have one active or pending.");
        return;
    }

    quest::setglobal($lock_key, 1, 5, "16M");
    quest::say("Run where you want it. Your personal dummy will appear in 7 seconds and remain for 15 minutes.");
    quest::settimer("spawn_for_${charid}", 7);
}

sub EVENT_TIMER {
    if ($timer eq "personal_depop") {
        quest::stoptimer("personal_depop");

        my $spawn_id = $npc->GetSpawnPointID();
        if (!$spawn_id || $spawn_id == 0) {
            quest::depop();
        }
        return;
    }

    if ($timer =~ /^spawn_for_(\d+)$/) {
        my $charid = $1;
        quest::stoptimer($timer);

        my $client = $entity_list->GetClientByCharID($charid);
        my $npcid  = $npc->GetNPCTypeID();
        my $lock_key = "personal_dummy_${npcid}_${charid}";

        if (!$client) {
            quest::delglobal($lock_key);
            return;
        }

        quest::spawn2(
            $npcid,
            0,
            0,
            $client->GetX(),
            $client->GetY(),
            $client->GetZ(),
            $client->GetHeading()
        );
    }
}