sub EVENT_SAY {
  if ($text =~ /hail/i) {
    quest::say("Greetings, $name. I am Kilven, quartermaster of this hall. I maintain supplies for adventurers. Browse my wares if you need provisions.");
  }
}

1;
