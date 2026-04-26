#!/usr/bin/env perl
# ============================================================
# generate_spell_pool.pl
# Reads spells_new (post-normalization, all classes can use any spell)
# and items (for scroll IDs) and writes
# server/quests/lua_modules/spell_pool.lua
#
# Pool entries carry:
#   level     = min level requirement (same for all classes after normalization)
#   name      = spell name
#   scroll_id = item ID of cheapest matching scroll (0 = none)
#   expac     = 0:Classic  1:Kunark  2:Velious  3:Luclin+
#   mana      = mana cost (0 = free)
#   cast_ms   = cast time in milliseconds (0 = instant)
#   icon      = spell icon index from spells_new.spell_icon
#   desc      = short auto-generated description e.g. "Group Heal", "AoE DD"
#
# Expansion unlock is checked at award time via Aurelian Stoneward flags:
#   classic_awarded_{char_id} => Kunark (expac 1) unlocked
#   kunark_awarded_{char_id}  => Velious (expac 2) unlocked
#   velious_awarded_{char_id} => Luclin+ (expac 3) unlocked
#
# Run inside the eqemu container:
#   docker exec akk-stack-eqemu-server-1 \
#     perl /home/eqemu/server/../assets/scripts/generate_spell_pool.pl
# ============================================================

use strict;
use warnings;
use DBI;
use JSON;

# ---- Config ------------------------------------------------
my $config_file = '/home/eqemu/server/eqemu_config.json';
$config_file = 'server/eqemu_config.json' unless -f $config_file;

open(my $fh, '<', $config_file) or die "Cannot read $config_file: $!";
my $raw = do { local $/; <$fh> };
close $fh;

my $cfg  = decode_json($raw);
my $db   = $cfg->{server}{database};
my $host = $db->{host};
my $port = $db->{port} || 3306;
my $name = $db->{db};
my $user = $db->{username};
my $pass = $db->{password};

# ---- Connect -----------------------------------------------
my $dbh = DBI->connect(
    "DBI:mysql:database=$name;host=$host;port=$port",
    $user, $pass,
    { RaiseError => 1, PrintError => 0 }
) or die "DB connect failed: $DBI::errstr";

# ---- Read level data from spells_us.txt -------------------------
# classesX in the DB are all set to 1 for unrestricted casting, so we
# use the unmodified spells_us.txt as the authoritative level source.
my $spells_us_path = '/home/eqemu/server/export/spells_us.txt';
$spells_us_path = 'server/export/spells_us.txt' unless -f $spells_us_path;

my %spell_level;
{
    open(my $sfh, '<', $spells_us_path) or die "Cannot read $spells_us_path: $!";
    while (my $line = <$sfh>) {
        chomp $line;
        my @f = split(/\^/, $line, -1);
        next unless @f > 119 && $f[0] =~ /^\d+$/;
        my $min = 999;
        for my $ci (104..119) {
            my $v = $f[$ci] // 255;
            if ($v =~ /^\d+$/ && $v > 0 && $v < 255) {
                $min = $v if $v < $min;
            }
        }
        $spell_level{ $f[0] } = ($min < 999) ? $min : 1;
    }
    close $sfh;
}
printf "Loaded level data for %d spells from spells_us.txt.\n", scalar keys %spell_level;

# ---- Read spell description text from dbstr_us.txt -------------
# Format: id^type^text^0   (type 6 = spell descriptions, id = spell_id)
my $dbstr_path = '/home/eqemu/server/export/dbstr_us.txt';
$dbstr_path = 'server/export/dbstr_us.txt' unless -f $dbstr_path;

my %spell_lore;
{
    open(my $dfh, '<', $dbstr_path) or die "Cannot read $dbstr_path: $!";
    while (my $line = <$dfh>) {
        chomp $line;
        my ($id, $type, $text) = split(/\^/, $line, 4);
        next unless defined $type && $type eq '6' && $id =~ /^\d+$/;
        $spell_lore{$id} = $text // "";
    }
    close $dfh;
}
printf "Loaded descriptions for %d spells from dbstr_us.txt.\n", scalar keys %spell_lore;

# ---- Generate modified spells_us.txt for client distribution ----
# Sets all non-255 class levels to 1 so players can memorize any
# awarded spell regardless of character level.  Copy this file to
# your EQ client directory as spells_us.txt.
my $client_out_path = '/home/eqemu/server/export/spells_us_norequirements.txt';
$client_out_path = 'server/export/spells_us_norequirements.txt' unless -d '/home/eqemu';
{
    open(my $in,  '<', $spells_us_path)   or die "Cannot read $spells_us_path: $!";
    open(my $out, '>', $client_out_path)  or die "Cannot write $client_out_path: $!";
    while (my $line = <$in>) {
        chomp $line;
        my @f = split(/\^/, $line, -1);
        if (@f > 119 && $f[0] =~ /^\d+$/) {
            for my $ci (104..119) {
                if (defined $f[$ci] && $f[$ci] =~ /^\d+$/ && $f[$ci] > 1 && $f[$ci] < 255) {
                    $f[$ci] = 1;
                }
            }
        }
        print $out join('^', @f) . "\n";
    }
    close $in;
    close $out;
}
printf "Written: %s\n", $client_out_path;
print "  -> Copy to your EQ client directory as spells_us.txt to allow memorizing at any level.\n";

# ---- Build scroll item lookup: spell_id -> lowest item_id --
print "Building scroll item map...\n";
my %scroll_map;
my $scroll_sth = $dbh->prepare(q{
    SELECT scrolleffect, MIN(id) AS item_id
    FROM items
    WHERE ItemType = 20
      AND scrolleffect > 0
    GROUP BY scrolleffect
});
$scroll_sth->execute();
while (my $row = $scroll_sth->fetchrow_hashref()) {
    $scroll_map{ $row->{scrolleffect} } = $row->{item_id};
}
$scroll_sth->finish();
printf "  %d spells have scroll items.\n", scalar keys %scroll_map;

# ---- Spell description helpers -----------------------------

# spell_affect_index → concise type label
my %SAI_LABEL = (
    0  => "DD",           1  => "Heal",
    2  => "AC Buff",      3  => "AoE DD",
    4  => "Summon",       5  => "Vision",
    6  => "Mana",         7  => "Stat Buff",
    9  => "Invis",        10 => "Illusion",
    11 => "Charm",        12 => "Calm",
    13 => "Fear",         14 => "Dispel",
    15 => "Stun",         16 => "Speed",
    17 => "Slow",         18 => "DmgShield",
    19 => "Proc",         20 => "Weaken",
    21 => "Banish",       22 => "Blind",
    23 => "Cold DD",      24 => "Poison DD",
    25 => "Fire DD",      27 => "MemBlur",
    28 => "Gravity",      29 => "Drowning",
    30 => "Lifetap DoT",  31 => "Fire AoE",
    33 => "Cold AoE",     34 => "Poison AoE",
    40 => "Teleport",     41 => "Bard DD",
    42 => "Bard Buff",    43 => "Bard Calm",
    50 => "Conversion",
);

# targettype → prefix to prepend (only when meaningful/non-default)
# Single target (5=ST_Target, 1=ST_TargetOptional, 13=ST_Tap) gets no prefix
my %TARGET_PREFIX = (
    2  => "AoE",      # ST_AEClientV1
    3  => "Group",    # ST_GroupTeleport
    4  => "PBAoE",    # ST_AECaster
    6  => "Self",     # ST_Self
    8  => "AoE",      # ST_AETarget
    9  => "Animal",   # ST_Animal
    10 => "Undead",   # ST_Undead
    11 => "Summon",   # ST_Summoned
    14 => "Pet",      # ST_Pet
    15 => "Corpse",   # ST_Corpse
    20 => "AoE",      # ST_TargetAETap
    24 => "AoE",      # ST_UndeadAE
    25 => "AoE",      # ST_SummonedAE
    32 => "AoE",      # ST_AETargetHateList
    33 => "AoE",      # ST_HateList
    36 => "AoE",      # ST_AreaClientOnly
    37 => "AoE",      # ST_AreaNPCOnly
    38 => "Pet",      # ST_SummonedPet
    39 => "Group",    # ST_GroupNoPets
    40 => "AoE",      # ST_AEBard
    41 => "Group",    # ST_Group
    42 => "Cone",     # ST_Directional
    43 => "Group",    # ST_GroupClientAndPet
    44 => "Beam",     # ST_Beam
    45 => "Ring",     # ST_Ring
    50 => "AoE",      # ST_TargetAENoPlayersPets
);

sub get_spell_desc {
    my ($sai, $targettype) = @_;
    my $type   = $SAI_LABEL{$sai}          || "Spell";
    my $prefix = $TARGET_PREFIX{$targettype} || "";
    # Avoid doubling "AoE" when the SAI already contains it
    if ($prefix eq "AoE" && $type =~ /AoE/) { $prefix = ""; }
    return $prefix ? "$prefix $type" : $type;
}

# ---- Query eligible spells ---------------------------------
print "Querying eligible spells...\n";
my $sth = $dbh->prepare(q{
    SELECT
        s.id,
        s.name,
        s.mana,
        s.cast_time,
        s.targettype,
        s.SpellAffectIndex,
        s.effectid1,
        s.icon
    FROM spells_new s
    WHERE
        s.cast_time > 0
        AND s.id    > 0
        AND s.id    < 60000
        AND NOT (
            s.classes1=255  AND s.classes2=255  AND s.classes3=255  AND s.classes4=255  AND
            s.classes5=255  AND s.classes6=255  AND s.classes7=255  AND s.classes8=255  AND
            s.classes9=255  AND s.classes10=255 AND s.classes11=255 AND s.classes12=255 AND
            s.classes13=255 AND s.classes14=255 AND s.classes15=255 AND s.classes16=255
        )
        AND s.name NOT LIKE '%test%'
        AND s.name NOT LIKE '%UNUSED%'
        AND s.name NOT LIKE '%zzz%'
        AND s.name NOT LIKE '%NULL%'
        AND s.name != ''
    ORDER BY s.id
});
$sth->execute();

# ---- Expansion ID from spell ID range ----------------------
# 0 = Classic   (id <  900)
# 1 = Kunark    (id < 1530)
# 2 = Velious   (id < 1960)
# 3 = Luclin+   (id >= 1960)
sub spell_expac {
    my $id = shift;
    return 0 if $id <  900;
    return 1 if $id < 1530;
    return 2 if $id < 1960;
    return 3;
}

my @spells;
while (my $row = $sth->fetchrow_hashref()) {
    push @spells, {
        id        => $row->{id},
        level     => $spell_level{ $row->{id} } || 1,
        name      => $row->{name},
        scroll_id => $scroll_map{ $row->{id} } || 0,
        expac     => spell_expac($row->{id}),
        mana      => $row->{mana}      || 0,
        cast_ms   => $row->{cast_time} || 0,   # spells_new.cast_time is in ms
        icon      => $row->{icon} || 0,
        effectid1 => $row->{effectid1} || 0,
        desc      => get_spell_desc($row->{SpellAffectIndex}, $row->{targettype}),
        lore      => $spell_lore{ $row->{id} } // "",
    };
}
$sth->finish();
$dbh->disconnect();

my $with_scroll = grep { $_->{scroll_id} > 0 } @spells;
printf "Found %d eligible spells (%d with scrolls, %d direct-scribe).\n",
    scalar @spells, $with_scroll, scalar(@spells) - $with_scroll;

# ---- Write spell_pool.lua ----------------------------------
my $out_path = '/home/eqemu/server/quests/lua_modules/spell_pool.lua';
$out_path = 'server/quests/lua_modules/spell_pool.lua' unless -d '/home/eqemu';

open(my $out, '>', $out_path) or die "Cannot write $out_path: $!";

print $out <<'HEADER';
-- ============================================================
-- spell_pool.lua  (AUTO-GENERATED -- do not edit by hand)
-- Regenerate: docker exec akk-stack-eqemu-server-1 \
--               perl /home/eqemu/server/../assets/scripts/generate_spell_pool.pl
--
-- All classes can learn any spell (server-side normalization applied).
-- Each entry:
--   level     = min level requirement
--   name      = spell name
--   scroll_id = scroll item ID (0 = none, ScribeSpell used directly)
--   expac     = 0:Classic 1:Kunark 2:Velious 3:Luclin+
--   mana      = mana cost (0 = free/instant)
--   cast_ms   = cast time in milliseconds (0 = instant)
--   icon      = spell icon index (from spells_new.spell_icon)
--   desc      = short description e.g. "Group Heal", "AoE Fire DD"
-- ============================================================

local M = {}

M.pool = {
HEADER

for my $sp (@spells) {
    my $name_esc = $sp->{name};
    $name_esc =~ s/\\/\\\\/g;
    $name_esc =~ s/"/\\"/g;
    my $desc_esc = $sp->{desc};
    $desc_esc =~ s/\\/\\\\/g;
    $desc_esc =~ s/"/\\"/g;
    my $lore_esc = $sp->{lore};
    $lore_esc =~ s/\\/\\\\/g;
    $lore_esc =~ s/"/\\"/g;
    printf $out
        "    [%d] = { level=%d, name=\"%s\", scroll_id=%d, expac=%d, mana=%d, cast_ms=%d, icon=%d, effectid1=%d, desc=\"%s\", lore=\"%s\" },\n",
        $sp->{id}, $sp->{level}, $name_esc, $sp->{scroll_id}, $sp->{expac},
        $sp->{mana}, $sp->{cast_ms}, $sp->{icon}, $sp->{effectid1}, $desc_esc, $lore_esc;
}

print $out <<'FOOTER';
}

return M
FOOTER

close $out;
print "Written: $out_path\n";
print "Reload zones after container restart for the Lua module to take effect.\n";
