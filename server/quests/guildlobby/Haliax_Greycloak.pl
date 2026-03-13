# Haliax Greycloak - AA Credit Display & Redemption NPC (Guild Lobby)
# Author: Straps
#
# Shows per-class, per-tier credit balances in a color-coded popup grid.
# Credits are stored in quest::get_data buckets keyed by character ID, tier, and class.
# Players can redeem credits for unspent AA points — either bulk (drains lowest tier first)
# or targeted by specific tier+class. Also handles buyback of old translated tomes
# from the previous system, refunding platinum and returning the illegible tome.

sub EVENT_SAY {
    if ($text =~ /hail/i) {
        my $credits_link = quest::saylink("my credits", 1, "my credits");
        plugin::Whisper("Greetings, $name. I am Haliax Greycloak, a scholar of ancient knowledge. The old translation system has been replaced with a new [training] system. You may also check [$credits_link] to view and redeem your AA training credits.");
    }
    elsif ($text =~ /my credits/i) {
        _show_credits($client);
    }
    elsif ($text =~ /^redeem (\d+)$/i) {
        _do_redeem($client, $1);
    }
    elsif ($text =~ /^redeem (greater|exalted|ascendant) (\d+) (\d+)$/i) {
        _do_redeem_tier($client, lc($1), $2, $3);
    }
    elsif ($text =~ /training/i) {
        my $popup_text = "<c \"#00FFFF\">New AA Training System</c><br><br>" .
            "The guild masters of each class now offer direct training in cross-class abilities.<br><br>" .
            "<c \"#FFFF00\">How It Works:</c><br>" .
            "1. Bring <c \"#FFD700\">illegible tomes</c> + platinum to any guild master<br>" .
            "2. They will decipher the tome and grant you <c \"#00FF00\">training credits</c><br>" .
            "3. Use credits to purchase cross-class abilities from that guild master<br><br>" .
            "<c \"#FFFF00\">Credit Costs:</c><br>" .
            "- <c \"#00FF00\">Greater Tome</c> + 100pp = 1 Greater Credit<br>" .
            "- <c \"#00CCFF\">Exalted Tome</c> + 300pp = 1 Exalted Credit<br>" .
            "- <c \"#CC66FF\">Ascendant Tome</c> + 500pp = 1 Ascendant Credit<br><br>" .
            "<c \"#AAAAAA\">Each credit buys one rank of its tier. You cannot purchase your own class abilities - those are earned through experience.</c><br><br>" .
            "<c \"#FFD700\">Old Translated Tomes:</c><br>" .
            "If you have old translated tomes from the previous system, I will [buyback] them for their original cost and return the matching illegible tome.";
        quest::popup("Haliax Greycloak - AA Training", $popup_text, 0, 0, 0);
    }
    elsif ($text =~ /buyback/i) {
        plugin::Whisper("Hand me any old translated tomes and I will refund their cost and return the matching illegible tome.");
    }
}

sub EVENT_ITEM {
    my $total_bought = 0;
    my $total_refund = 0;
    my $tier_name    = "";
    my $found_tome   = 0;

    my $dbh = plugin::LoadMysql();
    unless ($dbh) {
        plugin::Whisper("Database unavailable.");
        plugin::return_items(\%itemcount);
        return;
    }

    foreach my $item_id (keys %itemcount) {
        next unless $item_id && $item_id > 0;
        if ($item_id >= 121620 && $item_id <= 121847) {
            $found_tome = 1;

            my ($item_name, $illegible_tome_id) = $dbh->selectrow_array(
                "SELECT i.Name, acm.illegible_tome_id " .
                "FROM items i " .
                "LEFT JOIN aa_custom_mapping acm ON acm.tome_item_id = i.id " .
                "WHERE i.id = ?",
                undef, $item_id
            );

            unless ($item_name && $illegible_tome_id) {
                plugin::Whisper("Cannot find mapping for this tome. Please report this issue.");
                plugin::return_items(\%itemcount);
                return;
            }

            my $cost = 0;
            if    ($item_name =~ /\(Greater\)/i)   { $cost = 100; $tier_name = "Greater";   }
            elsif ($item_name =~ /\(Exalted\)/i)   { $cost = 200; $tier_name = "Exalted";   }
            elsif ($item_name =~ /\(Ascendant\)/i) { $cost = 500; $tier_name = "Ascendant"; }
            else {
                plugin::Whisper("Cannot determine tier for this tome. Please report this issue.");
                plugin::return_items(\%itemcount);
                return;
            }

            while (quest::handin({$item_id => 1})) {
                $client->AddMoneyToPP(0, 0, 0, $cost, 1);
                quest::summonitem($illegible_tome_id);
                $total_bought++;
                $total_refund += $cost;
            }
            last;
        }
    }

    if ($found_tome && $total_bought > 0) {
        quest::ding();
        my $plural = $total_bought > 1 ? "s" : "";
        plugin::Whisper("I have bought back $total_bought tome$plural. You received ${total_refund}pp and $total_bought illegible $tier_name tome$plural.");
    } else {
        plugin::Whisper("I have no use for this. Bring me old translated tomes for buyback, or speak to guild masters about the new training system.");
        plugin::return_items(\%itemcount);
    }
}

# -------------------------------------------------------
# _show_credits - popup showing all non-zero credit balances
# -------------------------------------------------------
sub _show_credits {
    my ($client) = @_;
    my $char_id = $client->CharacterID();
    my %tier_buckets = (1 => 'greater_credits', 2 => 'exalted_credits', 3 => 'ascendant_credits');
    my %tier_names   = (1 => 'Greater',  2 => 'Exalted',  3 => 'Ascendant');
    my %tier_colors  = (1 => '#00FF00',  2 => '#00CCFF',  3 => '#CC66FF');
    my %class_names  = (
        1  => 'Warrior',      2  => 'Cleric',       3  => 'Paladin',
        4  => 'Ranger',       5  => 'Shadow Knight', 6  => 'Druid',
        7  => 'Monk',         8  => 'Bard',          9  => 'Rogue',
        10 => 'Shaman',       11 => 'Necromancer',   12 => 'Wizard',
        13 => 'Magician',     14 => 'Enchanter',     15 => 'Beastlord',
        16 => 'Berserker',
    );

    my $total = 0;
    my %data;
    for my $class_id (1..16) {
        for my $tier (1..3) {
            my $val = int(quest::get_data("character-${char_id}-$tier_buckets{$tier}_${class_id}") || 0);
            $data{$class_id}{$tier} = $val;
            $total += $val;
        }
    }

    # Build full popup with all classes and tiers (including zeros)
    my $popup = "<c \"#FFD700\">Your AA Training Credits</c><br>"
              . "<c \"#AAAAAA\">Total: $total | Each credit = 1 unspent AA point</c><br>"
              . "<c \"#AAAAAA\">Click the numbers in chat below to redeem by tier and class.</c><br><br>";

    for my $class_id (1..16) {
        my $cname = $class_names{$class_id};
        my $row = "<c \"#FFFFFF\">$cname:</c> ";
        for my $tier (1..3) {
            my $val   = $data{$class_id}{$tier};
            my $color = $val > 0 ? $tier_colors{$tier} : '#555555';
            $row .= "<c \"$color\">$tier_names{$tier}:$val</c> ";
        }
        $popup .= "$row<br>";
    }

    $client->Popup2("Haliax Greycloak - Credits", $popup, 0, 0, 0, 0);

    # Chat lines — only classes with credits, alternating colors
    $client->Message(15, "Your AA Training Credits (Total: $total) -- click to redeem");
    my $row_num = 0;
    for my $class_id (1..16) {
        my $class_total = 0;
        for my $tier (1..3) { $class_total += $data{$class_id}{$tier}; }
        next unless $class_total > 0;

        my $line = "$class_names{$class_id}: ";
        for my $tier (1..3) {
            my $val   = $data{$class_id}{$tier};
            my $tname = $tier_names{$tier};
            my $slug  = lc($tname);
            if ($val > 0) {
                my $r1 = quest::saylink("redeem ${slug} ${class_id} 1", 1, "1");
                my $r5 = quest::saylink("redeem ${slug} ${class_id} 5", 1, "5");
                $line .= "$tname:$val ($r1|$r5)  ";
            } else {
                $line .= "$tname:$val  ";
            }
        }
        $client->Message(18, $line);
        $row_num++;
    }
}

# -------------------------------------------------------
# _show_redeem - whisper redeem options
# -------------------------------------------------------
sub _show_redeem {
    my ($client) = @_;
    my $char_id = $client->CharacterID();
    my %tier_buckets = (1 => 'greater_credits', 2 => 'exalted_credits', 3 => 'ascendant_credits');
    my $total = 0;
    for my $class_id (1..16) {
        for my $tier (1..3) {
            $total += int(quest::get_data("character-${char_id}-$tier_buckets{$tier}_${class_id}") || 0);
        }
    }
    if ($total == 0) {
        plugin::Whisper("You have no credits to redeem.");
        return;
    }
    my $r1  = quest::saylink("redeem 1",  1, "Redeem 1");
    my $r5  = quest::saylink("redeem 5",  1, "Redeem 5");
    my $r10 = quest::saylink("redeem 10", 1, "Redeem 10");
    plugin::Whisper("You have $total credits available. Each credit = 1 unspent AA point. $r1 | $r5 | $r10");
}

# -------------------------------------------------------
# _do_redeem - consume credits and award AA points
# Drains tier 1 first, then 2, then 3, across all classes
# -------------------------------------------------------
sub _do_redeem {
    my ($client, $requested) = @_;
    my $char_id = $client->CharacterID();
    my %tier_buckets = (1 => 'greater_credits', 2 => 'exalted_credits', 3 => 'ascendant_credits');

    my $total = 0;
    for my $class_id (1..16) {
        for my $tier (1..3) {
            $total += int(quest::get_data("character-${char_id}-$tier_buckets{$tier}_${class_id}") || 0);
        }
    }

    if ($total == 0) {
        plugin::Whisper("You have no credits to redeem.");
        return;
    }

    my $to_redeem = $requested > $total ? $total : $requested;
    my $remaining = $to_redeem;

    for my $tier (1..3) {
        last unless $remaining > 0;
        for my $class_id (1..16) {
            last unless $remaining > 0;
            my $key = "character-${char_id}-$tier_buckets{$tier}_${class_id}";
            my $bal = int(quest::get_data($key) || 0);
            next unless $bal > 0;
            my $take = $bal >= $remaining ? $remaining : $bal;
            quest::set_data($key, $bal - $take);
            $remaining -= $take;
        }
    }

    my $redeemed = $to_redeem - $remaining;
    $client->SetAAPoints($client->GetAAPoints() + $redeemed);
    plugin::Whisper("Haliax nods. You have redeemed $redeemed credit" . ($redeemed > 1 ? "s" : "") . " for $redeemed unspent AA point" . ($redeemed > 1 ? "s" : "") . ".");
    plugin::Whisper("You only had $total credits available.") if $requested > $total;
}

# -------------------------------------------------------
# _do_redeem_tier - redeem credits from a specific tier + class
# -------------------------------------------------------
sub _do_redeem_tier {
    my ($client, $tier_slug, $class_id, $requested) = @_;
    my $char_id = $client->CharacterID();
    my %slug_to_bucket = (
        'greater'   => 'greater_credits',
        'exalted'   => 'exalted_credits',
        'ascendant' => 'ascendant_credits',
    );
    my %slug_to_name = (
        'greater' => 'Greater', 'exalted' => 'Exalted', 'ascendant' => 'Ascendant',
    );
    my %class_names = (
        1  => 'Warrior',      2  => 'Cleric',       3  => 'Paladin',
        4  => 'Ranger',       5  => 'Shadow Knight', 6  => 'Druid',
        7  => 'Monk',         8  => 'Bard',          9  => 'Rogue',
        10 => 'Shaman',       11 => 'Necromancer',   12 => 'Wizard',
        13 => 'Magician',     14 => 'Enchanter',     15 => 'Beastlord',
        16 => 'Berserker',
    );

    my $bucket = $slug_to_bucket{$tier_slug};
    unless ($bucket) {
        plugin::Whisper("Unknown tier.");
        return;
    }

    my $key = "character-${char_id}-${bucket}_${class_id}";
    my $bal = int(quest::get_data($key) || 0);

    if ($bal == 0) {
        plugin::Whisper("You have no $slug_to_name{$tier_slug} credits for $class_names{$class_id}.");
        return;
    }

    my $take = $requested > $bal ? $bal : $requested;
    quest::set_data($key, $bal - $take);
    $client->SetAAPoints($client->GetAAPoints() + $take);
    plugin::Whisper("Redeemed $take $slug_to_name{$tier_slug} credit" . ($take > 1 ? "s" : "") . " ($class_names{$class_id}) for $take unspent AA point" . ($take > 1 ? "s" : "") . ". Remaining: " . ($bal - $take) . ".");
}

1;
