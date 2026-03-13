# Ascendant Gambling System
# Plugin for Harley Wynn gambling NPC
# Author: Straps
#
# Tiered loot pool with Fisher-Yates shuffle and lore-item skip.
# Odds: Legendary 0.25%, Jackpot 1%, Exceptional 4%, Rare ~20%, Uncommon ~25%, Common ~50%
# Returns ($tier_name, $item_id) to the calling NPC script for messaging.

sub _pick_item {
  my ($client, @pool) = @_;
  my @shuffled = @pool;
  for (my $i = $#shuffled; $i > 0; $i--) {
    my $j = int(rand($i + 1));
    @shuffled[$i, $j] = @shuffled[$j, $i];
  }
  for my $item_id (@shuffled) {
    next unless $item_id && $item_id > 0;
    if (quest::getitemstat($item_id, "loreflag") && $client->CountItem($item_id) > 0) {
      next;
    }
    return $item_id;
  }
  return $shuffled[0];
}

sub DoGamble {
  my ($client, $npc) = @_;

  my @COMMON      = (25805, 1139, 66602, 25833, 66614, 66605, 1152, 66608, 25807, 1140, 66610, 66607, 1138, 12260, 9662, 9756);
  my @UNCOMMON    = (25814, 66604, 66611, 66609, 66606, 66603, 66612, 96467, 66601, 66613, 14402, 16868);
  my @RARE        = (17815, 14521, 11631, 7479, 31861, 12507, 14304, 11911);
  my @EXCEPTIONAL = (64748, 55572, 53738, 64747, 64706, 66432, 2300, 7466, 2469, 11604, 6342, 10580, 54915, 53752, 71982, 71991, 72000, 71992, 81266);
  my @JACKPOT     = (11646, 27310, 59509, 24890, 4164, 11668, 55430, 57191, 60438, 43970, 60944, 54934, 50852, 64187, 40620, 40659, 40660, 40619, 77459);
  my @LEGENDARY   = (57521, 139831, 14730, 13401, 10895, 6631, 66314, 66315, 1800, 54918, 77402, 372269);

  my $roll = rand();
  my ($tier_name, @pool);

  if ($roll < 0.0025) {
    $tier_name = "Legendary";
    @pool = @LEGENDARY;
  } elsif ($roll < 0.0125) {
    $tier_name = "Jackpot";
    @pool = @JACKPOT;
  } elsif ($roll < 0.0525) {
    $tier_name = "Exceptional";
    @pool = @EXCEPTIONAL;
  } elsif ($roll < 0.255) {
    $tier_name = "Rare";
    @pool = @RARE;
  } elsif ($roll < 0.505) {
    $tier_name = "Uncommon";
    @pool = @UNCOMMON;
  } else {
    $tier_name = "Common";
    @pool = @COMMON;
  }

  my $item_id = _pick_item($client, @pool);

  if (!$item_id || $item_id == 0) {
    $client->Message(13, "Harly frowns - something went wrong with the draw! Please report this.");
    return;
  }

  $client->SummonItem($item_id, 1);
  return ($tier_name, $item_id);
}

1;
