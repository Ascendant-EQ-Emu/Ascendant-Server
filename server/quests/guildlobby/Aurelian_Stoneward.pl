# Aurelian Stoneward - Expansion Completion Tracker (Guild Lobby)
# Author: Straps
#
# Tracks which raid bosses a character has defeated per expansion era
# (Classic, Kunark, Velious) and awards one-time rewards when all bosses
# for an era are confirmed dead. Kill flags are stored per-account with
# character name validation; rewards are flagged per-character so alts
# must earn their own completions.

sub EVENT_SAY {
    if ($text =~ /hail/i) {
        my $account_id = $client->AccountID();
        my $char_id = $client->CharacterID();
        
        # Check account flags for Classic (backward compatibility)
        my $has_classic_acct = quest::get_data("classic_complete_" . $account_id);
        # Check character flags for Kunark (new system)
        my $has_kunark_char = CheckKunarkComplete($char_id);
        # Check character flags for Velious
        my $has_velious_char = CheckVeliousComplete($char_id);
        
        # Check character awarded flags
        my $classic_awarded = quest::get_data("classic_awarded_" . $char_id);
        my $kunark_awarded = quest::get_data("kunark_awarded_" . $char_id);
        my $velious_awarded = quest::get_data("velious_awarded_" . $char_id);
        
        my $classic_link = quest::saylink("classic", 1, "Classic");
        my $kunark_link = quest::saylink("kunark", 1, "Kunark");
        my $velious_link = quest::saylink("velious", 1, "Velious");
        
        plugin::Whisper("Greetings, $name. I am Aurelian Stoneward, keeper of legendary achievements. I can help you claim rewards for completing $classic_link, $kunark_link, or $velious_link content.");
        
        # Show status
        if ($has_classic_acct && !$classic_awarded) {
            plugin::Whisper("I see you have completed the Classic era! You have rewards waiting.");
        }
        if ($has_kunark_char && !$kunark_awarded) {
            plugin::Whisper("I see you have completed the Kunark era! You have rewards waiting.");
        }
        if ($has_velious_char && !$velious_awarded) {
            plugin::Whisper("I see you have completed the Velious era! You have rewards waiting.");
        }
    }
    elsif ($text =~ /classic/i) {
        HandleClassicRequest();
    }
    elsif ($text =~ /kunark/i) {
        HandleKunarkRequest();
    }
    elsif ($text =~ /velious/i) {
        HandleVeliousRequest();
    }
}

sub CheckKunarkComplete {
    my ($char_id) = @_;
    my $account_id = $client->AccountID();
    my $char_name  = $client->GetCleanName();
 
    my $has_talendor   = quest::get_data("kunark_talendor_"   . $account_id);
    my $has_severilous = quest::get_data("kunark_severilous_" . $account_id);
    my $has_trakanon   = quest::get_data("kunark_trakanon_"   . $account_id);
 
    return (
        $has_talendor   && $has_talendor   eq $char_name &&
        $has_severilous && $has_severilous eq $char_name &&
        $has_trakanon   && $has_trakanon   eq $char_name
    ) ? 1 : 0;
}

sub CheckVeliousComplete {
    my ($char_id) = @_;
    my $account_id = $client->AccountID();
    my $char_name  = $client->GetCleanName();

    my $has_wuoshi     = quest::get_data("velious_wuoshi_"          . $account_id);
    my $has_kelorekdar = quest::get_data("velious_kelorekdar_"      . $account_id);
    my $has_klandicar  = quest::get_data("velious_klandicar_"       . $account_id);
    my $has_zlandicar  = quest::get_data("velious_zlandicar_"       . $account_id);
    my $has_statue     = quest::get_data("velious_statue_rallos_zek_" . $account_id);

    return (
        $has_wuoshi     && $has_wuoshi     eq $char_name &&
        $has_kelorekdar && $has_kelorekdar eq $char_name &&
        $has_klandicar  && $has_klandicar  eq $char_name &&
        $has_zlandicar  && $has_zlandicar  eq $char_name &&
        $has_statue     && $has_statue     eq $char_name
    ) ? 1 : 0;
}

sub HandleVeliousRequest {
    my $char_id    = $client->CharacterID();
    my $account_id = $client->AccountID();
    my $char_name  = $client->GetCleanName();

    my $has_wuoshi     = quest::get_data("velious_wuoshi_"          . $account_id);
    my $has_kelorekdar = quest::get_data("velious_kelorekdar_"      . $account_id);
    my $has_klandicar  = quest::get_data("velious_klandicar_"       . $account_id);
    my $has_zlandicar  = quest::get_data("velious_zlandicar_"       . $account_id);
    my $has_statue     = quest::get_data("velious_statue_rallos_zek_" . $account_id);

    $has_wuoshi     = ($has_wuoshi     && $has_wuoshi     eq $char_name) ? 1 : 0;
    $has_kelorekdar = ($has_kelorekdar && $has_kelorekdar eq $char_name) ? 1 : 0;
    $has_klandicar  = ($has_klandicar  && $has_klandicar  eq $char_name) ? 1 : 0;
    $has_zlandicar  = ($has_zlandicar  && $has_zlandicar  eq $char_name) ? 1 : 0;
    $has_statue     = ($has_statue     && $has_statue     eq $char_name) ? 1 : 0;

    my $is_complete = ($has_wuoshi && $has_kelorekdar && $has_klandicar && $has_zlandicar && $has_statue) ? 1 : 0;

    # Check if already awarded to this character
    my $already_awarded = quest::get_data("velious_awarded_" . $char_id);

    # Build status popup
    my $wuoshi_status     = $has_wuoshi     ? "<c \"#00FF00\">DEFEATED</c>" : "<c \"#FF0000\">Not Defeated</c>";
    my $kelorekdar_status = $has_kelorekdar ? "<c \"#00FF00\">DEFEATED</c>" : "<c \"#FF0000\">Not Defeated</c>";
    my $klandicar_status  = $has_klandicar  ? "<c \"#00FF00\">DEFEATED</c>" : "<c \"#FF0000\">Not Defeated</c>";
    my $zlandicar_status  = $has_zlandicar  ? "<c \"#00FF00\">DEFEATED</c>" : "<c \"#FF0000\">Not Defeated</c>";
    my $statue_status     = $has_statue     ? "<c \"#00FF00\">DEFEATED</c>" : "<c \"#FF0000\">Not Defeated</c>";

    my $popup_text = "<c \"#FFD700\"><b>Velious Era Completion Status</b></c><br><br>"
                   . "<c \"#FFFFFF\">To complete the Velious era, you must defeat all five raid bosses:</c><br><br>"
                   . "<c \"#00FFFF\">Wuoshi</c> (Wakening Lands): $wuoshi_status<br>"
                   . "<c \"#00FFFF\">Kelorek`Dar</c> (Cobalt Scar): $kelorekdar_status<br>"
                   . "<c \"#00FFFF\">Klandicar</c> (Western Wastes): $klandicar_status<br>"
                   . "<c \"#00FFFF\">Zlandicar</c> (Dragon Necropolis): $zlandicar_status<br>"
                   . "<c \"#00FFFF\">The Statue of Rallos Zek</c> (Kael Drakkel): $statue_status<br><br>";

    if ($already_awarded) {
        my $simple_popup = "<c \"#FFD700\"><b>Velious Era Status</b></c><br><br>"
                         . "<c \"#FFFFFF\">You have already claimed your Velious rewards on this character!</c>";
        $client->Popup2("Velious Era Status", $simple_popup, 0, 0, 0, 0);
        return;
    }
    elsif ($is_complete) {
        $popup_text .= "<c \"#00FF00\"><b>Congratulations!</b></c><br>"
                    . "You have defeated all five Velious raid bosses!<br><br>"
                    . "<c \"#FFD700\">Rewards:</c><br>"
                    . "• Special reward item<br>"
                    . "• New titles<br><br>"
                    . "<c \"#FFFFFF\">Click OK to claim your rewards!</c>";

        $client->Popup2("Velious Era Completion", $popup_text, 5005, 5006, 2, 0, "Claim Rewards", "Cancel");
    }
    else {
        $popup_text .= "<c \"#FF9900\">You must defeat all five bosses to complete the Velious era.</c><br>"
                    . "Return to me when you have accomplished this feat!";

        $client->Popup2("Velious Era Completion", $popup_text, 0, 0, 0, 0);
    }
}

sub HandleClassicRequest {
    my $account_id = $client->AccountID();
    my $char_id = $client->CharacterID();
    
    # Check account completion
    my $has_nagafen = quest::get_data("classic_nagafen_" . $account_id);
    my $has_vox = quest::get_data("classic_vox_" . $account_id);
    my $is_complete = ($has_nagafen && $has_vox) ? 1 : 0;
    
    # Check if already awarded to this character
    my $already_awarded = quest::get_data("classic_awarded_" . $char_id);
    
    # Build status popup
    my $nagafen_status = $has_nagafen ? "<c \"#00FF00\">DEFEATED</c>" : "<c \"#FF0000\">Not Defeated</c>";
    my $vox_status     = $has_vox     ? "<c \"#00FF00\">DEFEATED</c>" : "<c \"#FF0000\">Not Defeated</c>";
    
    my $popup_text = "<c \"#FFD700\"><b>Classic Era Completion Status</b></c><br><br>"
                   . "<c \"#FFFFFF\">To complete the Classic era, you must defeat both ancient dragons:</c><br><br>"
                   . "<c \"#00FFFF\">Lord Nagafen</c> (Solusek's Eye): $nagafen_status<br>"
                   . "<c \"#00FFFF\">Lady Vox</c> (Permafrost): $vox_status<br><br>";
    
    if ($already_awarded) {
        my $simple_popup = "<c \"#FFD700\"><b>Classic Era Status</b></c><br><br>"
                         . "<c \"#FFFFFF\">You have already claimed your Classic rewards on this character!</c>";
        $client->Popup2("Classic Era Status", $simple_popup, 0, 0, 0, 0);
        return;
    }
    elsif ($is_complete) {
        $popup_text .= "<c \"#00FF00\"><b>Congratulations!</b></c><br>"
                    . "You have defeated both ancient dragons!<br><br>"
                    . "<c \"#FFD700\">Rewards:</c><br>"
                    . "• Charm of the First Age<br>"
                    . "• Special reward item<br>"
                    . "• Three new titles<br><br>"
                    . "<c \"#FFFFFF\">Click OK to claim your rewards!</c>";
        
        $client->Popup2("Classic Era Completion", $popup_text, 5001, 5002, 2, 0, "Claim Rewards", "Cancel");
    }
    else {
        $popup_text .= "<c \"#FF9900\">You must defeat both dragons to complete the Classic era.</c><br>"
                    . "Return to me when you have accomplished this feat!";
        
        $client->Popup2("Classic Era Completion", $popup_text, 0, 0, 0, 0);
    }
}


sub HandleKunarkRequest {
    my $char_id    = $client->CharacterID();
    my $account_id = $client->AccountID();
    my $char_name  = $client->GetCleanName();

    my $has_talendor   = quest::get_data("kunark_talendor_"   . $account_id);
    my $has_severilous = quest::get_data("kunark_severilous_" . $account_id);
    my $has_trakanon   = quest::get_data("kunark_trakanon_"   . $account_id);

    $has_talendor   = ($has_talendor   && $has_talendor   eq $char_name) ? 1 : 0;
    $has_severilous = ($has_severilous && $has_severilous eq $char_name) ? 1 : 0;
    $has_trakanon   = ($has_trakanon   && $has_trakanon   eq $char_name) ? 1 : 0;

    my $is_complete = ($has_talendor && $has_severilous && $has_trakanon) ? 1 : 0;

    # Check if already awarded to this character
    my $already_awarded = quest::get_data("kunark_awarded_" . $char_id);
    
    # Build status popup
    my $talendor_status   = $has_talendor   ? "<c \"#00FF00\">DEFEATED</c>"     : "<c \"#FF0000\">Not Defeated</c>";
    my $severilous_status = $has_severilous ? "<c \"#00FF00\">DEFEATED</c>"     : "<c \"#FF0000\">Not Defeated</c>";
    my $trakanon_status   = $has_trakanon   ? "<c \"#00FF00\">DEFEATED</c>"     : "<c \"#FF0000\">Not Defeated</c>";
    
    my $popup_text = "<c \"#FFD700\"><b>Kunark Era Completion Status</b></c><br><br>"
                   . "<c \"#FFFFFF\">To complete the Kunark era, you must defeat all three ancient dragons:</c><br><br>"
                   . "<c \"#00FFFF\">Talendor</c>: $talendor_status<br>"
                   . "<c \"#00FFFF\">Severilous</c>: $severilous_status<br>"
                   . "<c \"#00FFFF\">Trakanon</c>: $trakanon_status<br><br>";
    
    if ($already_awarded) {
        my $simple_popup = "<c \"#FFD700\"><b>Kunark Era Status</b></c><br><br>"
                         . "<c \"#FFFFFF\">You have already claimed your Kunark rewards on this character!</c>";
        $client->Popup2("Kunark Era Status", $simple_popup, 0, 0, 0, 0);
        return;
    }
    elsif ($is_complete) {
        $popup_text .= "<c \"#00FF00\"><b>Congratulations!</b></c><br>"
                    . "You have defeated all three Kunark dragons!<br><br>"
                    . "<c \"#FFD700\">Rewards:</c><br>"
                    . "• Special reward item<br>"
                    . "• Two new titles<br><br>"
                    . "<c \"#FFAA00\">After claiming, hand me your Charm of the First Age to upgrade it to the Charm of the Second Age!</c><br><br>"
                    . "<c \"#FFFFFF\">Click OK to claim your rewards!</c>";
        
        $client->Popup2("Kunark Era Completion", $popup_text, 5003, 5004, 2, 0, "Claim Rewards", "Cancel");
    }
    else {
        $popup_text .= "<c \"#FF9900\">You must defeat all three dragons to complete the Kunark era.</c><br>"
                    . "Return to me when you have accomplished this feat!";
        
        $client->Popup2("Kunark Era Completion", $popup_text, 0, 0, 0, 0);
    }
}

sub EVENT_ITEM {
    if (plugin::check_handin(\%itemcount, 2854 => 1)) {
        my $char_id = $client->CharacterID();
        my $classic_awarded = quest::get_data("classic_awarded_" . $char_id);
        
        if ($classic_awarded) {
            # They've completed Classic, upgrade their charm
            $client->SummonItem(2855);
            plugin::Whisper("Your charm has been upgraded! This enhanced Charm of the Second Age reflects your mastery over the Classic dragons.");
            $client->Message(15, "You received: Charm of the Second Age");
        }
        else {
            # They haven't completed Classic yet, return the item
            plugin::Whisper("You have not yet completed the Classic era. I cannot upgrade your charm at this time.");
            plugin::return_items(\%itemcount);
        }
    }
    else {
        plugin::return_items(\%itemcount);
    }
}

sub EVENT_POPUPRESPONSE {
    if ($popupid == 5001) {
        # Classic rewards claim
        my $account_id = $client->AccountID();
        my $char_id = $client->CharacterID();
        
        # Check if already awarded
        my $already_awarded = quest::get_data("classic_awarded_" . $char_id);
        if ($already_awarded) {
            plugin::Whisper("You have already claimed your Classic rewards!");
            return;
        }
        
        # Verify completion
        my $has_nagafen = quest::get_data("classic_nagafen_" . $account_id);
        my $has_vox = quest::get_data("classic_vox_" . $account_id);
        
        if ($has_nagafen && $has_vox) {
            # Award items and titles
            $client->SummonItem(2854);
            $client->SummonItem(17662);
            
            # Grant titles
            quest::enabletitle(398);
            quest::enabletitle(399);
            quest::enabletitle(400);
            
            # Mark as awarded (permanent)
            quest::set_data("classic_awarded_" . $char_id, $client->GetCleanName());
            
            # World announcement
            my $char_name = $client->GetCleanName();
            quest::we(15, "$char_name has claimed their Classic era rewards for defeating Lord Nagafen and Lady Vox! Congratulations, champion!");
            
            # Messages
            $client->Message(15, "═══════════════════════════════════════════════════");
            $client->Message(15, "Classic Era Rewards Claimed!");
            $client->Message(15, "You received the Charm of the First Age, a special reward, and unlocked three new titles!");
            $client->Message(15, "═══════════════════════════════════════════════════");
            
            plugin::Whisper("Congratulations, $name! Your Classic era achievements have been rewarded. Wear them with pride!");
        }
        else {
            plugin::Whisper("I cannot grant you the rewards. You must defeat both Lord Nagafen and Lady Vox first.");
        }
    }
    elsif ($popupid == 5002) {
        plugin::Whisper("Very well. Return when you are ready to claim your rewards.");
    }
    elsif ($popupid == 5003) {
        # Kunark rewards claim
        my $char_id = $client->CharacterID();
        
        # Check if already awarded
        my $already_awarded = quest::get_data("kunark_awarded_" . $char_id);
        if ($already_awarded) {
            plugin::Whisper("You have already claimed your Kunark rewards!");
            return;
        }
        
        # Verify completion (Kunark uses account_id key, char_name value)
        my $account_id = $client->AccountID();
        my $char_name  = $client->GetCleanName();
        my $has_talendor   = quest::get_data("kunark_talendor_"   . $account_id);
        my $has_severilous = quest::get_data("kunark_severilous_" . $account_id);
        my $has_trakanon   = quest::get_data("kunark_trakanon_"   . $account_id);

        $has_talendor   = ($has_talendor   && $has_talendor   eq $char_name) ? 1 : 0;
        $has_severilous = ($has_severilous && $has_severilous eq $char_name) ? 1 : 0;
        $has_trakanon   = ($has_trakanon   && $has_trakanon   eq $char_name) ? 1 : 0;

        if ($has_talendor && $has_severilous && $has_trakanon) {
            # Award item and titles (no charm yet)
            $client->SummonItem(17663);
            
            # Grant titles
            quest::enabletitle(401);
            quest::enabletitle(402);
            
            # Mark as awarded (permanent)
            quest::set_data("kunark_awarded_" . $char_id, $client->GetCleanName());
            
            # World announcement
            quest::we(15, "$char_name has claimed their Kunark era rewards for defeating Talendor, Severilous, and Trakanon! Congratulations, champion!");
            
            # Messages
            $client->Message(15, "═══════════════════════════════════════════════════");
            $client->Message(15, "Kunark Era Rewards Claimed!");
            $client->Message(15, "You received a special reward and unlocked two new titles!");
            $client->Message(15, "═══════════════════════════════════════════════════");
            
            plugin::Whisper("Congratulations, $name! Your Kunark era achievements have been rewarded. Now hand me your Charm of the First Age and I will upgrade it to the Charm of the Second Age!");
        }
        else {
            plugin::Whisper("I cannot grant you the rewards. You must defeat Talendor, Severilous, and Trakanon first.");
        }
    }
    elsif ($popupid == 5004) {
        plugin::Whisper("Very well. Return when you are ready to claim your rewards.");
    }
    elsif ($popupid == 5005) {
        # Velious rewards claim
        my $char_id = $client->CharacterID();

        # Check if already awarded
        my $already_awarded = quest::get_data("velious_awarded_" . $char_id);
        if ($already_awarded) {
            plugin::Whisper("You have already claimed your Velious rewards!");
            return;
        }

        # Verify completion
        my $account_id = $client->AccountID();
        my $char_name  = $client->GetCleanName();
        my $has_wuoshi     = quest::get_data("velious_wuoshi_"          . $account_id);
        my $has_kelorekdar = quest::get_data("velious_kelorekdar_"      . $account_id);
        my $has_klandicar  = quest::get_data("velious_klandicar_"       . $account_id);
        my $has_zlandicar  = quest::get_data("velious_zlandicar_"       . $account_id);
        my $has_statue     = quest::get_data("velious_statue_rallos_zek_" . $account_id);

        $has_wuoshi     = ($has_wuoshi     && $has_wuoshi     eq $char_name) ? 1 : 0;
        $has_kelorekdar = ($has_kelorekdar && $has_kelorekdar eq $char_name) ? 1 : 0;
        $has_klandicar  = ($has_klandicar  && $has_klandicar  eq $char_name) ? 1 : 0;
        $has_zlandicar  = ($has_zlandicar  && $has_zlandicar  eq $char_name) ? 1 : 0;
        $has_statue     = ($has_statue     && $has_statue     eq $char_name) ? 1 : 0;

        if ($has_wuoshi && $has_kelorekdar && $has_klandicar && $has_zlandicar && $has_statue) {
            # Award items and titles
            # TODO: Add reward item ID here
            # $client->SummonItem(ITEM_ID);

            # TODO: Add title IDs here
            # quest::enabletitle(TITLE_ID);

            # Mark as awarded (permanent)
            quest::set_data("velious_awarded_" . $char_id, $client->GetCleanName());

            # World announcement
            quest::we(15, "$char_name has claimed their Velious era rewards for conquering the frozen continent! Congratulations, champion!");

            # Messages
            $client->Message(15, "═══════════════════════════════════════════════════");
            $client->Message(15, "Velious Era Rewards Claimed!");
            $client->Message(15, "You received your Velious era rewards!");
            $client->Message(15, "═══════════════════════════════════════════════════");

            plugin::Whisper("Congratulations, $name! Your Velious era achievements have been rewarded. The frozen continent bows to your might!");
        }
        else {
            plugin::Whisper("I cannot grant you the rewards. You must defeat all five Velious bosses first.");
        }
    }
    elsif ($popupid == 5006) {
        plugin::Whisper("Very well. Return when you are ready to claim your rewards.");
    }
}

1;
