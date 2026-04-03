sub EVENT_SPAWN {
    quest::settimer("af_heckle", 10);  # 10s for testing, change to 300+int(rand(301)) for live
}

sub EVENT_TIMER {
    if ($timer eq "af_heckle") {
        quest::stoptimer("af_heckle");
        if (!plugin::AprilFools_Enabled()) {
            quest::settimer("af_heckle", 10);
            return;
        }

        # Pick a random NPC in the zone
        my @npc_list = $entity_list->GetNPCList();
        my @candidates;
        foreach my $n (@npc_list) {
            next unless $n;
            next if $n->IsPet();
            next if $n->GetBodyType() == 11;
            push @candidates, $n;
        }

        if (@candidates) {
            my $heckler = $candidates[int(rand(scalar @candidates))];

            # Pick a random player to target by name
            my @client_list = $entity_list->GetClientList();
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
            $heckler->Shout($saying);
        }

        quest::settimer("af_heckle", 10);  # 10s for testing, change to 300+int(rand(301)) for live
    }
}
