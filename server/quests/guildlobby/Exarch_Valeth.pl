# Exarch Valeth - Ascendant Benediction Vendor (Guild Lobby)
# Author: Straps
#
# Manages server-wide Ascendant Benedictions (haste, healing, run speed, thought).
# Players spend Marks of Ascendance to extend buff timers by 6h (max 48h) for
# ALL online players. Bulk pricing mode lets 1 Mark extend all 4 at once.
# Also sells Expedition Port Passes (account-wide unlock) and trades a
# Buff Bag Kit item (17674) for the satchel + wand pair.

my $MOA_ITEM_ID = 1800; # Mark of Ascendance

# PRICING MODE TOGGLE
# Set to 1 for startup mode (1 Mark extends ALL 4 buffs)
# Set to 0 for normal mode (1 Mark per individual buff)
my $BULK_PRICING_MODE = 1;

sub EVENT_SAY {
    my $player_name = $client->GetCleanName();
    
    if ($text =~ /hail/i) {
        my $now = time();
        my %auras = (
            "Haste" => "ascendant_aura_haste_expires",
            "Healing" => "ascendant_aura_healing_expires",
            "Run Speed" => "ascendant_aura_speed_expires",
            "Thought" => "ascendant_aura_thought_expires"
        );
        
        my @status_lines;
        foreach my $aura_name (sort keys %auras) {
            my $bucket_key = $auras{$aura_name};
            my $value = quest::get_data($bucket_key);
            
            if ($value) {
                my $remaining = $value - $now;
                if ($remaining > 0) {
                    my $hours = int($remaining / 3600);
                    my $minutes = int(($remaining % 3600) / 60);
                    push @status_lines, "<c \"#00FF00\">$aura_name:</c> ${hours}h ${minutes}m";
                } else {
                    push @status_lines, "<c \"#808080\">$aura_name:</c> <c \"#FF0000\">Expired</c>";
                }
            } else {
                push @status_lines, "<c \"#808080\">$aura_name:</c> <c \"#808080\">Inactive</c>";
            }
        }
        
        my $mark_count = $client->CountItem($MOA_ITEM_ID);
        
        my $popup_text = "Greetings, $name. I am Exarch Valeth, keeper of the Ascendant World Benedictions.<br><br>";
        $popup_text .= "<c \"#FFCC00\"><b>Current Benediction Status:</b></c><br>";
        $popup_text .= join("<br>", @status_lines);
        $popup_text .= "<br><br>";
        $popup_text .= "<c \"#FFD700\">Marks of Ascendance:</c> $mark_count<br>";
        if ($BULK_PRICING_MODE) {
            $popup_text .= "<c \"#808080\">Startup Mode: 1 Mark extends ALL 4 buffs by 6 hours (max 48h each).</c>";
        } else {
            $popup_text .= "<c \"#808080\">Each extension costs 1 Mark and adds 6 hours (max 48h).</c>";
        }
        
        $client->Popup2(
            "Exarch Valeth - Ascendant Benedictions",
            $popup_text,
            0, 0,
            0, 0
        );
        
        plugin::Whisper("Marks of Ascendance drop randomly from creatures throughout the world and are occasionally awarded for simply being online and adventuring.");
        plugin::Whisper("I offer server-wide benedictions (buffs) in exchange for Marks. In the future, I will also offer items such as experience potions, large bags, and other useful goods.");
        plugin::Whisper("To extend a benediction: ".quest::saylink("extend haste", 1)." | ".quest::saylink("extend healing", 1)." | ".quest::saylink("extend speed", 1)." | ".quest::saylink("extend thought", 1));
        my $acct_id = $client->AccountID();
        my $has_port = quest::get_data("ascendant_expedition_port_" . $acct_id);
        if (!$has_port) {
            plugin::Whisper("I also offer an " . quest::saylink("expedition port pass", 1) . " for 3 Marks — allows any character on your account to teleport directly to your expedition from the guild lobby porters.");
        } else {
            plugin::Whisper("Your account already has the Expedition Port Pass. Speak to the porters to use it.");
        }
    }
    elsif ($text =~ /extend speed/i) {
        if ($client->CountItem($MOA_ITEM_ID) < 1) {
            plugin::Whisper("You need 1 Mark of Ascendance to extend this benediction. You currently have none.");
            return;
        }
        
        my $bucket_key = "ascendant_aura_speed_expires";
        my $value = quest::get_data($bucket_key);
        my $now = time();
        
        if ($value && $value > $now) {
            my $remaining = $value - $now;
            if ($remaining > 151200) {
                my $hours_remaining = int($remaining / 3600);
                plugin::Whisper("The Ascendant Run Speed benediction still has $hours_remaining hours remaining. Please return when it has less than 42 hours.");
                return;
            }
        }
        
        $client->Popup2(
            "Confirm Extension - Run Speed",
            "<c \"#FFCC00\">Cost:</c> 1 Mark of Ascendance<br><br>"
            . "This will extend the <c \"#00FF00\">Ascendant Run Speed</c> benediction by <c \"#00FFFF\">6 hours</c> for <c \"#FFD700\">ALL players</c> on the server.<br><br>"
            . "Do you wish to proceed?",
            1001,
            1002,
            2, 0,
            "Confirm", "Cancel"
        );
    }
    elsif ($text =~ /extend healing/i) {
        if ($client->CountItem($MOA_ITEM_ID) < 1) {
            plugin::Whisper("You need 1 Mark of Ascendance to extend this benediction. You currently have none.");
            return;
        }
        
        my $bucket_key = "ascendant_aura_healing_expires";
        my $value = quest::get_data($bucket_key);
        my $now = time();
        
        if ($value && $value > $now) {
            my $remaining = $value - $now;
            if ($remaining > 151200) {
                my $hours_remaining = int($remaining / 3600);
                plugin::Whisper("The Ascendant Healing benediction still has $hours_remaining hours remaining. Please return when it has less than 42 hours.");
                return;
            }
        }
        
        $client->Popup2(
            "Confirm Extension - Healing",
            "<c \"#FFCC00\">Cost:</c> 1 Mark of Ascendance<br><br>"
            . "This will extend the <c \"#00FF00\">Ascendant Healing</c> benediction by <c \"#00FFFF\">6 hours</c> for <c \"#FFD700\">ALL players</c> on the server.<br><br>"
            . "Do you wish to proceed?",
            1003,
            1004,
            2, 0,
            "Confirm", "Cancel"
        );
    }
    elsif ($text =~ /extend haste/i) {
        if ($client->CountItem($MOA_ITEM_ID) < 1) {
            plugin::Whisper("You need 1 Mark of Ascendance to extend this benediction. You currently have none.");
            return;
        }
        
        my $bucket_key = "ascendant_aura_haste_expires";
        my $value = quest::get_data($bucket_key);
        my $now = time();
        
        if ($value && $value > $now) {
            my $remaining = $value - $now;
            if ($remaining > 151200) {
                my $hours_remaining = int($remaining / 3600);
                plugin::Whisper("The Ascendant Haste benediction still has $hours_remaining hours remaining. Please return when it has less than 42 hours.");
                return;
            }
        }
        
        $client->Popup2(
            "Confirm Extension - Haste",
            "<c \"#FFCC00\">Cost:</c> 1 Mark of Ascendance<br><br>"
            . "This will extend the <c \"#00FF00\">Ascendant Haste</c> benediction by <c \"#00FFFF\">6 hours</c> for <c \"#FFD700\">ALL players</c> on the server.<br><br>"
            . "Do you wish to proceed?",
            1005,
            1006,
            2, 0,
            "Confirm", "Cancel"
        );
    }
    elsif ($text =~ /extend thought/i) {
        if ($client->CountItem($MOA_ITEM_ID) < 1) {
            plugin::Whisper("You need 1 Mark of Ascendance to extend this benediction. You currently have none.");
            return;
        }
        
        my $bucket_key = "ascendant_aura_thought_expires";
        my $value = quest::get_data($bucket_key);
        my $now = time();
        
        if ($value && $value > $now) {
            my $remaining = $value - $now;
            if ($remaining > 151200) {
                my $hours_remaining = int($remaining / 3600);
                plugin::Whisper("The Ascendant Thought benediction still has $hours_remaining hours remaining. Please return when it has less than 42 hours.");
                return;
            }
        }
        
        $client->Popup2(
            "Confirm Extension - Thought",
            "<c \"#FFCC00\">Cost:</c> 1 Mark of Ascendance<br><br>"
            . "This will extend the <c \"#00FF00\">Ascendant Thought</c> benediction by <c \"#00FFFF\">6 hours</c> for <c \"#FFD700\">ALL players</c> on the server.<br><br>"
            . "Do you wish to proceed?",
            1007,
            1008,
            2, 0,
            "Confirm", "Cancel"
        );
    }
    elsif ($text =~ /expedition port pass/i) {
        my $acct_id = $client->AccountID();
        my $has_port = quest::get_data("ascendant_expedition_port_" . $acct_id);
        
        if ($has_port) {
            plugin::Whisper("Your account already has the Expedition Port Pass.");
            return;
        }
        
        if ($client->CountItem($MOA_ITEM_ID) < 3) {
            plugin::Whisper("You need 3 Marks of Ascendance to purchase the Expedition Port Pass. You have " . $client->CountItem($MOA_ITEM_ID) . ".");
            return;
        }
        
        $client->Popup2(
            "Confirm Purchase - Expedition Port Pass",
            "<c \"#FFCC00\">Cost:</c> 3 Marks of Ascendance<br><br>"
            . "This will unlock the <c \"#00FF00\">Expedition Port Pass</c> for your <c \"#FFD700\">entire account</c>.<br><br>"
            . "Once purchased, any character on this account can teleport directly to their active expedition from the wizard or druid porters in the Guild Lobby.<br><br>"
            . "This is a <c \"#00FFFF\">permanent</c> unlock.",
            1009,
            1010,
            2, 0,
            "Purchase", "Cancel"
        );
    }
}

sub EVENT_POPUPRESPONSE {
    my $player_name = $client->GetCleanName();
    
    my $bucket_key;
    my $aura_name;
    
    # Determine which aura based on popup ID (only confirm IDs)
    if ($popupid == 1001) {
        $bucket_key = "ascendant_aura_speed_expires";
        $aura_name = "Run Speed";
    } elsif ($popupid == 1003) {
        $bucket_key = "ascendant_aura_healing_expires";
        $aura_name = "Healing";
    } elsif ($popupid == 1005) {
        $bucket_key = "ascendant_aura_haste_expires";
        $aura_name = "Haste";
    } elsif ($popupid == 1007) {
        $bucket_key = "ascendant_aura_thought_expires";
        $aura_name = "Thought";
    } elsif ($popupid == 1002 || $popupid == 1004 || $popupid == 1006 || $popupid == 1008) {
        # Cancel buttons for benedictions
        plugin::Whisper("Extension cancelled.");
        return;
    } elsif ($popupid == 1009) {
        # Expedition Port Pass confirm
        my $acct_id = $client->AccountID();
        my $has_port = quest::get_data("ascendant_expedition_port_" . $acct_id);
        
        if ($has_port) {
            plugin::Whisper("Your account already has the Expedition Port Pass.");
            return;
        }
        if ($client->CountItem($MOA_ITEM_ID) < 3) {
            plugin::Whisper("You no longer have enough Marks of Ascendance.");
            return;
        }
        
        $client->RemoveItem($MOA_ITEM_ID, 3);
        quest::set_data("ascendant_expedition_port_" . $acct_id, "1");
        
        $client->Message(15, "You have unlocked the Expedition Port Pass for your account!");
        plugin::Whisper("The porters in the Guild Lobby can now send you directly to your active expedition.");
        return;
    } elsif ($popupid == 1010) {
        # Cancel button for port pass
        plugin::Whisper("Purchase cancelled.");
        return;
    } else {
        return;
    }
    
    # Verify player still has a Mark
    if ($client->CountItem($MOA_ITEM_ID) < 1) {
        plugin::Whisper("You no longer have a Mark of Ascendance.");
        return;
    }
    
    my $value = quest::get_data($bucket_key);
    my $now = time();
    
    # Double-check time limit
    if ($value && $value > $now) {
        my $remaining = $value - $now;
        if ($remaining > 151200) {
            my $hours_remaining = int($remaining / 3600);
            plugin::Whisper("The Ascendant $aura_name benediction still has $hours_remaining hours remaining. Please return when it has less than 42 hours.");
            return;
        }
    }
    
    # Remove the Mark
    $client->RemoveItem($MOA_ITEM_ID, 1);
    
    if ($BULK_PRICING_MODE) {
        # BULK MODE: Extend ALL 4 buffs
        my %all_auras = (
            "Haste" => "ascendant_aura_haste_expires",
            "Healing" => "ascendant_aura_healing_expires",
            "Run Speed" => "ascendant_aura_speed_expires",
            "Thought" => "ascendant_aura_thought_expires"
        );
        
        foreach my $aura (keys %all_auras) {
            my $key = $all_auras{$aura};
            my $val = quest::get_data($key);
            
            if ($val && $val > $now) {
                my $new_expires = $val + 21600;
                my $max_expires = $now + 172800;
                $new_expires = $max_expires if $new_expires > $max_expires;
                quest::set_data($key, $new_expires);
            } else {
                quest::set_data($key, $now + 21600);
            }
        }
        
        # World announcement for bulk mode
        quest::we(15, "Exarch Valeth proclaims: $player_name has extended ALL Ascendant Benedictions by 6 hours!");
        plugin::Whisper("All 4 Ascendant Benedictions have been extended by 6 hours for all adventurers!");
    } else {
        # NORMAL MODE: Extend single aura
        if ($value && $value > $now) {
            my $new_expires = $value + 21600;
            my $max_expires = $now + 172800;
            $new_expires = $max_expires if $new_expires > $max_expires;
            quest::set_data($bucket_key, $new_expires);
        } else {
            quest::set_data($bucket_key, $now + 21600);
        }
        
        # World announcement for single aura
        quest::we(15, "Exarch Valeth proclaims: $player_name has extended the Ascendant $aura_name benediction by 6 hours!");
        plugin::Whisper("The Ascendant $aura_name benediction has been extended by 6 hours for all adventurers!");
    }
    
    # Signal all online clients to apply auras immediately
    quest::worldwidesignalclient(999);
}

sub EVENT_ITEM {
    if (quest::handin({17674 => 1})) {
        $client->SummonItem(17672);
        $client->SummonItem(17673);
        plugin::Whisper("Take this satchel and wand. Place your buff scrolls within the satchel, then use the wand to unleash their power.");
        $client->Message(18, "You receive an Ascendant Buff Satchel and an Ascendant Buff Wand!");
    } else {
        plugin::Whisper("I have no use for this.");
        plugin::return_items(\%itemcount);
    }
}

1;
