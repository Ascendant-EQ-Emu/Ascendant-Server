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

# ---- Query eligible spells ---------------------------------
# Uses normalized spells_new (all classes have the same min level after
# normalization, so any class can learn any spell at that level).
print "Querying eligible spells...\n";
my $sth = $dbh->prepare(q{
    SELECT
        s.id,
        s.name,
        LEAST(
            IF(s.classes1  < 255, s.classes1,  999),
            IF(s.classes2  < 255, s.classes2,  999),
            IF(s.classes3  < 255, s.classes3,  999),
            IF(s.classes4  < 255, s.classes4,  999),
            IF(s.classes5  < 255, s.classes5,  999),
            IF(s.classes6  < 255, s.classes6,  999),
            IF(s.classes7  < 255, s.classes7,  999),
            IF(s.classes8  < 255, s.classes8,  999),
            IF(s.classes9  < 255, s.classes9,  999),
            IF(s.classes10 < 255, s.classes10, 999),
            IF(s.classes11 < 255, s.classes11, 999),
            IF(s.classes12 < 255, s.classes12, 999),
            IF(s.classes13 < 255, s.classes13, 999),
            IF(s.classes14 < 255, s.classes14, 999),
            IF(s.classes15 < 255, s.classes15, 999),
            IF(s.classes16 < 255, s.classes16, 999)
        ) AS min_level
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
        level     => $row->{min_level},
        name      => $row->{name},
        scroll_id => $scroll_map{ $row->{id} } || 0,
        expac     => spell_expac($row->{id}),
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
-- spell_pool.lua  (AUTO-GENERATED — do not edit by hand)
-- Regenerate: docker exec akk-stack-eqemu-server-1 \
--               perl /home/eqemu/server/../assets/scripts/generate_spell_pool.pl
--
-- All classes can learn any spell (server-side normalization applied).
-- Each entry:
--   level     = min level requirement (all classes equal after normalization)
--   name      = spell name
--   scroll_id = scroll item ID (0 = none, ScribeSpell used directly)
--   expac     = 0:Classic 1:Kunark 2:Velious 3:Luclin+
-- ============================================================

local M = {}

M.pool = {
HEADER

for my $sp (@spells) {
    my $name_esc = $sp->{name};
    $name_esc =~ s/\\/\\\\/g;
    $name_esc =~ s/"/\\"/g;
    printf $out "    [%d] = { level = %d, name = \"%s\", scroll_id = %d, expac = %d },\n",
        $sp->{id}, $sp->{level}, $name_esc, $sp->{scroll_id}, $sp->{expac};
}

print $out <<'FOOTER';
}

return M
FOOTER

close $out;
print "Written: $out_path\n";
print "Reload zones after restart for the Lua module to take effect.\n";
