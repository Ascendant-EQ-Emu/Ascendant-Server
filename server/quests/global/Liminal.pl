# ==========================================================
# Liminal.pl
#
# Silent gateway NPC ("Liminal")
#
# Behavior:
# - Proximity-based discovery in all zones except Guild Lobby
# - Guild Lobby (zoneid 344) acts as hub
# - Permanent, character-scoped data buckets
# - Uses index bucket for iteration (EQEmu-safe)
#
# Data Model:
#   liminal-<charid>-<zone_short_name> = zoneid,x,y,z,h
#   liminal-index-<charid>             = zone1,zone2,zone3
# ==========================================================

use strict;
use warnings;

# -----------------------------
# EQEmu injected globals
# -----------------------------
our (
    $client,
    $text,
    $zoneid,
    $x, $y, $z, $h
);

# -----------------------------
# CONFIG
# -----------------------------
my $PROX_RADIUS        = 60;
my $GUILD_LOBBY_ZONEID = 344;

# -----------------------------
# EVENT_SPAWN
# -----------------------------
sub EVENT_SPAWN {

    # Never auto-discover in Guild Lobby
    return if $zoneid == $GUILD_LOBBY_ZONEID;

    quest::set_proximity(
        $x - $PROX_RADIUS, $x + $PROX_RADIUS,
        $y - $PROX_RADIUS, $y + $PROX_RADIUS,
        $z - 20,           $z + 20
    );
}

# -----------------------------
# EVENT_ENTER (Discovery)
# -----------------------------
sub EVENT_ENTER {
    return unless $client;
    return if $zoneid == $GUILD_LOBBY_ZONEID;

    my $charid = $client->CharacterID();
    return unless $charid;

    my $zonesn = quest::GetZoneShortName($zoneid);
    return unless $zonesn;

    my $zone_key  = "liminal-$charid-$zonesn";
    my $index_key = "liminal-index-$charid";

    # Already discovered
    return if quest::get_data($zone_key);

    # Store zoneid + XYZH (permanent)
    my $value = join(',', $zoneid, int($x), int($y), int($z), int($h));
    quest::set_data($zone_key, $value);

    # Update index (additive, no duplicates)
    my $index = quest::get_data($index_key);
    my %zones = ();

    if ($index && length $index) {
        %zones = map { $_ => 1 } split(',', $index);
    }

    $zones{$zonesn} = 1;

    quest::set_data(
        $index_key,
        join(',', sort keys %zones)
    );

    $client->Message(
        21,
        "A whisper stirs in your mind. You feel connected to Liminal."
    );
}

# -----------------------------
# EVENT_SAY (Guild Lobby Hub)
# -----------------------------
sub EVENT_SAY {
    return unless $client;
    return unless $zoneid == $GUILD_LOBBY_ZONEID;

    my $charid = $client->CharacterID();
    return unless $charid;

    my $index_key = "liminal-index-$charid";
    my $index = quest::get_data($index_key);

    # Silent unless you know the way
    return unless $index && length $index;

    my @zones = split(',', $index);

    if ($text =~ /hail/i) {

    my @links = map {
        quest::silent_saylink("travel $_", $_)
    } @zones;

    $client->Message(
        21,
        "A whisper brushes your thoughts, would you like to pass through to:\n" .
        join(", ", @links)
    );
}

if ($text =~ /^travel\s+(\w+)/i) {
    my $zonesn = lc $1;

    my $zone_key = "liminal-$charid-$zonesn";
    my $data = quest::get_data($zone_key);
    return unless $data;

    my ($zid, $tx, $ty, $tz, $th) = split(',', $data);

    quest::movepc($zid, $tx, $ty, $tz, $th);
}

}
