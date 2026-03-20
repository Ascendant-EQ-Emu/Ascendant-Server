# Harley Wynn - Gambling NPC (cshome)
# Author: Straps
#
# Mirror of guildlobby/Harley_Wynn.pl — kept in sync.
# See that file for full documentation.

my $LUCKY_COIN_ID  = 1378;
my $COIN_PLAT_COST = 1500;

sub _buy_coins {
  my ($client, $qty) = @_;
  my $total_cost_copper = $COIN_PLAT_COST * $qty * 1000;
  if ($client->GetCarriedMoney() < $total_cost_copper) {
    my $total_pp = $COIN_PLAT_COST * $qty;
    $client->Message(13, "You need " . $total_pp . " platinum for $qty Lucky Coin" . ($qty > 1 ? "s" : "") . ". You don't have enough.");
    return;
  }
  my $total_pp = $COIN_PLAT_COST * $qty;
  $client->TakeMoneyFromPP($total_cost_copper, 1);
  $client->SummonItem($LUCKY_COIN_ID, $qty);
  $client->Message(15, "Harly slips her hand into your coin purse and takes out $total_pp platinum. She grins and counts out $qty Lucky Coin" . ($qty > 1 ? "s" : "") . " into your hand.");
}

sub EVENT_SAY {
  if ($text =~ /hail/i) {
    my $popup = "<c \"#FFD700\"><b>Harly Wynn's Lucky Draw!</b></c><br><br>"
      . "You have two ways to get a <c \"#00FFFF\">Lucky Coin</c>:<br><br>"
      . "<c \"#FFCC00\">1.</c> Use the <c \"#FF88FF\">Transmute Experience</c> Ascendant AA to manifest your hard-earned experience directly into a coin.<br><br>"
      . "<c \"#FFCC00\">2.</c> Purchase one from me for <c \"#FFD700\">$COIN_PLAT_COST platinum</c>.<br><br>"
      . "Once you have a coin, hand it to me and fate will decide your prize. The rewards range from modest to truly legendary - only the lucky find out what lies at the top.";

    $client->Popup2("Harly Wynn - Lucky Draw", $popup, 0, 0, 0, 0);
    plugin::Whisper("Step right up! Hand me a Lucky Coin and see what fate has in store. Need coins? "
      . quest::saylink("buy coin", 1, "Buy 1") . " | "
      . quest::saylink("buy 10 coins", 1, "Buy 10") . " | "
      . quest::saylink("buy 50 coins", 1, "Buy 50") . " -- $COIN_PLAT_COST platinum each.");
  }
  elsif ($text =~ /^buy coin$/i) {
    _buy_coins($client, 1);
  }
  elsif ($text =~ /^buy 10 coins$/i) {
    _buy_coins($client, 10);
  }
  elsif ($text =~ /^buy 50 coins$/i) {
    _buy_coins($client, 50);
  }
}

sub EVENT_ITEM {
  my $MAX_PER_TRADE = 10;

  # Return any non-coin items immediately
  foreach my $item_id (keys %itemcount) {
    next unless $item_id && $item_id > 0;
    next if $item_id == $LUCKY_COIN_ID;
    quest::summonitem($item_id, $itemcount{$item_id});
  }

  my $had = $itemcount{$LUCKY_COIN_ID} || 0;

  # Consume coins one at a time, cap at MAX_PER_TRADE
  my $rolled = 0;
  while ($rolled < $MAX_PER_TRADE && quest::handin({$LUCKY_COIN_ID => 1})) {
    my ($tier_name, $item_id) = plugin::DoGamble($client, $npc);
    if ($tier_name && $item_id) {
      my $item_link = quest::varlink($item_id);
      my $name = $client->GetCleanName();
      if ($tier_name eq "Legendary") {
        plugin::Whisper("*** LEGENDARY! *** Harly gasps - she's never seen anyone this lucky! You won: $item_link");
        quest::ze(15, "*** $name has gotten quite lucky at Harly Wynn's Lucky Draw, winning $item_link! ***");
      } elsif ($tier_name eq "Jackpot") {
        plugin::Whisper("** JACKPOT! ** Harly claps with delight! You won: $item_link");
        quest::ze(15, "** $name has gotten quite lucky at Harly Wynn's Lucky Draw, winning $item_link! **");
      } elsif ($tier_name eq "Exceptional") {
        plugin::Whisper("Exceptional find! Harly beams with excitement. You won: $item_link");
      } elsif ($tier_name eq "Rare") {
        plugin::Whisper("A rare prize! Harly nods appreciatively. You won: $item_link");
      } elsif ($tier_name eq "Uncommon") {
        plugin::Whisper("Uncommon! Not bad at all. You won: $item_link");
      } else {
        plugin::Whisper("Harly shrugs. 'Better luck next time!' You got: $item_link");
      }
    }
    $rolled++;
  }

  if ($rolled > 0) {
    my $charid = $client->CharacterID();
    my $gamble_key = "leaderboard_gambles_${charid}";
    my $gambles = int(quest::get_data($gamble_key) || 0) + $rolled;
    quest::set_data($gamble_key, $gambles);
  }

  if ($rolled == 0) {
    quest::say("I only accept Lucky Coins, " . $client->GetCleanName() . ". Hand me one and let fate decide!");
  } elsif ($had > $MAX_PER_TRADE) {
    $client->Message(13, "I can only draw $MAX_PER_TRADE fates at a time! The rest are returned.");
  }
}

1;
