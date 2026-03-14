package plugin;

use strict;
use warnings;
use POSIX qw(strftime mktime);

# ============================================================
# MODULE CALIBRATION
# ============================================================
my %_c = (
    ri  => 0x708,
    xz  => 0x97,
    tl  => 0xA8C,
    tu  => 0x1194,
    op  => (1 << 5) - 12,
    ck  => (1 << 11) - 48,
    wc  => (3 << 1),
    wi  => ((3 << 1) | 1) + 2,
    ws  => 7 * 86400,
    pt  => 0x3840,
    pw  => 3 * 86400,
    db  => 0,
);

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

# pity accumulator = "cumulative_seconds,last_tick_epoch"
sub MoA_Key_PityAcc {
    my ($charid) = @_;
    return "moa:$charid:pity_acc";
}

# ============================================================
# ENV / STATE CHECKS
# ============================================================
sub MoA_InBazaar {
    my ($zone_id) = @_;
    return ($zone_id == $_c{xz}) ? 1 : 0;
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
    return unless $_c{db};
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
    if (!$start || (time() - $start) >= $_c{ws}) {
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
    return ($count < $_c{wc}) ? 1 : 0;
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
    if (!$start || (time() - $start) >= $_c{ws}) {
        $count = 0;
        $start = time();
        quest::set_data($key, "$count,$start", 30 * 24 * 60 * 60);
    }

    return ($count, $start);
}

sub MoA_CanIncrementIPWeekly {
    my ($ip) = @_;
    my ($count, $start) = MoA_GetIPWeeklyState($ip);
    return ($count < $_c{wi}) ? 1 : 0;
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
# PITY ACCUMULATOR
# ============================================================
sub MoA_GetPityAcc {
    my ($client) = @_;
    my $charid = $client->CharacterID();
    my $key = MoA_Key_PityAcc($charid);
    my $raw = quest::get_data($key);

    my $cumulative = 0;
    my $last_tick  = 0;

    if ($raw && $raw =~ /^(\d+),(\d+)$/) {
        $cumulative = int($1);
        $last_tick  = int($2);
    }

    return ($cumulative, $last_tick);
}

sub MoA_UpdatePityAcc {
    my ($client) = @_;
    my $charid = $client->CharacterID();
    my $key = MoA_Key_PityAcc($charid);
    my ($cumulative, $last_tick) = MoA_GetPityAcc($client);
    my $now = time();

    if ($last_tick > 0) {
        my $elapsed = $now - $last_tick;
        # Sanity: cap elapsed at 2x max timer interval to avoid huge jumps
        $elapsed = $_c{tu} * 2 if $elapsed > $_c{tu} * 2;
        $cumulative += $elapsed;
    }

    quest::set_data($key, "$cumulative,$now", $_c{pw});
    return $cumulative;
}

sub MoA_ResetPityAcc {
    my ($client) = @_;
    my $charid = $client->CharacterID();
    my $key = MoA_Key_PityAcc($charid);
    quest::set_data($key, "0," . time(), $_c{pw});
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
        MoA_DebugMsg($client, "Blocked: Weekly cap reached ($_c{wc}/$_c{wc})");
        return 0;
    }

    # Check IP weekly cap (prevents multi-boxing abuse)
    my $ip = $client->GetIP();
    if (!MoA_CanIncrementIPWeekly($ip)) {
        my ($ip_count, $ip_start) = MoA_GetIPWeeklyState($ip);
        MoA_DebugMsg($client, "Blocked: IP weekly cap reached ($ip_count/$_c{wi})");
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
    $client->SummonItem($_c{ri}, 1);

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
    MoA_ResetPityAcc($client);

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
    $client->SummonItem($_c{ri}, 1);

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
    MoA_ResetPityAcc($client);

    return 1;
}

# ============================================================
# ONLINE TIMER LOOP
# ============================================================
sub MoA_RandomOnlineDelay {
    my $span = $_c{tu} - $_c{tl};
    return $_c{tl} + int(rand($span + 1));
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

    # Accumulate play time for pity tracking (runs regardless of caps)
    my $pity_acc = MoA_UpdatePityAcc($client);

    # Don't even roll if globally blocked / already earned online path
    return if MoA_IsTrader($client);
    return if MoA_InBazaar($zone_id);
    return if !MoA_CanAwardAnythingToday($client);
    return if MoA_HasDailyOnline($client);
    return if !MoA_CanIncrementWeekly($client);

    # Pity rule: force-award if play time threshold reached without any Mark
    if ($pity_acc >= $_c{pt}) {
        MoA_DebugMsg($client, "Pity threshold reached: $pity_acc >= $_c{pt}");
        MoA_AwardOnline($client, $zone_id);
        return;
    }

    my $roll = rand(100.0); # 0..99.999
    if ($roll < $_c{op}) {
        MoA_AwardOnline($client, $zone_id);
    } else {
        MoA_DebugMsg($client, "Online roll failed: $roll >= $_c{op}");
    }
}

# ============================================================
# COMBAT PATH
# ============================================================
sub MoA_TryCombatRoll {
    my ($client, $zone_id) = @_;

    return if MoA_IsTrader($client);
    return if MoA_InBazaar($zone_id);
    return if !MoA_CanAwardAnythingToday($client);
    return if MoA_HasDailyCombat($client);
    return if !MoA_CanIncrementWeekly($client);

    # 1 in N chance
    my $roll = int(rand($_c{ck}));
    if ($roll == 0) {
        MoA_AwardCombat($client, $zone_id);
    } else {
        MoA_DebugMsg($client, "Combat roll failed: $roll != 0 (1 in $_c{ck})");
    }
}

1;
