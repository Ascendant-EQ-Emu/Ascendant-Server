# ============================================================
# Gold Token Refund Vendor
# Hail to claim tome_refund bucket as Gold Tokens (alt currency 17).
# Right-click NPC to browse the tome vendor inventory.
#
# Bucket key: {charname_lc}-tome_refund
# Alt currency: ID 17 (Gold Token, item 43943)
# ============================================================

my $ALT_CURRENCY_ID   = 17;
my $TOME_BUCKET       = "tome_refund";
my $AA_BUCKET         = "aa_refund";
my $PLAT_BUCKET       = "plat_refund";
my %pending_tokens;   # char_id => amount
my %pending_aa;       # char_id => amount
my %pending_plat;     # char_id => amount (platinum)

sub EVENT_SAY {
    if ($text =~ /hail/i || $text =~ /hello/i || $text =~ /hi/i) {
        my $char_name    = $client->GetName();
        my $name_lc      = lc($char_name);
        my $tome_pending = int(quest::get_data("${name_lc}-${TOME_BUCKET}") || 0);
        my $aa_pending   = int(quest::get_data("${name_lc}-${AA_BUCKET}")   || 0);

        $client->Message(15, "Greetings, $char_name. I hold compensation for those whose Ascendant tomes were recalled during the expansion rebalance.");

        my $plat_pending  = int(quest::get_data("${name_lc}-${PLAT_BUCKET}") || 0);

        if ($tome_pending > 0) {
            $client->Message(14, "You have $tome_pending Gold Token(s) waiting to be claimed.");
            $client->Message(18, ">> " . quest::saylink("claim tokens", 1, "Claim $tome_pending Gold Token(s)"));
        }
        if ($aa_pending > 0) {
            $client->Message(14, "You have $aa_pending unspent AA point(s) to be refunded.");
            $client->Message(18, ">> " . quest::saylink("claim aa", 1, "Claim $aa_pending AA Point(s)"));
        }
        if ($plat_pending > 0) {
            $client->Message(14, "You have ${plat_pending}pp platinum compensation waiting.");
            $client->Message(18, ">> " . quest::saylink("claim plat", 1, "Claim ${plat_pending}pp"));
        }
        if ($tome_pending <= 0 && $aa_pending <= 0 && $plat_pending <= 0) {
            $client->Message(12, "You have no pending refund.");
        }

        $client->Message(0, "Right-click me to browse available tomes you may purchase with Gold Tokens.");
    }
    elsif ($text =~ /claim tokens/i) {
        my $char_id  = $client->CharacterID();
        my $name_lc  = lc($client->GetName());
        my $pending  = int(quest::get_data("${name_lc}-${TOME_BUCKET}") || 0);

        if ($pending <= 0) {
            $client->Message(13, "You have no Gold Tokens to claim.");
            return;
        }

        quest::delete_data("${name_lc}-${TOME_BUCKET}");
        $pending_tokens{$char_id} = $pending;
        $client->Message(14, "Processing your claim for $pending Gold Token(s)...");
        quest::settimer("grant_tokens", 1);
    }
    elsif ($text =~ /claim aa/i) {
        my $char_id  = $client->CharacterID();
        my $name_lc  = lc($client->GetName());
        my $pending  = int(quest::get_data("${name_lc}-${AA_BUCKET}") || 0);

        if ($pending <= 0) {
            $client->Message(13, "You have no AA points to claim.");
            return;
        }

        quest::delete_data("${name_lc}-${AA_BUCKET}");
        $pending_aa{$char_id} = $pending;
        $client->Message(14, "Processing your claim for $pending AA point(s)...");
        quest::settimer("grant_aa", 1);
    }
    elsif ($text =~ /claim plat/i) {
        my $char_id  = $client->CharacterID();
        my $name_lc  = lc($client->GetName());
        my $pending  = int(quest::get_data("${name_lc}-${PLAT_BUCKET}") || 0);

        if ($pending <= 0) {
            $client->Message(13, "You have no platinum compensation to claim.");
            return;
        }

        quest::delete_data("${name_lc}-${PLAT_BUCKET}");
        $pending_plat{$char_id} = $pending;
        $client->Message(14, "Processing your platinum claim for ${pending}pp...");
        quest::settimer("grant_plat", 1);
    }
}

sub EVENT_TIMER {
    if ($timer eq "grant_tokens") {
        quest::stoptimer("grant_tokens");

        foreach my $cid (keys %pending_tokens) {
            my $amount = delete $pending_tokens{$cid};
            next unless $amount > 0;
            my $ent = $entity_list->GetClientByCharID($cid);
            next unless $ent;
            $ent->AddAlternateCurrencyValue($ALT_CURRENCY_ID, $amount);
            $ent->Message(14, "You have received $amount Gold Token(s).");
        }
    }
    elsif ($timer eq "grant_aa") {
        quest::stoptimer("grant_aa");

        foreach my $cid (keys %pending_aa) {
            my $amount = delete $pending_aa{$cid};
            next unless $amount > 0;
            my $ent = $entity_list->GetClientByCharID($cid);
            next unless $ent;
            $ent->AddAAPoints($amount);
            $ent->Message(14, "You have received $amount unspent AA point(s).");
        }
    }
    elsif ($timer eq "grant_plat") {
        quest::stoptimer("grant_plat");

        foreach my $cid (keys %pending_plat) {
            my $amount = delete $pending_plat{$cid};
            next unless $amount > 0;
            my $ent = $entity_list->GetClientByCharID($cid);
            next unless $ent;
            $ent->AddPlatinum($amount, 1);
            $ent->Message(14, "You have received ${amount}pp platinum compensation.");
        }
    }
}
