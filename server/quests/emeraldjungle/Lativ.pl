# Lativ - Emerald Jungle
# Claw of the Spiritual Elder quest (#6)
# Hand him the Seal of Choatl (48074), he goes hostile
# Drops Sacred Figurine (48075) on death via loot table
# items: 48074, 48075

sub EVENT_SAY {
  if($text=~/hail/i) {
    quest::say("Fool! Haven't you learned by now my wrath is absolute!");
  }
}

sub EVENT_ITEM {
  if(plugin::check_handin(\%itemcount, 48074 => 1)) { #Seal of Choatl
    quest::say("What is this?! It can't be!");
    quest::settimer("lativ_attack", 2);
  }
  plugin::return_items(\%itemcount);
}

sub EVENT_TIMER {
  if($timer eq "lativ_attack") {
    quest::stoptimer("lativ_attack");
    $npc->AddToHateList($client, 1, 999999);
  }
}
