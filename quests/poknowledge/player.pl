my %book_door_ids = map { $_ => 1 } qw(
	18 20 21 23 26 27 28 29 30 31 33 34 35 36 37 137 138 150 152 156 157 158
);

my %book_destinations = (
	fieldofbone   => { id => 78,  x => 1845,     y => -2980, z => 11,      h => 259, req => 1, label => 'Field of Bone' },
	nektulos      => { id => 25,  x => -840,     y => -809,  z => 9,       h => 0,   req => 0, label => 'Nektulos' },
	feerrott      => { id => 47,  x => -163,     y => 908,   z => -9,      h => 248, req => 0, label => 'Feerrott' },
	overthere     => { id => 93,  x => 1888,     y => 3133,  z => -51,     h => 128, req => 1, label => 'Overthere' },
	firiona       => { id => 84,  x => 4673,     y => -455,  z => 9,       h => 128, req => 1, label => 'Firiona Vie' },
	potranquility => { id => 203, x => -1463,    y => 774,   z => -878,    h => 131, req => 4, label => 'Plane of Tranquility' },
	qeynos2       => { id => 2,   x => 487,      y => 219,   z => 2,       h => 267, req => 0, label => 'North Qeynos' },
	shadeweaver   => { id => 165, x => -2433,    y => -2970, z => -215,    h => 236, req => 3, label => 'Shadeweaver' },
	greatdivide   => { id => 118, x => -1813.22, y => 0,     z => 393.44,  h => 0,   req => 2, label => 'Great Divide' },
	nexus         => { id => 152, x => 442,      y => 48,    z => -29,     h => 388, req => 3, label => 'Nexus' },
	gfaydark      => { id => 54,  x => -734,     y => -188,  z => -3,      h => 0,   req => 0, label => 'Greater Faydark' },
	everfrost     => { id => 30,  x => -31,      y => 2835,  z => -62,     h => 0,   req => 0, label => 'Everfrost' },
	butcher       => { id => 68,  x => -523,     y => 1726,  z => -1,      h => 45,  req => 0, label => 'Butcherblock' },
	misty         => { id => 33,  x => -1262.71, y => -546,  z => 8,       h => 2,   req => 0, label => 'Misty Thicket' },
	gunthak       => { id => 224, x => -1030,    y => 1780,  z => 60,      h => 0,   req => 5, label => 'Gunthak' },
	arena         => { id => 77,  x => 147.04,   y => -1014.25, z => 48,    h => 256, req => 0, label => 'Arena' },
	rathemtn      => { id => 50,  x => 309.5,    y => -1166, z => -0.5,    h => 34,  req => 0, label => 'Rathe Mountains' },
	crescent      => { id => 394, x => -2635,    y => -1240, z => -150.6,  h => 149, req => 12, label => 'Crescent Reach' }
);

sub show_book_menu {
	my @ordered_keys = (
		'qeynos2', 'gfaydark', 'misty', 'everfrost', 'butcher', 'rathemtn',
		'feerrott', 'nektulos', 'fieldofbone', 'firiona', 'overthere',
		'greatdivide', 'nexus', 'shadeweaver', 'potranquility', 'gunthak',
		'arena', 'crescent'
	);

	$client->Message(315, "Book Network: Click a destination keyword below.");

	my $line = "";
	my $shown = 0;
	foreach my $key (@ordered_keys) {
		next if (!exists $book_destinations{$key});
		my $dest = $book_destinations{$key};
		my $required_expansion = $dest->{req};
		my $is_locked = ($required_expansion > 0 && $expansion < $required_expansion);
		my $tag = $is_locked ? " (Locked)" : "";
		$line .= " [go_${key}]";
		$shown++;
		if ($shown % 6 == 0) {
			$client->Message(315, $line);
			$line = "";
		}
	}

	if ($line ne "") {
		$client->Message(315, $line);
	}

	$client->Message(315, "Type or click [go_zone] (example: [go_gfaydark]). Expansion-locked zones will be blocked.");
}

sub EVENT_ENTERZONE {
	if (quest::istaskcompleted(5745) == 0 && quest::istaskactive(5745) == 0) #Check if completed Task: New Beginnings
	{
		quest::assigntask(5745); #Force assign Task: New Beginnings
	}

	set_current_position();
	quest::settimer("check_idle", 1200);
}

sub EVENT_CLICKDOOR {
	if (exists $book_door_ids{$doorid}) {
		show_book_menu();
		return 1;
	}

	if ($doorid == 139) {
		if ($client->CalculateDistance(1452, 347, -113) <= 30) {
			quest::movepc(151, -425, 0, -25, 127); # Zone: bazaar
			return 1;
		}
	}

	return 0;
}

sub EVENT_SAY {
	if ($text =~ /^go_(\w+)$/i) {
		my $zone_key = lc($1);
		if (!exists $book_destinations{$zone_key}) {
			$client->Message(13, "Unknown destination.");
			return;
		}

		my $dest = $book_destinations{$zone_key};
		if ($dest->{req} > 0 && $expansion < $dest->{req}) {
			$client->Message(13, "That destination is expansion locked on this server.");
			return;
		}

		quest::movepc($dest->{id}, $dest->{x}, $dest->{y}, $dest->{z}, $dest->{h});
		return;
	}

	if ($text =~ /^book$/i) {
		show_book_menu();
		return;
	}
}


sub EVENT_POPUPRESPONSE {
	if ($popupid == 2) {
		quest::movepc(46, -34, -721, -27, 221.21); # Zone: innothule
	}
	if ($popupid == 3) {
		quest::movepc(38, 296, -2330, -45.4, 127); # Zone: tox
	}
	if ($popupid == 4) {
		quest::movepc(38, -569, 2325, -43.4, 39); # Zone: tox
	}
	if ($popupid == 5) {
		quest::movepc(56, 933.79, -1358, -109); # Zone: steamfont
	}
	if ($popupid == 6) {
		quest::movepc(9, 77.31, -660.57, -30.24); # Zone: freportw
	}
}

sub EVENT_TIMER {
	if ($timer == 2) {
		quest::movepc(413, -361, -462, 5); # Zone: innothuleb
	}
	if ($timer == 3) {
		quest::movepc(414, 248, -1684, 33, 88); # Zone: toxxulia
	}
	if ($timer == 4) {
		quest::movepc(414, -1801, 1907, 119, 195.5); # Zone: toxxulia
	}
	if ($timer == 5) {
		quest::movepc(448, 940, -1122, 5, 98); # Zone: steamfontmts
	}
	if ($timer == 6) {
		quest::movepc(383, -173, -188, -69, 192); # Zone: freeportwest
	}

	if ($timer eq "check_idle") {
		my $last_x  = $client->GetEntityVariable("last_x");
		my $last_y  = $client->GetEntityVariable("last_y");
		my $is_idle = ($last_x eq $client->GetX() && $last_y eq $client->GetY());

		if ($is_idle && $uguild_id > 0) {
			$client->SendToGuildHall();
		}

		set_current_position();
	}
}

sub set_current_position() {
	$client->SetEntityVariable("last_x", $client->GetX());
	$client->SetEntityVariable("last_y", $client->GetY());
}
