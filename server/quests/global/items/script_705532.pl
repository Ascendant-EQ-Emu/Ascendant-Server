sub EVENT_ITEM_CLICK {
    my $caster        = $client->CastToClient();
    my $caster_charid = $caster->CharacterID();
    my $target        = $caster->GetTarget();

    # Default to self if no target or target is self
    my $is_self = 0;
    if (!$target || !$target->IsClient() || $target->CastToClient()->CharacterID() == $caster_charid) {
        $target  = $caster;
        $is_self = 1;
    }

    my $target_client = $target->CastToClient();
    my $target_name   = $target_client->GetCleanName();
    my $target_charid = $target_client->CharacterID();

    # Combat check
    if ($caster->GetAggroCount() > 0) {
        $caster->Message(13, "You cannot use Divine Recall while in combat.");
        return;
    }
    if (!$is_self && $target_client->GetAggroCount() > 0) {
        $caster->Message(13, "$target_name is in combat and cannot be recalled.");
        return;
    }

    # 30-second cooldown on caster
    my $cd_key = "divine_recall_cd_" . $caster_charid;
    my $cd     = quest::get_data($cd_key);
    if ($cd) {
        my $remaining = 30 - (time() - $cd);
        if ($remaining > 0) {
            $caster->Message(13, "Divine Recall is on cooldown for $remaining more second(s).");
            return;
        }
    }

    # Check that target has a recent death location bucket
    my $loc_key = "divine_recall_loc_" . $target_charid;
    my $loc     = quest::get_data($loc_key);
    unless ($loc) {
        $caster->Message(13, "$target_name has no recent death location. They must have died within the last 30 minutes.");
        return;
    }

    # Parse location for display
    my ($zone_id, $x, $y, $z, $heading, $instance_id) = split(/,/, $loc);
    #my ($zone_id, $x, $y, $z, $heading) = split(/,/, $loc);
    my $zone_name = quest::GetZoneLongName(quest::GetZoneShortName($zone_id));
    $zone_name = "Zone $zone_id" unless $zone_name;
    my $x_fmt = sprintf("%.1f", $x);
    my $y_fmt = sprintf("%.1f", $y);
    my $z_fmt = sprintf("%.1f", $z);

    # Store pending request token (90-second window for target to respond)
    quest::set_data("divine_recall_pending_" . $target_charid, time(), 90);

    # Set cooldown on caster now
    quest::set_data($cd_key, time(), 30);

    # Send confirmation popup to target
    my $caster_name = $caster->GetCleanName();
    my $popup_text  = $is_self
        ? "Return to your most recent death location?<br><br>"
          . "<c \"#FFCC00\">Zone:</c> $zone_name<br>"
          . "<c \"#FFCC00\">Location:</c> $x_fmt, $y_fmt, $z_fmt<br><br>"
          . "<c \"#FF9900\">You will be teleported immediately upon accepting.</c>"
        : "<c \"#00FFFF\">$caster_name</c> offers to recall you to your most recent death location.<br><br>"
          . "<c \"#FFCC00\">Zone:</c> $zone_name<br>"
          . "<c \"#FFCC00\">Location:</c> $x_fmt, $y_fmt, $z_fmt<br><br>"
          . "<c \"#FF9900\">You will be teleported immediately upon accepting.</c>";

    $target_client->Popup2("Divine Recall", $popup_text, 3001, 3002, 2, 0, "Accept", "Decline");

    unless ($is_self) {
        $caster->Message(15, "You offer divine recall to $target_name. Awaiting their response.");
    }
}
