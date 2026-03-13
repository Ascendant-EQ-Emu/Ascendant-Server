# Spell 27086 - Transmute Experience (AA → Lucky Coin)
# Author: Straps
#
# Deducts 3 unspent AA points and summons a Lucky Coin (1378).
# Used with Harley Wynn's gambling system as an alternative to buying coins with plat.

my $COIN_AA_COST = 3;
my $LUCKY_COIN_ID = 1378;

sub EVENT_SPELL_EFFECT_CLIENT {
  my $aa = $client->GetAAPoints();
  if ($aa < $COIN_AA_COST) {
    $client->Message(13, "You need $COIN_AA_COST unspent AA points to transmute experience into a Lucky Coin. You only have $aa.");
    return;
  }
  $client->SetAAPoints($aa - $COIN_AA_COST);
  $client->SummonItem($LUCKY_COIN_ID, 1);
  $client->Message(15, "You transmute $COIN_AA_COST AA points into a Lucky Coin...");
}

1;
