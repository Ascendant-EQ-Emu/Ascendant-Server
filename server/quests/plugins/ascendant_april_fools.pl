# Bristlebane's Mischief — April Fools Event Plugin
# Toggle: plugin::AprilFools_Enabled() returns 1 (on) or 0 (off). Flip and #reloadquests.
#
# Features:
#   1. Doppelganger (3%) — NPC clones attacker's appearance on combat engage
#   2. Size Pranks (~10%) — Player shrunk or enlarged on zone-in, reverts after 60-90s
#   3. Silly Death Emotes (4%) — Random funny zone emote on NPC death

# --- Master Toggle (1 = on, 0 = off) ---
sub AprilFools_Enabled {
    return 0;
}

# ---------------------------------------------------------------------------
# 1. Doppelganger — call from EVENT_COMBAT on engage
# ---------------------------------------------------------------------------
sub AprilFools_OnEngage {
    my ($npc) = @_;
    return unless AprilFools_Enabled();
    if ($npc->IsPet()) { return; }
    if ($npc->GetBodyType() == 11) { return; }
    if ($npc->IsRaidTarget()) { return; }
    if ($npc->GetEntityVariable('af_transformed')) { return; }

    return unless int(rand(100)) < 5;  # 5% chance

    my $top = $npc->GetHateTop();
    return unless $top && $top->IsClient();
    my $client = $top->CastToClient();
    return unless $client;

    my $name = $client->GetCleanName();

    # Native C++ CloneAppearance — handles race, gender, face, hair, armor, weapons, size
    $npc->CloneAppearance($client);

    $npc->TempName($name . "'s Evil Twin");
    $npc->SetEntityVariable('af_transformed', 1);
}

# ---------------------------------------------------------------------------
# 2. Size Pranks — call from EVENT_ENTER_ZONE
# ---------------------------------------------------------------------------
sub AprilFools_OnZoneIn {
    my ($client) = @_;
    return unless AprilFools_Enabled();
    return unless $client;

    my $char_id = $client->CharacterID();
    my $cd_key = "af_size_cd_${char_id}";
    return if quest::get_data($cd_key);

    return unless int(rand(100)) < 10;  # 10% chance

    my $original_size = $client->GetSize();
    my $new_size;
    if (int(rand(2)) == 0) {
        $new_size = 1 + rand(1);   # 1.0 - 2.0 (shrink)
    } else {
        $new_size = 10 + rand(3);  # 10.0 - 13.0 (enlarge)
    }

    $client->ChangeSize($new_size);
    $client->Message(15, "Bristlebane cackles as he works his mischief on you!");

    quest::set_data("af_origsize_${char_id}", $original_size, 120);
    quest::set_data($cd_key, "1", 600);  # 10min cooldown

    my $revert_sec = 60 + int(rand(31));  # 60-90s
    quest::settimer("af_sizerevert_${char_id}", $revert_sec);
}

sub AprilFools_SizeRevert {
    my ($timer_name) = @_;
    return unless $timer_name =~ /^af_sizerevert_(\d+)$/;
    my $char_id = $1;

    quest::stoptimer($timer_name);

    my $orig = quest::get_data("af_origsize_${char_id}");
    return unless $orig;

    my $entity_list = plugin::val('$entity_list');
    return unless $entity_list;
    my $client = $entity_list->GetClientByCharID($char_id);
    return unless $client;

    $client->ChangeSize($orig + 0);
    $client->Message(15, "Bristlebane's mischief fades... for now.");
    quest::delete_data("af_origsize_${char_id}");
}

# ---------------------------------------------------------------------------
# 3. Silly Death Emotes — call from EVENT_DEATH
# ---------------------------------------------------------------------------
sub AprilFools_OnDeath {
    my ($npc) = @_;
    return unless AprilFools_Enabled();
    return if $npc->IsPet();
    return if $npc->GetBodyType() == 11;

    return unless int(rand(100)) < 4;  # 4% chance

    my @emotes = (
        "A gnome-sized ghost rises from the corpse, does a little dance, and vanishes.",
        "The corpse lets out a final sigh: 'I was only two days from retirement...'",
        "A spectral chicken emerges from the fallen and struts away indignantly.",
        "You hear a faint whisper: 'Tell my wife... she was right about everything.'",
        "The fallen warrior's ghost appears, checks its watch, and shrugs before fading.",
        "A tiny flag pops out of the corpse that reads: 'OUCH.'",
        "The spirit rises and immediately asks for a rez. Some habits die hard.",
        "A ghostly bard appears and plays a sad trombone. Womp womp.",
        "The corpse briefly glows... then a loot pinata appears! Just kidding.",
        "You swear you hear the Jeopardy theme playing from the corpse.",
        "A ghostly gnome appears, pats the corpse on the head, and says: 'Better luck next time, champ.'",
        "The fallen foe's ghost rises and starts doing jumping jacks. Dedication.",
        "A spectral merchant appears over the corpse: 'I'll give you 3 copper for the lot.'",
        "You hear a distant voice: 'FINISH HI-- oh wait, you already did.'",
        "The corpse emits a faint glow and a fortune cookie appears: 'You will loot something disappointing.'",
        "A ghostly halfling runs by screaming: 'THE PIES ARE BURNING!' ...wrong corpse.",
        "The spirit rises, looks at you, and mutters: 'I had better loot in beta.'",
        "A tiny spectral orchestra plays a dramatic death march, then trips over each other.",
        "The fallen foe whispers from beyond: 'I hope you step on a Lego.'",
        "A ghost appears and leaves a one-star review: 'Terrible fight. Would not die again.'",
        "You hear ethereal laughter as a gnomish ghost juggles the fallen's belongings.",
        "The corpse briefly transforms into a rubber duck before returning to normal.",
        "A phantom scribe appears and writes in a ledger: 'Death #4,271. Cause: adventurer.'",
        "The fallen's spirit rises and tries to sell you a timeshare in the Plane of Tranquility.",
        "A spectral kobold appears and shouts 'You no take candle!' before vanishing in a puff of smoke.",
    );

    my $emote = $emotes[int(rand(scalar @emotes))];
    quest::ze(15, $emote);
}

# ---------------------------------------------------------------------------
# 4. NPC Hecklers — random NPCs trash-talk players (zone_controller timer)
# ---------------------------------------------------------------------------
sub AprilFools_HecklerStart {
    return unless AprilFools_Enabled();
    quest::settimer("af_heckle", 10);  # 10s for testing, change to 300+int(rand(301)) for live
}

sub AprilFools_Heckle {
    my ($controller) = @_;
    quest::stoptimer("af_heckle");
    return unless AprilFools_Enabled();

    # Pick a random NPC in the zone (not the controller, not a pet)
    my $entity_list = plugin::val('$entity_list');
    return unless $entity_list;
    my @npc_list = $entity_list->GetNPCList();
    my @candidates;
    foreach my $n (@npc_list) {
        next unless $n;
        next if $n->GetID() == $controller->GetID();
        next if $n->IsPet();
        next if $n->GetBodyType() == 11;
        push @candidates, $n;
    }

    if (@candidates) {
        my $heckler = $candidates[int(rand(scalar @candidates))];

        # Pick a random player to target by name
        my @client_list = $entity_list->GetClientList();  # already resolved above
        my $target_name = "adventurer";
        if (@client_list) {
            my $rc = $client_list[int(rand(scalar @client_list))];
            $target_name = $rc->GetCleanName() if $rc;
        }

        my @sayings = (
            "$target_name, you call that armor? I've seen better on a scarecrow.",
            "I once saw $target_name get lost in the Guild Lobby. The GUILD LOBBY.",
            "Hey $target_name, your weapon looks like it was forged by a blind gnome. No offense to blind gnomes.",
            "$target_name walks into the room and the average IQ drops by ten.",
            "I've seen moss grow faster than $target_name levels.",
            "Is $target_name still using that weapon? I vendor'd better in Crushbone.",
            "$target_name, your reputation precedes you. Unfortunately, it's not a good one.",
            "Someone told me $target_name soloed a rat once. They lost.",
            "You know what $target_name and a decaying skeleton have in common? The skeleton has better gear.",
            "$target_name, I wouldn't trust you to pull a gnoll pup.",
            "I heard $target_name tried to sell a rusty dagger for a plat. Twice.",
            "$target_name, even the bards won't write songs about you.",
            "If $target_name were a spell, they'd be Cancel Magic.",
            "I've met fire beetles with more charisma than $target_name.",
            "$target_name, your sense of direction is so bad, you got lost on a boat.",
            "Hey $target_name, is it true you got pickpocketed by your own rogue alt?",
            "$target_name once asked a merchant how much a 'free sample' costs.",
            "I heard $target_name's last group disbanded mid-pull. Can't imagine why.",
            "$target_name, your combat skills remind me of a drunk iksar on ice.",
            "They say $target_name once got feared into the wrong continent.",
            "$target_name, you fight like a dairy farmer.",
            "I wouldn't invite $target_name to a group if they were the last adventurer in Norrath.",
            "Nice hat, $target_name. Did you loot it off a goblin or did the goblin give it willingly?",
            "$target_name, I've seen better tanking from a cloth-wearing enchanter.",
            "Legend has it $target_name once wiped to a merchant NPC.",
            "$target_name tried to melee as a wizard once. Once.",
            "Even Fippy Darkpaw thinks $target_name is a pushover.",
            "$target_name, you have the tactical awareness of a muffin.",
            "I saw $target_name try to cast a spell without a component. Three times.",
            "$target_name once trained half of Blackburrow into the other half of Blackburrow.",
            "Rumor has it $target_name asked the guildmaster for a refund on their class.",
            "Hey $target_name, even the Plane of Knowledge doesn't have a book about your accomplishments.",
            "I heard $target_name sold their epic for some ringmail boots.",
            "$target_name, your pulling technique is so bad, even monks cringe.",
            "If $target_name were a bard song, they'd be the one that goes out of tune.",
            "They say $target_name once camped a spawn for twelve hours. It was a non-combat NPC.",
            "$target_name, your medding face could frighten an undead.",
            "I'd rather group with a charmed basilisk than $target_name.",
            "Last I heard, $target_name got out-DPSed by a pet with no weapons.",
            "$target_name once asked where to find the Plane of Mischief. They were standing in it.",
            "Hey $target_name, you couldn't pull aggro if you tried. Actually, you can't.",
            "$target_name, I've seen better looting etiquette from an ogre in a bakery.",
            "I heard $target_name got killed by falling damage. In the Guild Lobby.",
            "$target_name's idea of crowd control is running in circles screaming.",
            "They call $target_name 'the human speed bump' in dungeons.",
            "I once saw $target_name buff the wrong group. It was a group of NPCs.",
            "$target_name, even willowisps dodge better than you.",
            "Hey $target_name, I heard your bind point is set to the respawn zone. On purpose.",
            "$target_name is the reason clerics need Rez.",
            "I once saw $target_name negotiate with a merchant. The merchant won. The merchant ALWAYS wins.",
            "$target_name's battle cry sounds like a gnome sneezing.",
            "They say $target_name soloed a brownie once. The baked kind.",
            "Nice moves, $target_name. Did you learn those from a clockwork?",
            "$target_name, your loot luck is so bad, even grey cons drop nothing for you.",
            "I saw $target_name zone in and the mobs started laughing.",
            "Hey $target_name, is it true you once needed a rez from a banker?",
            "$target_name's damage output is measured in disappointment per second.",
            "I heard $target_name got trained by a butterfly. A BUTTERFLY.",
            "$target_name, you have the aggro management skills of a sneeze in a library.",
            "Every time $target_name zones in, Bristlebane himself sheds a single tear of joy.",
        );

        my $saying = $sayings[int(rand(scalar @sayings))];
        $heckler->Say($saying);
    }

    # Restart timer
    quest::settimer("af_heckle", 10);  # 10s for testing, change to 300+int(rand(301)) for live
}

return 1;
