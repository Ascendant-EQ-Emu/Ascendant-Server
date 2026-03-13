# ============================================================
# Ascendant Training System - Plugin
# Handles illegible tome turn-in, tiered credits, AA browsing,
# prerequisite checking, and AA rank purchasing.
#
# All public functions take $trainer_class (1-16) so each guild
# master only teaches their class's AAs and accepts their tomes.
# ============================================================

# ── Server progression constant ──
# Update this when a new expansion unlocks on the server.
# Expansion numbers: 0-9=Classic, 10-11=Kunark, 12-14=Velious, 15=Luclin, 16=PoP, 17+=GoD+
my $CURRENT_MAX_EXPANSION = 11;  # Currently: Kunark

# ── Economy constants ──
# Each tome gives 1 credit of its tier; each AA rank costs 1 credit of its tier
my %TIER_PLAT_COST = (1 => 100,  2 => 300,  3 => 500);
my %TIER_NAMES     = (1 => 'Greater', 2 => 'Exalted', 3 => 'Ascendant');
my %TIER_COLORS    = (1 => '#00FF00', 2 => '#00CCFF', 3 => '#CC66FF');
my %TIER_BUCKET    = (1 => 'greater_credits', 2 => 'exalted_credits', 3 => 'ascendant_credits');

# ── $client->Message() color IDs (emote colors) ──
# IMPORTANT: Use IDs 0-19 only — higher IDs route to different chat windows
my $COLOR_HEADING = 18;   # cyan (headings, links, nav)
my $COLOR_GOLD    = 15;   # yellow (currency amounts)
my $COLOR_GREEN   = 14;   # light green (success/ready/buy)
my $COLOR_RED     = 13;   # red (errors)
my $COLOR_GRAY    = 12;   # light silver (muted/maxed)
my $COLOR_WHITE   = 0;    # white (default text)
my $COLOR_TEAL    = 5;    # light purple (tier accent)

# ── Class names for display ──
my %CLASS_NAMES = (
    1  => 'Warrior',     2  => 'Cleric',      3  => 'Paladin',
    4  => 'Ranger',      5  => 'Shadow Knight',6  => 'Druid',
    7  => 'Monk',        8  => 'Bard',        9  => 'Rogue',
    10 => 'Shaman',      11 => 'Necromancer', 12 => 'Wizard',
    13 => 'Magician',    14 => 'Enchanter',   15 => 'Beastlord',
    16 => 'Berserker',
);

# ── Illegible tome ID ranges (121571-121618, 3 per class × 16 classes) ──
# Formula: base = 121571 + (class - 1) * 3; T1=base, T2=base+1, T3=base+2
sub _get_tome_info {
    my ($item_id) = @_;
    return (0, 0) unless ($item_id >= 121571 && $item_id <= 121618);
    my $index = $item_id - 121571;
    my $tome_class = int($index / 3) + 1;   # 1-16
    my $tome_tier  = ($index % 3) + 1;      # 1-3
    return ($tome_class, $tome_tier);
}

# Items per page for AA browser popup
my $ITEMS_PER_PAGE = 10;

# ── Convert trainer class (1-16) to bitmask ──
sub _class_bitmask {
    my ($class_num) = @_;
    return 1 << ($class_num - 1);
}

# ============================================================
# GetCreditBalance - Read credit balance for a specific tier + class
# Key: character-{charid}-{tier}_credits_{class}
# ============================================================
sub GetCreditBalance {
    my ($client, $tier, $trainer_class) = @_;
    my $char_id = $client->CharacterID();
    my $suffix = $TIER_BUCKET{$tier} || return 0;
    my $val = quest::get_data("character-${char_id}-${suffix}_${trainer_class}");
    return int($val || 0);
}

# ============================================================
# _set_credit_balance - Write credit balance for a specific tier + class
# ============================================================
sub _set_credit_balance {
    my ($client, $tier, $trainer_class, $amount) = @_;
    $amount = int($amount);
    $amount = 0 if $amount < 0;
    my $char_id = $client->CharacterID();
    my $suffix = $TIER_BUCKET{$tier} || return;
    quest::set_data("character-${char_id}-${suffix}_${trainer_class}", $amount);
}

# ============================================================
# GetAllBalances - Return hash of all 3 credit balances for a class
# ============================================================
sub GetAllBalances {
    my ($client, $trainer_class) = @_;
    return (
        1 => GetCreditBalance($client, 1, $trainer_class),
        2 => GetCreditBalance($client, 2, $trainer_class),
        3 => GetCreditBalance($client, 3, $trainer_class),
    );
}

# ============================================================
# HandleTomeTurnin - Accept illegible tome stacks + plat, award credits
# Only accepts tomes matching $trainer_class.
# Processes stacks using while loop pattern.
# Returns: 1 if any tomes consumed, 0 otherwise
# ============================================================
sub HandleTomeTurnin {
    my ($npc, $client, $itemcount_ref, $trainer_class) = @_;

    my $trainer_name = $CLASS_NAMES{$trainer_class} || "Unknown";
    my $total_consumed = 0;
    my $tome_tier = 0;
    my $tier_name = "";

    # Find the first tome in the handin
    foreach my $item_id (keys %{$itemcount_ref}) {
        next unless $item_id;
        my ($tome_class, $tier) = _get_tome_info($item_id);
        next unless $tier;

        # Reject tomes for a different class
        if ($tome_class != $trainer_class) {
            my $tome_class_name = $CLASS_NAMES{$tome_class} || "Unknown";
            $client->Message($COLOR_RED, "This is a $tome_class_name tome. I only accept $trainer_name tomes. Seek the $tome_class_name guild master instead.");
            return 0;
        }

        $tome_tier = $tier;
        $tier_name = $TIER_NAMES{$tier};

        my $cost_pp = $TIER_PLAT_COST{$tier};
        my $cost_copper = $cost_pp * 1000;

        # Check platinum BEFORE consuming any tomes
        if ($client->GetCarriedMoney() < $cost_copper) {
            $client->Message($COLOR_RED, "Deciphering a $tier_name tome requires $cost_pp platinum. You do not carry enough.");
            return 0;
        }

        # Process stack using while loop — plat checked before each handin
        while ($client->GetCarriedMoney() >= $cost_copper && quest::handin({$item_id => 1})) {
            # Take plat
            $client->TakeMoneyFromPP($cost_copper, 1);

            # Award 1 credit
            my $current = GetCreditBalance($client, $tier, $trainer_class);
            _set_credit_balance($client, $tier, $trainer_class, $current + 1);

            $total_consumed++;
        }

        last; # Only process one item type per handin
    }

    if ($total_consumed > 0) {
        quest::ding();
        my $plural = $total_consumed > 1 ? "s" : "";
        my $total_cost_pp = $TIER_PLAT_COST{$tome_tier} * $total_consumed;
        my $new_balance = GetCreditBalance($client, $tome_tier, $trainer_class);
        $client->Message($COLOR_GREEN, "I have deciphered $total_consumed tome$plural for $total_cost_pp platinum. You received $total_consumed $tier_name $trainer_name Credit$plural. (Total: $new_balance)");
        quest::debug("InsightTrainer: $trainer_name $tier_name tome turn-in x$total_consumed, cost=${total_cost_pp}pp, new balance=$new_balance");
        return 1;
    }

    return 0;
}

# ============================================================
# ShowAllAACredits - Display all credits across all class trainers
# Used by /myaacredits player command
# ============================================================
sub ShowAllAACredits {
    my ($client) = @_;

    my $popup = "<c \"#FFD700\">Your AA Training Credits</c><br><br>";
    
    # Loop through all 16 classes and show all, even with 0 credits
    for my $class_id (1..16) {
        my $class_name = $CLASS_NAMES{$class_id};
        my %bal = GetAllBalances($client, $class_id);
        
        $popup .= "<c \"#FFFFFF\">$class_name:</c> ";
        $popup .= "<c \"#00FF00\">G:$bal{1}</c> ";
        $popup .= "<c \"#00CCFF\">E:$bal{2}</c> ";
        $popup .= "<c \"#CC66FF\">A:$bal{3}</c><br>";
    }
    
    $popup .= "<br><c \"#AAAAAA\">Visit guild masters to browse and purchase abilities.</c>";
    quest::popup("AA Training Credits", $popup, 0, 0, 0);
}

# ============================================================
# ShowBalance - Display current credit balances
# ============================================================
sub ShowBalance {
    my ($client, $trainer_class) = @_;
    my %bal = GetAllBalances($client, $trainer_class);
    my $class_name = $CLASS_NAMES{$trainer_class} || "Unknown";

    my $popup = "<c \"#FFD700\">$class_name Training - Credits</c><br><br>";
    $popup .= "<c \"#AAAAAA\">Your Credits:</c><br>";
    $popup .= "  <c \"#00FF00\">Greater Credits:</c> <c \"#FFFFFF\">$bal{1}</c><br>";
    $popup .= "  <c \"#00CCFF\">Exalted Credits:</c> <c \"#FFFFFF\">$bal{2}</c><br>";
    $popup .= "  <c \"#CC66FF\">Ascendant Credits:</c> <c \"#FFFFFF\">$bal{3}</c><br><br>";
    $popup .= "<c \"#AAAAAA\">Earn credits by turning in $class_name illegible tomes:</c><br>";
    $popup .= "- <c \"#00FF00\">Greater Tome</c> + 100pp = 1 Greater Credit<br>";
    $popup .= "- <c \"#00CCFF\">Exalted Tome</c> + 300pp = 1 Exalted Credit<br>";
    $popup .= "- <c \"#CC66FF\">Ascendant Tome</c> + 500pp = 1 Ascendant Credit<br><br>";
    $popup .= "<c \"#AAAAAA\">Each credit buys one rank of its tier:</c><br>";
    $popup .= "- 1 <c \"#00FF00\">Greater Credit</c> = 1 Greater AA rank<br>";
    $popup .= "- 1 <c \"#00CCFF\">Exalted Credit</c> = 1 Exalted AA rank<br>";
    $popup .= "- 1 <c \"#CC66FF\">Ascendant Credit</c> = 1 Ascendant AA rank";
    quest::popup("$class_name Training", $popup, 0, 0, 0);
    $client->Message($COLOR_HEADING, quest::saylink("train", 1, "[Browse $class_name Abilities]") . "  " . quest::saylink("balance", 1, "[Refresh Balance]"));
}

# ============================================================
# ShowTrainingMenu - Paginated AA browser popup
# Only shows AAs whose original_classes includes $trainer_class.
# ============================================================
sub ShowTrainingMenu {
    my ($client, $page, $filter, $trainer_class) = @_;
    $page = 0 unless defined $page;
    $filter = '' unless defined $filter;

    my $dbh = plugin::LoadMysql();
    unless ($dbh) {
        $client->Message($COLOR_RED, "The training records are unavailable. Please try again later.");
        return;
    }

    my %bal = GetAllBalances($client, $trainer_class);
    my $class_name = $CLASS_NAMES{$trainer_class} || "Unknown";
    my $class_bitmask = _class_bitmask($trainer_class);

    # Fetch AAs for this class from mapping
    my @where = ("(acm.original_classes & $class_bitmask) > 0");
    my @params;
    if ($filter =~ /^[123]$/) {
        push @where, "acm.tier = ?";
        push @params, int($filter);
    }
    my $where_clause = "WHERE " . join(" AND ", @where);

    # Also filter to current expansion only
    push @where, "ur.expansion <= ?";
    push @params, $CURRENT_MAX_EXPANSION;

    $where_clause = "WHERE " . join(" AND ", @where);

    my $sth = $dbh->prepare(
        "SELECT acm.universal_aa_id, acm.aa_name, acm.tier, acm.original_classes, " .
        "ua.first_rank_id AS universal_first_rank_id, " .
        "oa.first_rank_id AS original_first_rank_id " .
        "FROM aa_custom_mapping acm " .
        "JOIN aa_ability ua ON ua.id = acm.universal_aa_id " .
        "JOIN aa_ability oa ON oa.id = acm.original_aa_id " .
        "JOIN aa_ranks ur ON ur.id = ua.first_rank_id " .
        "$where_clause " .
        "ORDER BY acm.tier, acm.aa_name"
    );
    $sth->execute(@params);

    my @all_aas;
    while (my $row = $sth->fetchrow_hashref()) {
        push @all_aas, $row;
    }
    $sth->finish();

    my $total = scalar @all_aas;
    my $total_pages = int(($total + $ITEMS_PER_PAGE - 1) / $ITEMS_PER_PAGE);
    $page = 0 if $page < 0;
    $page = $total_pages - 1 if $page >= $total_pages && $total_pages > 0;

    my $start = $page * $ITEMS_PER_PAGE;
    my $end = $start + $ITEMS_PER_PAGE - 1;
    $end = $total - 1 if $end >= $total;

    # Header with all 3 balances
    $client->Message($COLOR_HEADING, "--- $class_name AA Training --- G:$bal{1} E:$bal{2} A:$bal{3} --- (" . ($start + 1) . "-" . ($end + 1) . " of $total, page " . ($page + 1) . "/$total_pages) ---");

    # Get player class for native access check
    my $player_class = $client->GetClass();
    my $player_bitmask = 1 << ($player_class - 1);

    # Only hide AAs where the next rank requires level > 60.
    # Maxed AAs and prereq-blocked AAs always remain visible.
    @all_aas = grep {
        my $frid = (($_->{original_classes} & $player_bitmask) > 0)
                   ? $_->{original_first_rank_id}
                   : $_->{universal_first_rank_id};
        my $cur          = $client->GetAALevel($frid);
        my $next_rank_id = _get_nth_rank_id($dbh, $frid, $cur);
        if (!$next_rank_id) {
            1;  # maxed — always show
        } else {
            my ($req) = $dbh->selectrow_array(
                "SELECT level_req FROM aa_ranks WHERE id = ?", undef, $next_rank_id
            );
            !$req || $req == 0 || $req <= 60;  # hide only if level_req > 60
        }
    } @all_aas;

    # Recompute totals after filter
    $total = scalar @all_aas;
    $total_pages = int(($total + $ITEMS_PER_PAGE - 1) / $ITEMS_PER_PAGE);
    $page = 0 if $page < 0;
    $page = $total_pages - 1 if $page >= $total_pages && $total_pages > 0;
    $start = $page * $ITEMS_PER_PAGE;
    $end = $start + $ITEMS_PER_PAGE - 1;
    $end = $total - 1 if $end >= $total;

    for (my $i = $start; $i <= $end; $i++) {
        my $aa = $all_aas[$i];
        my $uid = $aa->{universal_aa_id};
        my $name = $aa->{aa_name};
        my $tier = $aa->{tier};
        my $tier_name = $TIER_NAMES{$tier};
        my $tier_balance = $bal{$tier} || 0;

        # Check if player has native access to determine which first_rank_id to use
        my $has_native = ($aa->{original_classes} & $player_bitmask) ? 1 : 0;
        my $first_rank_id = $has_native ? $aa->{original_first_rank_id} : $aa->{universal_first_rank_id};

        my $current_rank = $client->GetAALevel($first_rank_id);
        my $max_rank = _count_ranks($dbh, $first_rank_id);

        if ($current_rank >= $max_rank) {
            $client->Message($COLOR_GRAY,
                "($tier_name) " . quest::saylink("aainfo $uid", 1, $name) . " $current_rank/$max_rank (MAXED)");
        } else {
            my $can_buy = _check_can_buy($dbh, $client, $first_rank_id, $current_rank, $tier_balance, 1);

            my $line = "($tier_name) " . quest::saylink("aainfo $uid", 1, $name) . " $current_rank/$max_rank";
            if ($can_buy) {
                $line .= " " . quest::saylink("buyaa $uid", 1, "[Buy]");
            }
            $client->Message($COLOR_HEADING, $line);
        }
    }

    # Pagination (silent saylinks)
    my $filter_key = $filter eq '' ? 'all' : "t$filter";
    my $nav = "";
    if ($page > 0) {
        my $prev = $page - 1;
        $nav .= quest::saylink("train $filter_key $prev", 1, "<< Prev") . '  ';
    }
    if ($page < $total_pages - 1) {
        my $nxt = $page + 1;
        $nav .= quest::saylink("train $filter_key $nxt", 1, "Next >>") . '  ';
    }
    $client->Message($COLOR_HEADING, $nav) if $nav;
}

# ============================================================
# ShowAADetail - Detail popup for a single AA
# Validates the AA belongs to $trainer_class before showing.
# ============================================================
sub ShowAADetail {
    my ($client, $universal_aa_id, $trainer_class) = @_;

    my $dbh = plugin::LoadMysql();
    unless ($dbh) {
        $client->Message($COLOR_RED, "The training records are unavailable.");
        return;
    }

    my $class_name = $CLASS_NAMES{$trainer_class} || "Unknown";
    my $class_bitmask = _class_bitmask($trainer_class);

    # Get mapping info
    my $sth = $dbh->prepare(
        "SELECT acm.universal_aa_id, acm.original_aa_id, acm.aa_name, acm.tier, acm.original_classes, " .
        "ua.first_rank_id " .
        "FROM aa_custom_mapping acm " .
        "JOIN aa_ability ua ON ua.id = acm.universal_aa_id " .
        "WHERE acm.universal_aa_id = ?"
    );
    $sth->execute($universal_aa_id);
    my $aa = $sth->fetchrow_hashref();
    $sth->finish();

    unless ($aa) {
        $client->Message($COLOR_RED, "I cannot find that ability in my records.");
        return;
    }

    # Validate this AA belongs to this trainer's class
    unless (($aa->{original_classes} & $class_bitmask) > 0) {
        $client->Message($COLOR_RED, "That ability is not part of the $class_name discipline. Seek the appropriate guild master.");
        return;
    }

    my $tier = $aa->{tier};
    my $tier_name = $TIER_NAMES{$tier};
    my $tier_color = $TIER_COLORS{$tier};
    my $tier_balance = GetCreditBalance($client, $tier, $trainer_class);
    my $first_rank_id = $aa->{first_rank_id};
    my $current_rank = $client->GetAALevel($first_rank_id);
    my $max_rank = _count_ranks($dbh, $first_rank_id);

    # Get description from dbstrings
    my ($desc_sid) = $dbh->selectrow_array(
        "SELECT desc_sid FROM aa_ranks WHERE id = ?", undef, $first_rank_id
    );
    my $description = "";
    if ($desc_sid && $desc_sid > 0) {
        ($description) = $dbh->selectrow_array(
            "SELECT value FROM db_str WHERE id = ? AND type = 4", undef, $desc_sid
        );
    }

    # Get effects from first rank
    my $eff_sth = $dbh->prepare(
        "SELECT effect_id, base1, base2 FROM aa_rank_effects WHERE rank_id = ? ORDER BY slot"
    );
    $eff_sth->execute($first_rank_id);

    my @effects;
    while (my ($eid, $b1, $b2) = $eff_sth->fetchrow_array()) {
        push @effects, { id => $eid, base1 => $b1, base2 => $b2 };
    }
    $eff_sth->finish();

    # Get level requirement for next rank
    my $next_rank_id = _get_nth_rank_id($dbh, $first_rank_id, $current_rank);
    my $level_req = 0;
    if ($next_rank_id) {
        ($level_req) = $dbh->selectrow_array(
            "SELECT level_req FROM aa_ranks WHERE id = ?", undef, $next_rank_id
        );
    }

    # Check prerequisites
    my @prereqs;
    if ($next_rank_id) {
        my $pre_sth = $dbh->prepare(
            "SELECT rp.aa_id, rp.points, aa.name as aa_name " .
            "FROM aa_rank_prereqs rp " .
            "LEFT JOIN aa_ability aa ON aa.id = rp.aa_id " .
            "WHERE rp.rank_id = ?"
        );
        $pre_sth->execute($next_rank_id);
        while (my $p = $pre_sth->fetchrow_hashref()) {
            my $prereq_aa = $p->{aa_id};
            my $prereq_name = $p->{aa_name} || "AA $prereq_aa";
            my $prereq_points = $p->{points};

            my ($prereq_first_rank) = $dbh->selectrow_array(
                "SELECT first_rank_id FROM aa_ability WHERE id = ?", undef, $prereq_aa
            );
            my $player_prereq_rank = $prereq_first_rank ? $client->GetAALevel($prereq_first_rank) : 0;
            my $met = $player_prereq_rank >= $prereq_points ? 1 : 0;

            push @prereqs, {
                name => $prereq_name,
                required => $prereq_points,
                current => $player_prereq_rank,
                met => $met
            };
        }
        $pre_sth->finish();
    }

    # Static detail popup with <c> color tags
    my $popup = "<c \"$tier_color\">$aa->{aa_name}</c> <c \"#888888\">[$tier_name - $class_name]</c><br><br>";

    if ($description) {
        $popup .= "<c \"#CCCCCC\">$description</c><br><br>";
    }

    $popup .= "Rank: <c \"#FFFFFF\">$current_rank / $max_rank</c><br>";
    $popup .= "Cost: <c \"#FFD700\">1 $tier_name Credit per rank</c><br>";

    my $total_remaining = $max_rank - $current_rank;
    $popup .= "Remaining to Max: <c \"#FFD700\">$total_remaining $tier_name Credit" . ($total_remaining != 1 ? "s" : "") . "</c><br>";
    $popup .= "Your $tier_name Credits: <c \"#00FF00\">$tier_balance</c><br>";

    if ($level_req && $level_req > 0) {
        my $player_level = $client->GetLevel();
        my $level_color = $player_level >= $level_req ? "#00FF00" : "#FF4444";
        $popup .= "Level Required: <c \"$level_color\">$level_req</c> (You: $player_level)<br>";
    }

    $popup .= "<br>";

    # Effects
    if (@effects) {
        $popup .= "<c \"#00CCFF\">Effects:</c><br>";
        foreach my $eff (@effects) {
            $popup .= "  Effect $eff->{id}: base $eff->{base1}<br>";
        }
        $popup .= "<br>";
    }

    # Prerequisites
    if (@prereqs) {
        $popup .= "<c \"#FFA500\">Prerequisites:</c><br>";
        foreach my $p (@prereqs) {
            my $color = $p->{met} ? "#00FF00" : "#FF4444";
            my $check = $p->{met} ? "MET" : "NOT MET";
            $popup .= "  <c \"$color\">[$check]</c> $p->{name}: $p->{current}/$p->{required} ranks<br>";
        }
        $popup .= "<br>";
    }

    # Determine purchase status
    my $can_buy = 1;
    my $reason = "";

    if ($current_rank >= $max_rank) {
        $can_buy = 0;
        $reason = "Mastered";
    } else {
        if ($tier_balance < 1) {
            $can_buy = 0;
            $reason = "No $tier_name Credits ($tier_balance)";
        }
        if ($level_req && $level_req > 0 && $client->GetLevel() < $level_req) {
            $can_buy = 0;
            $reason = "Level too low (need $level_req)";
        }
        foreach my $p (@prereqs) {
            unless ($p->{met}) {
                $can_buy = 0;
                $reason = "Missing prerequisite: $p->{name}";
                last;
            }
        }
    }

    # Status in popup
    if ($current_rank >= $max_rank) {
        $popup .= "<c \"#888888\">You have mastered this ability.</c><br>";
    } elsif ($can_buy) {
        $popup .= "<c \"#00FF00\">Ready to purchase rank " . ($current_rank + 1) . "</c><br>";
    } else {
        $popup .= "<c \"#FF4444\">Cannot purchase: $reason</c><br>";
    }

    quest::popup("$aa->{aa_name} - $class_name", $popup, 0, 0, 0);
}

# ============================================================
# ShowBuyConfirmation - Yes/No popup to confirm AA purchase
# popup_id = universal_aa_id (used in EVENT_POPUPRESPONSE)
# ============================================================
sub ShowBuyConfirmation {
    my ($client, $universal_aa_id, $trainer_class) = @_;

    my $dbh = plugin::LoadMysql();
    unless ($dbh) {
        $client->Message($COLOR_RED, "The training records are unavailable.");
        return;
    }

    my $class_name = $CLASS_NAMES{$trainer_class} || "Unknown";
    my $class_bitmask = _class_bitmask($trainer_class);

    my $sth = $dbh->prepare(
        "SELECT acm.universal_aa_id, acm.aa_name, acm.tier, acm.original_classes, " .
        "ua.first_rank_id " .
        "FROM aa_custom_mapping acm " .
        "JOIN aa_ability ua ON ua.id = acm.universal_aa_id " .
        "WHERE acm.universal_aa_id = ?"
    );
    $sth->execute($universal_aa_id);
    my $aa = $sth->fetchrow_hashref();
    $sth->finish();

    unless ($aa && ($aa->{original_classes} & $class_bitmask) > 0) {
        $client->Message($COLOR_RED, "That ability is not available.");
        return;
    }

    my $tier = $aa->{tier};
    my $tier_name = $TIER_NAMES{$tier};
    my $tier_balance = GetCreditBalance($client, $tier, $trainer_class);
    my $first_rank_id = $aa->{first_rank_id};
    my $current_rank = $client->GetAALevel($first_rank_id);
    my $max_rank = _count_ranks($dbh, $first_rank_id);

    if ($current_rank >= $max_rank) {
        $client->Message($COLOR_GRAY, "You have already mastered $aa->{aa_name}.");
        return;
    }

    my $can_buy = _check_can_buy($dbh, $client, $first_rank_id, $current_rank, $tier_balance, 1);
    unless ($can_buy) {
        $client->Message($COLOR_RED, "You cannot purchase $aa->{aa_name} right now. Check your credits, level, and prerequisites.");
        return;
    }

    my $next_rank = $current_rank + 1;
    my $popup = "<c \"#FFD700\">Confirm Purchase</c><br><br>";
    $popup .= "Ability: <c \"#FFFFFF\">$aa->{aa_name}</c><br>";
    $popup .= "Tier: <c \"$TIER_COLORS{$tier}\">$tier_name</c><br>";
    $popup .= "Rank: <c \"#FFFFFF\">$current_rank -> $next_rank</c> of $max_rank<br><br>";
    $popup .= "Cost: <c \"#FFD700\">1 $tier_name Credit</c><br>";
    $popup .= "Your $tier_name Credits: <c \"#00FF00\">$tier_balance</c><br>";
    $popup .= "After Purchase: <c \"#00FF00\">" . ($tier_balance - 1) . "</c><br><br>";
    $popup .= "<c \"#AAAAAA\">Click Yes to confirm purchase.</c>";

    # popup_id = universal_aa_id, buttons = 1 (Yes/No)
    quest::popup("Confirm: $aa->{aa_name}", $popup, $universal_aa_id, 1, 0);
}

# ============================================================
# HandlePopupResponse - Process Yes click on buy confirmation
# Called from EVENT_POPUPRESPONSE in NPC script
# ============================================================
sub HandlePopupResponse {
    my ($client, $popup_id, $trainer_class) = @_;

    # popup_id is the universal_aa_id from ShowBuyConfirmation
    # Only process if it looks like a valid AA ID (> 0)
    return 0 unless $popup_id && $popup_id > 0;

    HandleTrainRequest($client, $popup_id, $trainer_class);
    return 1;
}

# ============================================================
# HandleTrainRequest - Validate and grant a single AA rank
# Validates the AA belongs to $trainer_class before granting.
# ============================================================
sub HandleTrainRequest {
    my ($client, $universal_aa_id, $trainer_class) = @_;

    my $dbh = plugin::LoadMysql();
    unless ($dbh) {
        $client->Message($COLOR_RED, "The training records are unavailable.");
        return 0;
    }

    my $class_name = $CLASS_NAMES{$trainer_class} || "Unknown";
    my $class_bitmask = _class_bitmask($trainer_class);

    # Get mapping info
    my $sth = $dbh->prepare(
        "SELECT acm.universal_aa_id, acm.original_aa_id, acm.aa_name, acm.tier, acm.original_classes, " .
        "ua.first_rank_id AS universal_first_rank_id, " .
        "oa.first_rank_id AS original_first_rank_id " .
        "FROM aa_custom_mapping acm " .
        "JOIN aa_ability ua ON ua.id = acm.universal_aa_id " .
        "JOIN aa_ability oa ON oa.id = acm.original_aa_id " .
        "WHERE acm.universal_aa_id = ?"
    );
    $sth->execute($universal_aa_id);
    my $aa = $sth->fetchrow_hashref();
    $sth->finish();

    unless ($aa) {
        $client->Message($COLOR_RED, "I cannot find that ability.");
        return 0;
    }

    # Validate this AA belongs to this trainer's class
    unless (($aa->{original_classes} & $class_bitmask) > 0) {
        $client->Message($COLOR_RED, "That ability is not part of the $class_name discipline.");
        return 0;
    }

    my $player_class = $client->GetClass();
    my $player_bitmask = 1 << ($player_class - 1);
    my $has_native = ($aa->{original_classes} & $player_bitmask) ? 1 : 0;

    my $tier = $aa->{tier};
    my $tier_name = $TIER_NAMES{$tier};
    my $tier_balance = GetCreditBalance($client, $tier, $trainer_class);
    my $aa_name = $aa->{aa_name};

    # Native class players get their original AA; cross-class players get universal
    my $aa_id_to_grant = $has_native ? $aa->{original_aa_id}    : $aa->{universal_aa_id};
    my $first_rank_id  = $has_native ? $aa->{original_first_rank_id} : $aa->{universal_first_rank_id};

    quest::debug("InsightTrainer: Buying $aa_name ($class_name) - " . ($has_native ? "native" : "cross-class") . ", grant_aa=$aa_id_to_grant, first_rank=$first_rank_id");

    # Check current rank
    my $current_rank = $client->GetAALevel($first_rank_id);
    my $max_rank = _count_ranks($dbh, $first_rank_id);

    if ($current_rank >= $max_rank) {
        $client->Message($COLOR_GRAY, "You have already mastered $aa_name.");
        return 0;
    }

    # Check credit balance
    if ($tier_balance < 1) {
        $client->Message($COLOR_RED, "You need 1 $tier_name Credit but have $tier_balance.");
        return 0;
    }

    # Get the next rank ID
    my $target_rank_number = $current_rank + 1;
    my $target_rank_id = _get_nth_rank_id($dbh, $first_rank_id, $current_rank);

    unless ($target_rank_id) {
        $client->Message($COLOR_RED, "An error occurred finding the next rank.");
        return 0;
    }

    # Check level requirement
    my $level_req = $dbh->selectrow_array(
        "SELECT level_req FROM aa_ranks WHERE id = ?", undef, $target_rank_id
    );
    $level_req = 0 unless defined $level_req;
    my $player_level = $client->GetLevel();
    quest::debug("InsightTrainer: Level check - player=$player_level, required=" . (defined $level_req ? $level_req : "NULL") . ", rank_id=$target_rank_id");
    if ($level_req > 0 && $player_level < $level_req) {
        $client->Message($COLOR_RED, "This rank requires level $level_req. You are level $player_level.");
        return 0;
    }

    # Check prerequisites (including AAs outside custom mapping)
    # rp.aa_id is always an ORIGINAL aa_ability id.
    # Cross-class players may satisfy the prereq via the universal AA, so check both.
    my $pre_sth = $dbh->prepare(
        "SELECT rp.aa_id, rp.points, aa.name as aa_name, aa.first_rank_id " .
        "FROM aa_rank_prereqs rp " .
        "LEFT JOIN aa_ability aa ON aa.id = rp.aa_id " .
        "WHERE rp.rank_id = ?"
    );
    $pre_sth->execute($target_rank_id);
    while (my $p = $pre_sth->fetchrow_hashref()) {
        my $prereq_first_rank_orig = $p->{first_rank_id};
        my $prereq_name = $p->{aa_name} || "AA $p->{aa_id}";

        unless ($prereq_first_rank_orig) {
            quest::debug("InsightTrainer: WARNING - Prerequisite AA $p->{aa_id} not found in aa_ability table");
            next;
        }

        # Also look up universal first_rank_id in case player has the cross-class version
        my ($prereq_first_rank_univ) = $dbh->selectrow_array(
            "SELECT ua.first_rank_id FROM aa_custom_mapping acm " .
            "JOIN aa_ability ua ON ua.id = acm.universal_aa_id " .
            "WHERE acm.original_aa_id = ?", undef, $p->{aa_id}
        );

        my $rank_orig = $client->GetAALevel($prereq_first_rank_orig);
        my $rank_univ = $prereq_first_rank_univ ? $client->GetAALevel($prereq_first_rank_univ) : 0;
        my $player_prereq_rank = ($rank_orig > $rank_univ) ? $rank_orig : $rank_univ;

        quest::debug("InsightTrainer: Prereq check - $prereq_name (aa_id=$p->{aa_id}): need $p->{points}, have orig=$rank_orig univ=$rank_univ");

        if ($player_prereq_rank < $p->{points}) {
            $client->Message($COLOR_RED, "You need $p->{points} rank" . ($p->{points} > 1 ? "s" : "") . " of $prereq_name first (you have $player_prereq_rank).");
            $pre_sth->finish();
            return 0;
        }
    }
    $pre_sth->finish();

    # All checks passed — grant the rank
    # API: GrantAlternateAdvancementAbility(aa_id, total_points, ignore_cost)
    # Second parameter is TOTAL points, not increment
    my $new_total_points = $current_rank + 1;
    quest::debug("InsightTrainer: About to grant - aa_id=$aa_id_to_grant, total_points=$new_total_points (was $current_rank), first_rank_id=$first_rank_id");
    my $result = $client->GrantAlternateAdvancementAbility($aa_id_to_grant, $new_total_points, 1);
    quest::debug("InsightTrainer: GrantAA result=$result");

    if ($result) {
        # Deduct 1 credit of this tier
        my $new_balance = $tier_balance - 1;
        _set_credit_balance($client, $tier, $trainer_class, $new_balance);

        quest::ding();
        my $rank_msg = $max_rank > 1 ? " (Rank $target_rank_number/$max_rank)" : "";
        $client->Message($COLOR_GREEN, "You have learned $aa_name$rank_msg! [Cross-Class]");
        $client->Message($COLOR_HEADING, "1 $tier_name Credit spent. $tier_name Credits remaining: $new_balance  " . quest::saylink("train", 1, "[Continue Training]"));
        quest::debug("InsightTrainer: Granted $aa_name rank $target_rank_number ($class_name), -1 $tier_name credit, balance=$new_balance");
        return 1;
    } else {
        $client->Message($COLOR_RED, "Failed to grant this ability. You may not meet a hidden requirement.");
        quest::debug("InsightTrainer: GrantAA FAILED for $aa_name ($class_name)");
        return 0;
    }
}

# ============================================================
# HandleSay - Process all say commands from the NPC script
# $trainer_class: 1-16, determines which class this trainer teaches
# Returns 1 if handled, 0 if not
# ============================================================
sub HandleSay {
    my ($client, $text, $trainer_class) = @_;
    my $class_name = $CLASS_NAMES{$trainer_class} || "Unknown";

    if ($text =~ /hail/i) {
        my %bal = GetAllBalances($client, $trainer_class);
        
        my $popup = "<c \"#00FFFF\">$class_name AA Training</c><br><br>";
        $popup .= "<c \"#FFFF00\">How It Works:</c><br>";
        $popup .= "1. Bring me <c \"#FFD700\">illegible $class_name tomes</c> + platinum<br>";
        $popup .= "2. I will decipher them and grant you <c \"#00FF00\">training credits</c><br>";
        $popup .= "3. Use credits to purchase cross-class abilities<br><br>";
        $popup .= "<c \"#FFFF00\">Credit Costs:</c><br>";
        $popup .= "- <c \"#00FF00\">Greater Tome</c> + 100pp = 1 Greater Credit<br>";
        $popup .= "- <c \"#00CCFF\">Exalted Tome</c> + 300pp = 1 Exalted Credit<br>";
        $popup .= "- <c \"#CC66FF\">Ascendant Tome</c> + 500pp = 1 Ascendant Credit<br><br>";
        $popup .= "<c \"#FFFF00\">Your Credits:</c><br>";
        $popup .= "- <c \"#00FF00\">Greater:</c> <c \"#FFFFFF\">$bal{1}</c><br>";
        $popup .= "- <c \"#00CCFF\">Exalted:</c> <c \"#FFFFFF\">$bal{2}</c><br>";
        $popup .= "- <c \"#CC66FF\">Ascendant:</c> <c \"#FFFFFF\">$bal{3}</c><br><br>";
        $popup .= "<c \"#AAAAAA\">Each credit buys one rank of its tier. Native class abilities use your original AA — cross-class abilities use the universal version.</c>";
        
        quest::popup("$class_name Training", $popup, 0, 0, 0);
        $client->Message($COLOR_HEADING, "Browse: " . quest::saylink("train t1 0", 1, "[Greater]") . "   " . quest::saylink("train t2 0", 1, "[Exalted]") . "   " . quest::saylink("train t3 0", 1, "[Ascendant]"));
        return 1;
    }

    if ($text =~ /^balance$/i) {
        ShowBalance($client, $trainer_class);
        return 1;
    }

    # train [filter] [page]
    if ($text =~ /^train(?:\s+(all|t1|t2|t3))?(?:\s+(\d+))?$/i) {
        my $filter_key = lc($1 || 'all');
        my $page = int($2 || 0);
        my $filter = '';
        $filter = '1' if $filter_key eq 't1';
        $filter = '2' if $filter_key eq 't2';
        $filter = '3' if $filter_key eq 't3';
        ShowTrainingMenu($client, $page, $filter, $trainer_class);
        return 1;
    }

    # aainfo <uid>
    if ($text =~ /^aainfo\s+(\d+)$/i) {
        ShowAADetail($client, int($1), $trainer_class);
        return 1;
    }

    # buyaa <uid> — show confirmation popup
    if ($text =~ /^buyaa\s+(\d+)$/i) {
        ShowBuyConfirmation($client, int($1), $trainer_class);
        return 1;
    }

    return 0;
}

# ============================================================
# Helper: Check if player can buy next rank (balance + level + prereqs)
# Returns 1 if all conditions met, 0 otherwise
# ============================================================
sub _check_can_buy {
    my ($dbh, $client, $first_rank_id, $current_rank, $balance, $insight_cost) = @_;

    # Check balance
    if ($balance < $insight_cost) {
        quest::debug("_check_can_buy: FAIL - insufficient balance ($balance < $insight_cost)");
        return 0;
    }

    # Get next rank ID
    my $next_rank_id = _get_nth_rank_id($dbh, $first_rank_id, $current_rank);
    unless ($next_rank_id) {
        quest::debug("_check_can_buy: FAIL - cannot find next rank (first_rank=$first_rank_id, current=$current_rank)");
        return 0;
    }
    quest::debug("_check_can_buy: next_rank_id=$next_rank_id");

    # Check level requirement
    my ($level_req) = $dbh->selectrow_array(
        "SELECT level_req FROM aa_ranks WHERE id = ?", undef, $next_rank_id
    );
    if ($level_req && $level_req > 0 && $client->GetLevel() < $level_req) {
        quest::debug("_check_can_buy: FAIL - level too low (need $level_req, have " . $client->GetLevel() . ")");
        return 0;
    }

    # Check prerequisites
    # rp.aa_id is always an ORIGINAL aa_ability id.
    # Cross-class players may hold the prerequisite via the universal AA instead,
    # so check both the original first_rank_id AND the universal first_rank_id.
    my $pre_sth = $dbh->prepare(
        "SELECT rp.aa_id, rp.points FROM aa_rank_prereqs rp WHERE rp.rank_id = ?"
    );
    $pre_sth->execute($next_rank_id);
    while (my ($prereq_aa, $prereq_points) = $pre_sth->fetchrow_array()) {
        # Original ability first_rank_id
        my ($prereq_first_rank_orig) = $dbh->selectrow_array(
            "SELECT first_rank_id FROM aa_ability WHERE id = ?", undef, $prereq_aa
        );
        # Universal ability first_rank_id (if mapped)
        my ($prereq_first_rank_univ) = $dbh->selectrow_array(
            "SELECT ua.first_rank_id FROM aa_custom_mapping acm " .
            "JOIN aa_ability ua ON ua.id = acm.universal_aa_id " .
            "WHERE acm.original_aa_id = ?", undef, $prereq_aa
        );
        my $rank_orig = $prereq_first_rank_orig ? $client->GetAALevel($prereq_first_rank_orig) : 0;
        my $rank_univ = $prereq_first_rank_univ ? $client->GetAALevel($prereq_first_rank_univ) : 0;
        my $player_prereq_rank = ($rank_orig > $rank_univ) ? $rank_orig : $rank_univ;
        if ($player_prereq_rank < $prereq_points) {
            quest::debug("_check_can_buy: FAIL - missing prereq AA $prereq_aa (need $prereq_points, have orig=$rank_orig univ=$rank_univ)");
            $pre_sth->finish();
            return 0;
        }
    }
    $pre_sth->finish();

    quest::debug("_check_can_buy: PASS - all checks passed");
    return 1;
}

# ============================================================
# Helper: Count total ranks by walking chain
# ============================================================
sub _count_ranks {
    my ($dbh, $first_rank_id) = @_;
    return 0 unless $first_rank_id && $first_rank_id > 0;

    my $count = 0;
    my $current = $first_rank_id;
    my $safety = 0;

    while ($current && $current > 0 && $safety < 100) {
        $count++;
        my ($next) = $dbh->selectrow_array(
            "SELECT next_id FROM aa_ranks WHERE id = ?", undef, $current
        );
        last unless $next && $next > 0;
        $current = $next;
        $safety++;
    }
    return $count;
}

# ============================================================
# Helper: Get the rank_id for rank N (0-indexed from first_rank)
# ============================================================
sub _get_nth_rank_id {
    my ($dbh, $first_rank_id, $n) = @_;
    return undef unless $first_rank_id && $first_rank_id > 0;

    my $current = $first_rank_id;
    for (my $i = 0; $i < $n; $i++) {
        my ($next) = $dbh->selectrow_array(
            "SELECT next_id FROM aa_ranks WHERE id = ?", undef, $current
        );
        return undef unless $next && $next > 0;
        $current = $next;
    }
    return $current;
}

return 1;
