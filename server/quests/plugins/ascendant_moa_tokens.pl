package plugin;

use strict;
use warnings;
use POSIX qw(strftime mktime);

# ============================================================
# CONFIG
# ============================================================
my $MOA_ITEM_ID        = 1800;     # Mark of Ascendance item id
my $BAZAAR_ZONE_ID     = 151;      # No awards in Bazaar

# Online award behavior
my $ONLINE_TIMER_MIN   = 45 * 60;  # 45 minutes
my $ONLINE_TIMER_MAX   = 75 * 60;  # 75 minutes
my $ONLINE_CHANCE_PCT  = 20.0;     # % chance per timer fire (tune)

# Combat award behavior
my $COMBAT_ONE_IN      = 2000;     # 1 in N chance on kill credit (tune)

# Caps
my $WEEKLY_CAP         = 6;
my $IP_WEEKLY_CAP      = 9;        # 1.5x character cap (allows 3-boxing without 3x rewards)
my $WEEK_SECONDS       = 7 * 24 * 60 * 60;

# Debug mode (set to 1 to see award blocks and reasons)
my $DEBUG_MODE         = 0;

# ============================================================
# TIME HELPERS
# ============================================================
sub MoA_DayKey {
    return strftime("%Y%m%d", localtime(time()));
}

sub MoA_SecondsToMidnight {
    my @lt  = localtime(time());
    my $now = time();

    # midnight today
    $lt[0] = 0; $lt[1] = 0; $lt[2] = 0;
    my $today_midnight = mktime(@lt);
    my $next_midnight  = $today_midnight + 24 * 60 * 60;

    my $ttl = $next_midnight - $now;
    $ttl = 60 if ($ttl < 60); # safety
    return $ttl;
}

# ============================================================
# KEY HELPERS (per-character)
# ============================================================
sub MoA_Key_DailyOnline {
    my ($charid, $day) = @_;
    return "moa:$charid:$day:daily_online";
}

sub MoA_Key_DailyCombat {
    my ($charid, $day) = @_;
    return "moa:$charid:$day:daily_combat";
}

# weekly_state = "count,start_epoch"
sub MoA_Key_WeeklyState {
    my ($charid) = @_;
    return "moa:$charid:weekly_state";
}

sub MoA_Key_TimerActive {
    my ($charid) = @_;
    return "moa:$charid:timer_active";
}

# IP-based weekly state = "count,start_epoch"
sub MoA_Key_IPWeeklyState {
    my ($ip) = @_;
    return "moa:ip:$ip:weekly_state";
}

# ============================================================
# ENV / STATE CHECKS
# ============================================================
sub MoA_InBazaar {
    my ($zone_id) = @_;
    return ($zone_id == $BAZAAR_ZONE_ID) ? 1 : 0;
}

sub MoA_IsTrader {
    my ($client) = @_;
    # Some builds support IsTrader(); wrap in eval.
    my $is_trader = 0;
    eval { $is_trader = $client->IsTrader(); };
    return $is_trader ? 1 : 0;
}

sub MoA_BucketExists {
    my ($key) = @_;
    my $v = quest::get_data($key);
    return ($v) ? 1 : 0;
}

sub MoA_DebugMsg {
    my ($client, $msg) = @_;
    return unless $DEBUG_MODE;
    $client->Message(15, "[MOA DEBUG] $msg");
}

# ============================================================
# DAILY CAPS (2 total: 1 online + 1 combat)
# ============================================================
sub MoA_HasDailyOnline {
    my ($client) = @_;
    my $day    = MoA_DayKey();
    my $charid = $client->CharacterID();
    return MoA_BucketExists(MoA_Key_DailyOnline($charid, $day));
}

sub MoA_HasDailyCombat {
    my ($client) = @_;
    my $day    = MoA_DayKey();
    my $charid = $client->CharacterID();
    return MoA_BucketExists(MoA_Key_DailyCombat($charid, $day));
}

sub MoA_DailyTotal {
    my ($client) = @_;
    my $t = 0;
    $t++ if MoA_HasDailyOnline($client);
    $t++ if MoA_HasDailyCombat($client);
    return $t;
}

sub MoA_CanAwardAnythingToday {
    my ($client) = @_;
    return (MoA_DailyTotal($client) < 2) ? 1 : 0;
}

# ============================================================
# WEEKLY CAP (rolling 7 days)
# ============================================================
sub MoA_GetWeeklyState {
    my ($client) = @_;
    my $charid = $client->CharacterID();
    my $key    = MoA_Key_WeeklyState($charid);
    my $raw    = quest::get_data($key);

    my $count = 0;
    my $start = 0;

    if ($raw && $raw =~ /^(\d+),(\d+)$/) {
        $count = int($1);
        $start = int($2);
    }

    # Reset if missing or older than 7 days
    if (!$start || (time() - $start) >= $WEEK_SECONDS) {
        $count = 0;
        $start = time();
        # Use 30 day TTL to avoid race conditions
        quest::set_data($key, "$count,$start", 30 * 24 * 60 * 60);
    }

    return ($count, $start);
}

sub MoA_CanIncrementWeekly {
    my ($client) = @_;
    my ($count, $start) = MoA_GetWeeklyState($client);
    return ($count < $WEEKLY_CAP) ? 1 : 0;
}

sub MoA_IncrementWeekly {
    my ($client) = @_;
    my ($count, $start) = MoA_GetWeeklyState($client);
    $count++;

    my $charid = $client->CharacterID();
    my $key    = MoA_Key_WeeklyState($charid);

    # Keep TTL at 30 days
    quest::set_data($key, "$count,$start", 30 * 24 * 60 * 60);
    return $count;
}

# ============================================================
# IP WEEKLY CAP (rolling 7 days)
# ============================================================
sub MoA_GetIPWeeklyState {
    my ($ip) = @_;
    my $key = MoA_Key_IPWeeklyState($ip);
    my $raw = quest::get_data($key);

    my $count = 0;
    my $start = 0;

    if ($raw && $raw =~ /^(\d+),(\d+)$/) {
        $count = int($1);
        $start = int($2);
    }

    # Reset if missing or older than 7 days
    if (!$start || (time() - $start) >= $WEEK_SECONDS) {
        $count = 0;
        $start = time();
        quest::set_data($key, "$count,$start", 30 * 24 * 60 * 60);
    }

    return ($count, $start);
}

sub MoA_CanIncrementIPWeekly {
    my ($ip) = @_;
    my ($count, $start) = MoA_GetIPWeeklyState($ip);
    return ($count < $IP_WEEKLY_CAP) ? 1 : 0;
}

sub MoA_IncrementIPWeekly {
    my ($ip) = @_;
    my ($count, $start) = MoA_GetIPWeeklyState($ip);
    $count++;

    my $key = MoA_Key_IPWeeklyState($ip);
    quest::set_data($key, "$count,$start", 30 * 24 * 60 * 60);
    return $count;
}

# ============================================================
# AWARD HELPERS
# ============================================================
sub MoA_GlobalAwardAllowed {
    my ($client, $zone_id) = @_;

    if (MoA_IsTrader($client)) {
        MoA_DebugMsg($client, "Blocked: Trader mode");
        return 0;
    }

    if (MoA_InBazaar($zone_id)) {
        MoA_DebugMsg($client, "Blocked: In Bazaar");
        return 0;
    }

    if (!MoA_CanAwardAnythingToday($client)) {
        MoA_DebugMsg($client, "Blocked: Daily cap reached (2/2)");
        return 0;
    }

    if (!MoA_CanIncrementWeekly($client)) {
        MoA_DebugMsg($client, "Blocked: Weekly cap reached ($WEEKLY_CAP/$WEEKLY_CAP)");
        return 0;
    }

    # Check IP weekly cap (prevents multi-boxing abuse)
    my $ip = $client->GetIP();
    if (!MoA_CanIncrementIPWeekly($ip)) {
        my ($ip_count, $ip_start) = MoA_GetIPWeeklyState($ip);
        MoA_DebugMsg($client, "Blocked: IP weekly cap reached ($ip_count/$IP_WEEKLY_CAP)");
        return 0;
    }

    return 1;
}

sub MoA_AwardOnline {
    my ($client, $zone_id) = @_;

    return 0 if !MoA_GlobalAwardAllowed($client, $zone_id);

    if (MoA_HasDailyOnline($client)) {
        MoA_DebugMsg($client, "Blocked: Already earned online Mark today");
        return 0;
    }

    # Award
    $client->SummonItem($MOA_ITEM_ID, 1);

    # Mark daily online until midnight
    my $ttl   = MoA_SecondsToMidnight();
    my $day   = MoA_DayKey();
    my $cid   = $client->CharacterID();
    quest::set_data(MoA_Key_DailyOnline($cid, $day), 1, $ttl);

    # Increment both character and IP weekly counters
    MoA_IncrementWeekly($client);
    my $ip = $client->GetIP();
    MoA_IncrementIPWeekly($ip);
    
    $client->Message(13, "You received a Mark of Ascendance!");

    return 1;
}

sub MoA_AwardCombat {
    my ($client, $zone_id) = @_;

    return 0 if !MoA_GlobalAwardAllowed($client, $zone_id);

    if (MoA_HasDailyCombat($client)) {
        MoA_DebugMsg($client, "Blocked: Already earned combat Mark today");
        return 0;
    }

    # Award
    $client->SummonItem($MOA_ITEM_ID, 1);

    # Mark daily combat until midnight
    my $ttl   = MoA_SecondsToMidnight();
    my $day   = MoA_DayKey();
    my $cid   = $client->CharacterID();
    quest::set_data(MoA_Key_DailyCombat($cid, $day), 1, $ttl);

    # Increment both character and IP weekly counters
    MoA_IncrementWeekly($client);
    my $ip = $client->GetIP();
    MoA_IncrementIPWeekly($ip);
    
    $client->Message(13, "You received a Mark of Ascendance!");

    return 1;
}

# ============================================================
# ONLINE TIMER LOOP (45–75 minutes random)
# ============================================================
sub MoA_RandomOnlineDelay {
    my $span = $ONLINE_TIMER_MAX - $ONLINE_TIMER_MIN;
    return $ONLINE_TIMER_MIN + int(rand($span + 1));
}

# Call this from EVENT_CONNECT to start the timer
# Always starts timer since EQ timers don't persist across disconnect
sub MoA_StartOnlineTimer {
    my ($client) = @_;
    my $cid  = $client->CharacterID();
    my $flag = MoA_Key_TimerActive($cid);

    my $delay = MoA_RandomOnlineDelay();
    quest::settimer("moa_online_roll", $delay);

    # flag TTL is just a safety net; it gets refreshed every timer fire
    quest::set_data($flag, 1, 2 * 60 * 60);
}

# Call this ONLY when the timer fires to set the next random interval
sub MoA_RescheduleOnlineTimer {
    my ($client) = @_;
    my $cid  = $client->CharacterID();
    my $flag = MoA_Key_TimerActive($cid);

    my $delay = MoA_RandomOnlineDelay();
    quest::stoptimer("moa_online_roll");
    quest::settimer("moa_online_roll", $delay);

    quest::set_data($flag, 1, 2 * 60 * 60);
}

sub MoA_HandleOnlineTimerFire {
    my ($client, $zone_id) = @_;

    # Always reschedule first so the loop continues
    MoA_RescheduleOnlineTimer($client);

    # Don't even roll if globally blocked / already earned online path
    return if MoA_IsTrader($client);
    return if MoA_InBazaar($zone_id);
    return if !MoA_CanAwardAnythingToday($client);
    return if MoA_HasDailyOnline($client);
    return if !MoA_CanIncrementWeekly($client);

    my $roll = rand(100.0); # 0..99.999
    if ($roll < $ONLINE_CHANCE_PCT) {
        MoA_AwardOnline($client, $zone_id);
    } else {
        MoA_DebugMsg($client, "Online roll failed: $roll >= $ONLINE_CHANCE_PCT");
    }
}

# ============================================================
# COMBAT PATH (1 in N on kill credit)
# ============================================================
sub MoA_TryCombatRoll {
    my ($client, $zone_id) = @_;

    return if MoA_IsTrader($client);
    return if MoA_InBazaar($zone_id);
    return if !MoA_CanAwardAnythingToday($client);
    return if MoA_HasDailyCombat($client);
    return if !MoA_CanIncrementWeekly($client);

    # 1 in N chance
    my $roll = int(rand($COMBAT_ONE_IN));
    if ($roll == 0) {
        MoA_AwardCombat($client, $zone_id);
    } else {
        MoA_DebugMsg($client, "Combat roll failed: $roll != 0 (1 in $COMBAT_ONE_IN)");
    }
}

1;
