sub EVENT_KILLED_MERIT {
	# Award Vox kill credit (account-wide)
	# This event fires for each player who gets kill credit
	my $account_id = $client->AccountID();
	my $char_name = $client->GetCleanName();
	
	# Set account-wide bucket (30 day TTL)
	quest::set_data("kunark_talendor_" . $account_id, $char_name);
	
	my $first_key = "first_kill_talendor";
	unless (quest::get_data($first_key)) {
		quest::set_data($first_key, $char_name . "|" . $uguild);
		quest::we(15, "SERVER FIRST! " . $char_name . " <" . $uguild . "> and their group have slain Talendor for the first time on this server!");
	}
}