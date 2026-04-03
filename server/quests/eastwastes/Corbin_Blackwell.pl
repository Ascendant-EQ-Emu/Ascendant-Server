# items: 1046, 30162
my $corbin = undef;
my $ambush_spawned = 0;

sub EVENT_SPAWN {
    if ($npc->GetNPCTypeID() == 116119) {
        $corbin = $npc;
        quest::settimer("down",1);
    }
    elsif ($npc->GetNPCTypeID() == 2000944) {
        quest::say("[DEBUG] Escort spawned on grid " . $npc->GetGrid() . " at (" . int($x) . ", " . int($y) . ", " . int($z) . ")");
    }
}

sub EVENT_HP {
    # Unused — healing detection handled by "checkheal" timer below
}

sub EVENT_SAY { 
    if($text=~/hail/i && $npc->GetGrid() == 0) {
        quest::say("Hurry! There's not much time. Give me the key and show me proof that you are a friend sent to rescue me...");
    }
}

sub EVENT_ITEM {
    if (plugin::check_handin(\%itemcount, 1046 => 1, 30162 => 1)) {
        quest::say("I thought I was a dwarfskin rug there for a minute! Thank Brell for your help stranger! Now cover me while I make good my escape. I am weakened and cannot endure much more.");
        quest::summonitem(30162); # Item: Mithril Coldain Insignia Ring
        $corbin2 = quest::spawn2(2000944, 234, 0, $x, $y, $z, $h);
        $mob = $entity_list->GetMobID($corbin2);
        $mobnpc = $mob->CastToNPC();
        $mobnpc->SetHP( $mobnpc->GetMaxHP() * 0.84 );
        quest::depop_withtimer();
    }

    plugin::return_items(\%itemcount);
}

sub EVENT_WAYPOINT_DEPART {
    quest::say("[DEBUG] Departing waypoint $wp") if ($npc->GetNPCTypeID() == 2000944);
    if ($wp == 39 && !$ambush_spawned) {
        $ambush_spawned = 1;
        quest::say("Uh oh, looks like they were tipped off somehow... I hope you can handle them.");
        quest::spawn2(116569, 0, 0, -2139, 168, 150, 114); # NPC: Commander_Bahreck
        quest::settimer("depop", 1200);
    }
}

sub EVENT_WAYPOINT_ARRIVE {
    if ($npc->GetGrid() == 235 && $wp == 18) {
        quest::say("I have escaped! With the help of our friends here I was saved from certain death. We are in their debt.");
        quest::signalwith(116118, 1, 1000); # NPC: Dobbin_Crossaxe
        quest::settimer("depop", 30);
    }
}

sub EVENT_TIMER {
    if ($timer eq "depop") {
        quest::stoptimer("depop");
        quest::depop();
    }
    elsif ($timer eq "down") {
        quest::stoptimer("down");

        # Makes guards emote flavor text
        quest::signalwith(116114, 116119, 500); # NPC: a_Ry`Gorr_prison_guard
        quest::signalwith(116527, 116119, 500); # NPC: a_Ry`Gorr_prison_guard
        quest::signalwith(116102, 116119, 500); # NPC: a_Ry`Gorr_prison_guard

        quest::settimer("resethp", 1);
    }
    elsif ($timer eq "resethp") {
        quest::stoptimer("resethp");

        $npc->SetHP( $npc->GetMaxHP() * 0.30 );
        $npc->SetAppearance(3);

        quest::settimer("checkheal", 2);
    }
    elsif ($timer eq "checkheal") {
        my $hp_pct = int($npc->GetHPRatio());
        if ($hp_pct >= 75 && $npc->GetAppearance() != 0) {
            quest::stoptimer("checkheal");
            quest::emote(" heaves himself heavily to his feet.");
            $npc->SetAppearance(0);
            quest::settimer("down", 5);
        }
        elsif ($hp_pct >= 50 && $npc->GetAppearance() == 3) {
            quest::emote(" sits up with a groan of effort.");
            $npc->SetAppearance(1);
        }
    }
}

sub EVENT_SIGNAL {
    quest::stoptimer("depop");
    quest::spawn2(2000944, 235, 0, $x, $y, $z, $h);
    quest::depop();
}

sub EVENT_DEATH_COMPLETE {
    quest::stoptimer("depop");
}

#END of FILE Zone:eastwastes  ID:116145 ID:2000944 -- Corbin_Blackwell
