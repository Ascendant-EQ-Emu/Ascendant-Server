# EPIC CLERIC (Timorous deep)
# items: 28023, 5532

sub EVENT_ITEM {
  if (plugin::check_handin(\%itemcount, 28023 => 1)) { #Orb of the triumvirate
    quest::emote("takes the orb from you. The avatar has determined that you are worthy!");
    
    quest::summonitem(705532);
    quest::summonitem(2856);
    # Clerics w/ Epic - 2856 - Reviviscence Wand

    my $item_link = quest::varlink(705532);
    quest::we(15, "$name has obtained $item_link! Congratulations, $name!");

    my $first_key = "first_epic_class_" . $client->GetClass();
    unless (quest::get_data($first_key)) {
        quest::set_data($first_key, $name);
        quest::enabletitle(406);
        quest::we(15, "A historic moment! $name is the FIRST " . $client->GetClassName() . " to obtain their class epic on this server! A title of legend has been bestowed!");
    }

    quest::exp(200000); 
    quest::ding();
    quest::depop();
  }
  plugin::return_items(\%itemcount); # return unused items
}
#End of File, Zone:timorous  NPC:96086 -- Avatar of Water