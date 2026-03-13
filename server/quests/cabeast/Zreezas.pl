#BEGIN File: cabeast\Zreezas.pl (106119)
#Quest file for Cabilis East - Claw of the Mature Patriarch (#5) + Claw of the Spiritual Elder (#6)
# items: 48062, 48063, 48064, 48068

sub EVENT_SAY {
  if($text=~/hail/i) {
    quest::say("Sorry, I am busy trying to track down a traitor planning on overthrowing the Patriarchs. Unless you are [willing to help], I will have to send you on your way.");
  }
  if($text=~/help/i) {
    quest::say("Clues have lead me to believe that some corrupt individuals are working in the City of Mist and Kaesora. I have been searching in spiritual areas for clues to this traitor's name. Return to me any information which may help in my investigation.");
  }
  if($text=~/his name/i) {
    quest::say("Would that be the traitor's name? Hmm. . .that name does sound familiar. He had once gained the rank of young patriarch before he was banished from the Patriarchs of Cabilis. Now where [Lativ] is I may know.");
  }
  if($text=~/where.*lativ/i || $text=~/^lativ$/i) {
    quest::say("I have heard talk of him training in a jungle region. Go seek him out and return with whatever you can retrieve from his demise.");
  }
}

sub EVENT_ITEM {
  if(plugin::check_handin(\%itemcount, 48062 => 1, 48063 => 1)) { #Hidden Plans (Top Half, Bottom Half)
    quest::say("Good work, $name.");
    quest::emote("fits the pieces of the plans together and studies them for a moment.");
    quest::say("Ah, so the plot thickens. It seems that the rumored attacks are set to be conducted soon. Seek out Ixthal and tell him about these attacks. If he does not believe you, show him these plans as proof.");
    quest::summonitem(48064); #Lativ's Plans
    quest::exp(15000);
  }
  elsif(plugin::check_handin(\%itemcount, 48068 => 1)) { #Lativ's Remains
    quest::say("What is this? This cannot be Lativ. It seems as though he has gained more power than we have been aware of thus far. Take the remains to Prime Patriarch Vuzx. He should know what is going on from this point forward.");
    quest::summonitem(48068); #Lativ's Remains - give back for Vuzx
    quest::exp(15000);
  }
  plugin::return_items(\%itemcount);
}

#END File: cabeast\Zreezas.pl (106119)