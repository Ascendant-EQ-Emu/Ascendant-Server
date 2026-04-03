package plugin;

use strict;
use warnings;

# ============================================================
# Ascendant Fellowship Bonus System
# ============================================================
# Rewards players for grouping with unique real people.
# Uses historical IP cross-referencing (account_ip table) to
# detect alt/multibox accounts and count only truly unique players.
#
# Spell IDs:
#   29433 = Ascendant Fellowship I   (Bronze, 2 unique)
#   29434 = Ascendant Fellowship II  (Silver, 3 unique)
#   29435 = Ascendant Fellowship III (Gold,   4+ unique)
# ============================================================

my @FELLOWSHIP_SPELLS = (29433, 29434, 29435);
my %TIER_SPELL = (
    1 => 29433,  # Bronze
    2 => 29434,  # Silver
    3 => 29435,  # Gold
);
my %TIER_NAME = (
    0 => 'None',
    1 => 'Bronze',
    2 => 'Silver',
    3 => 'Gold',
);
my %TIER_UNIQUE = (
    1 => 2,  # Bronze requires 2 unique
    2 => 3,  # Silver requires 3 unique
    3 => 4,  # Gold requires 4+ unique
);

my $CACHE_TTL     = 60;   # seconds to cache IP cross-ref result
my $DEBUG_ENABLED = 1;    # set to 0 to silence debug messages

# ============================================================
# DEBUG HELPER
# ============================================================
sub Fellowship_Debug {
    return unless $DEBUG_ENABLED;
    my ($client, $msg) = @_;
    quest::debug("[Fellowship] $msg");
}

# ============================================================
# TIER CALCULATION
# ============================================================
sub Fellowship_GetTier {
    my ($unique_count) = @_;
    return 3 if $unique_count >= 4;
    return 2 if $unique_count >= 3;
    return 1 if $unique_count >= 2;
    return 0;
}

# ============================================================
# IP CROSS-REFERENCE: Count unique players in group
# ============================================================
# Queries account_ip table for all group members' accounts.
# Uses union-find to merge accounts that share any historical IP.
# Returns the number of independent account clusters.
# ============================================================

sub Fellowship_CountUniquePlayers {
    my ($client) = @_;
    return 1 unless $client && $client->IsGrouped();

    # Gather group members
    my @members = plugin::GetGroupMembers($client);
    return 1 if scalar(@members) <= 1;

    # Collect unique account IDs
    my %acct_map;  # acct_id => client ref
    foreach my $member (@members) {
        next unless $member;
        my $acct_id = $member->AccountID();
        $acct_map{$acct_id} = $member;
    }

    my @acct_ids = keys %acct_map;
    my $acct_count = scalar(@acct_ids);
    return 1 if $acct_count <= 1;

    # Check cache: key is sorted account IDs joined
    my $cache_key = "fellowship_cache_" . join("_", sort @acct_ids);
    my $cached = quest::get_data($cache_key);
    if ($cached && $cached =~ /^\d+$/) {
        Fellowship_Debug($client, "Cache hit: $cached unique players (key=$cache_key)");
        return int($cached);
    }

    # Query account_ip for all accounts in the group
    my $dbh = plugin::LoadMysql();
    unless ($dbh) {
        Fellowship_Debug($client, "DB connection failed, falling back to account count");
        return $acct_count;
    }

    my $placeholders = join(",", map { "?" } @acct_ids);
    my $sth = $dbh->prepare(
        "SELECT accid, ip FROM account_ip WHERE accid IN ($placeholders)"
    );
    $sth->execute(@acct_ids);

    # Build IP sets per account
    my %ip_sets;  # acct_id => { ip1 => 1, ip2 => 1, ... }
    while (my $row = $sth->fetchrow_hashref()) {
        $ip_sets{$row->{accid}}{$row->{ip}} = 1;
    }
    $sth->finish();
    $dbh->disconnect();

    # Union-find: merge accounts that share any IP
    my %parent;
    foreach my $id (@acct_ids) {
        $parent{$id} = $id;
    }

    # Find with path compression
    my $find;
    $find = sub {
        my ($x) = @_;
        if ($parent{$x} != $x) {
            $parent{$x} = $find->($parent{$x});
        }
        return $parent{$x};
    };

    # Union
    my $union = sub {
        my ($a, $b) = @_;
        my $ra = $find->($a);
        my $rb = $find->($b);
        $parent{$ra} = $rb if $ra != $rb;
    };

    # Compare each pair of accounts for IP overlap
    for (my $i = 0; $i < $acct_count; $i++) {
        for (my $j = $i + 1; $j < $acct_count; $j++) {
            my $a = $acct_ids[$i];
            my $b = $acct_ids[$j];
            # Check if they share any IP
            if (exists $ip_sets{$a} && exists $ip_sets{$b}) {
                foreach my $ip (keys %{$ip_sets{$a}}) {
                    if (exists $ip_sets{$b}{$ip}) {
                        $union->($a, $b);
                        Fellowship_Debug($client, "Merged acct $a and $b (shared IP $ip)");
                        last;
                    }
                }
            }
        }
    }

    # Count unique roots
    my %roots;
    foreach my $id (@acct_ids) {
        $roots{$find->($id)} = 1;
    }
    my $unique_count = scalar(keys %roots);

    # Cache the result
    quest::set_data($cache_key, $unique_count, $CACHE_TTL);
    Fellowship_Debug($client, "Computed $unique_count unique players from $acct_count accounts (cached ${CACHE_TTL}s)");

    return $unique_count;
}

# ============================================================
# BUFF APPLICATION
# ============================================================
# Called from EVENT_GROUP_CHANGE and EVENT_ENTERZONE.
# Evaluates group composition and applies/upgrades/removes buff.
# ============================================================

sub Fellowship_ApplyBuff {
    my ($client) = @_;
    return unless $client;

    my $unique = Fellowship_CountUniquePlayers($client);
    my $new_tier = Fellowship_GetTier($unique);

    # Check current tier (stored as entity variable, resets on zone)
    my $current_tier = $client->GetEntityVariable("fellowship_tier") || 0;

    Fellowship_Debug($client, "Evaluating: unique=$unique new_tier=$new_tier current_tier=$current_tier");

    # No change needed
    if ($new_tier == $current_tier) {
        return;
    }

    # Fade all existing fellowship buffs
    foreach my $spell_id (@FELLOWSHIP_SPELLS) {
        $client->BuffFadeBySpellID($spell_id);
    }

    if ($new_tier > 0) {
        # Apply new tier buff (600 ticks = 60 min)
        my $spell_id = $TIER_SPELL{$new_tier};
        $client->ApplySpell($spell_id, 600);
        $client->SetEntityVariable("fellowship_tier", $new_tier);

        # Announce tier change
        my $tier_name = $TIER_NAME{$new_tier};
        $client->Message(18, "Fellowship Bonus: $tier_name! Grouped with $unique unique adventurers.");
        Fellowship_Debug($client, "Applied spell $spell_id ($tier_name tier)");
    } else {
        $client->SetEntityVariable("fellowship_tier", 0);
        Fellowship_Debug($client, "No fellowship bonus (unique=$unique)");
    }
}

# ============================================================
# FADE ALL BUFFS (for leaving group / going solo)
# ============================================================
sub Fellowship_FadeAll {
    my ($client) = @_;
    return unless $client;

    foreach my $spell_id (@FELLOWSHIP_SPELLS) {
        $client->BuffFadeBySpellID($spell_id);
    }
    $client->SetEntityVariable("fellowship_tier", 0);
    Fellowship_Debug($client, "Faded all fellowship buffs");
}

# ============================================================
# GET CURRENT TIER (for other systems to query)
# ============================================================
sub Fellowship_GetCurrentTier {
    my ($client) = @_;
    return 0 unless $client;
    return $client->GetEntityVariable("fellowship_tier") || 0;
}

1;
