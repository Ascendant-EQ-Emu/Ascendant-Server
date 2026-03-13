sub EVENT_DEATH_COMPLETE {
$ventani = $entity_list->GetMobByNpcTypeID(128091);
$tukaarak = $entity_list->GetMobByNpcTypeID(128092);
$hraashna = $entity_list->GetMobByNpcTypeID(128093);
if (!$ventani && !$tukaarak && !$hraashna) {
if ($killer_mob && $killer_mob->IsClient()) {
  my $killer_client = $killer_mob->CastToClient();
  my $account_id = $killer_client->AccountID();
  my $char_name = $killer_client->GetCleanName();
  quest::set_data("velious_sleeper_" . $account_id, $char_name);
  my $first_key = "first_kill_sleeper_wake";
  unless (quest::get_data($first_key)) {
    quest::set_data($first_key, $char_name);
    quest::we(15, "SERVER FIRST! " . $char_name . " and their raid have awakened The Sleeper for the first time on this server!");
  }
}
quest::signalwith(128094,66,0); # NPC: #The_Sleeper
quest::shout("Warders, I have fallen. Prepare yourselves, these fools are determined to unleash doom!");
}
else { 
quest::shout("Warders, I have fallen. Prepare yourselves, these fools are determined to unleash doom!");
}
 }
