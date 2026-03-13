# Marked Passage (Item 26508) - Expedition Compatible
# First use: Marks location and teleports to Guild Lobby
# Second use: Returns to marked location (including expedition instances)
# Author: Straps

sub EVENT_SPELL_EFFECT_CLIENT {

    my $guild_lobby_zone_id = 344; # Guild Lobby
    my $bucket_key = "marked_passage_" . $client->CharacterID();
    my $bucket_ttl = 1800; # 30 minutes

    # Check if we have a stored location
    my $stored_location = quest::get_data($bucket_key);

    if ($stored_location) {
        # Second use: Return to stored location
        my @coords = split(/,/, $stored_location);

        # Now expecting 6 values: zone_id, instance_id, x, y, z, heading
        if (scalar(@coords) == 6) {
            my ($zone_id, $instance_id, $x, $y, $z, $heading) = @coords;

            # Delete the stored location
            quest::delete_data($bucket_key);

            # Store teleport data in a timer-specific bucket
            my $teleport_key = "marked_passage_teleport_" . $client->CharacterID();
            quest::set_data($teleport_key, $stored_location, 5); # 5 second TTL

            # Set a timer to perform the actual teleport
            quest::settimer("marked_passage_return", 1);

            $client->Message(10, "Returning to marked location...");
        } else {
            $client->Message(13, "Error: Invalid stored location data.");
        }

    } else {
        # First use: Store current location and port to Guild Lobby
        my $current_zone_id = $zoneid;
        my $current_instance_id = $client->GetInstanceID();
        my $x = $client->GetX();
        my $y = $client->GetY();
        my $z = $client->GetZ();
        my $heading = $client->GetHeading();

        # Store location in data bucket (now with instance_id)
        my $location_data = "$current_zone_id,$current_instance_id,$x,$y,$z,$heading";
        quest::set_data($bucket_key, $location_data, $bucket_ttl);

        # Random spawn location in Guild Lobby
        my @guild_lobby_spawns = (
            [   0,  315,  2, 0 ],   # center-ish, commonly safe
            [ -262, 414,  2, 0 ],   # west side, clear floor
            [  257, 411,  2, 0 ],   # east side, clear floor
            [   -2, 515,  2, 0 ],   # north side, clear floor
        );

        # Pick random spawn point
        my $random_spawn = $guild_lobby_spawns[int(rand(scalar(@guild_lobby_spawns)))];
        my $spawn_data = join(",", $guild_lobby_zone_id, 0, @$random_spawn); # Instance 0 for Guild Lobby

        # Store teleport destination in timer-specific bucket
        my $teleport_key = "marked_passage_teleport_" . $client->CharacterID();
        quest::set_data($teleport_key, $spawn_data, 5); # 5 second TTL

        # Set a timer to perform the actual teleport
        quest::settimer("marked_passage_goto", 1);

        $client->Message(10, "Location marked. Teleporting to Guild Lobby...");
    }

}
