sub EVENT_KILLED_MERIT {
	my $account_id = $client->AccountID();
	my $char_name = $client->GetCleanName();

	quest::set_data("velious_velketor_" . $account_id, $char_name);

	my $first_key = "first_kill_velketor";
	unless (quest::get_data($first_key)) {
		quest::set_data($first_key, $char_name . "|" . $uguild);
		quest::we(15, "SERVER FIRST! " . $char_name . " <" . $uguild . "> and their group have slain Velketor the Sorcerer for the first time on this server!");
	}
}
