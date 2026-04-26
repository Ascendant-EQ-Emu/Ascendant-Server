#!/usr/bin/env perl
# ============================================================
# export_spells_us.pl
# Exports normalized spells_new to spells_us.txt format
# (all classes have equal level requirements per spell)
#
# Run:
#   docker exec akk-stack-eqemu-server-1 \
#     perl /home/eqemu/server/../assets/scripts/export_spells_us.pl > spells_us.txt
# ============================================================

use strict;
use warnings;
use DBI;
use JSON;

my $config_file = '/home/eqemu/server/eqemu_config.json';
$config_file = 'server/eqemu_config.json' unless -f $config_file;

open(my $fh, '<', $config_file) or die "Cannot read $config_file: $!";
my $raw = do { local $/; <$fh> };
close $fh;

my $cfg = decode_json($raw);
my $db  = $cfg->{server}{database};
my $dbh = DBI->connect(
    "DBI:mysql:database=$db->{db};host=$db->{host};port=$db->{port}",
    $db->{username}, $db->{password},
    { RaiseError => 1, PrintError => 0 }
) or die "DB connect failed: $DBI::errstr";

# Query all spell data from normalized spells_new
# Format matches spells_us.txt: id|name|range|aoerange|pushback|pushup|cast_time|
# recast_time|buffduration|aoe_duration|mana|effect_base_value_1|effect_base_value_2|...
# |classes1|classes2|...|classes16|...

my $sth = $dbh->prepare(q{
    SELECT *
    FROM spells_new
    WHERE id > 0 AND id < 60000
    ORDER BY id
});
$sth->execute();

# Get column names to preserve order
my @cols = @{ $sth->{NAME} };

# Print header with column names (for reference)
print "# Normalized spells_us.txt export (all classes have equal level requirements)\n";
print "# Columns: " . join("|", @cols) . "\n";
print "#\n";

my $count = 0;
while (my $row = $sth->fetchrow_hashref()) {
    # Build pipe-delimited line with all fields in order
    my @values = map { $row->{$_} // '' } @cols;
    print join("|", @values) . "\n";
    $count++;
}
$sth->finish();
$dbh->disconnect();

print STDERR "Exported $count spells\n";
