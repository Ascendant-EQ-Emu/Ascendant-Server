# items: 67704
my %book_network_destinations = (
    qeynos2       => { id => 2,   x => 487,      y => 219,   z => 2,       h => 267, req => 0,  label => 'North Qeynos' },
    gfaydark      => { id => 54,  x => -734,     y => -188,  z => -3,      h => 0,   req => 0,  label => 'Greater Faydark' },
    misty         => { id => 33,  x => -1262.71, y => -546,  z => 8,       h => 2,   req => 0,  label => 'Misty Thicket' },
    everfrost     => { id => 30,  x => -31,      y => 2835,  z => -62,     h => 0,   req => 0,  label => 'Everfrost' },
    butcher       => { id => 68,  x => -523,     y => 1726,  z => -1,      h => 45,  req => 0,  label => 'Butcherblock' },
    rathemtn      => { id => 50,  x => 309.5,    y => -1166, z => -0.5,    h => 34,  req => 0,  label => 'Rathe Mountains' },
    feerrott      => { id => 47,  x => -163,     y => 908,   z => -9,      h => 248, req => 0,  label => 'Feerrott' },
    nektulos      => { id => 25,  x => -840,     y => -809,  z => 9,       h => 0,   req => 0,  label => 'Nektulos' },
    fieldofbone   => { id => 78,  x => 1845,     y => -2980, z => 11,      h => 259, req => 1,  label => 'Field of Bone' },
    firiona       => { id => 84,  x => 4673,     y => -455,  z => 9,       h => 128, req => 1,  label => 'Firiona Vie' },
    overthere     => { id => 93,  x => 1888,     y => 3133,  z => -51,     h => 128, req => 1,  label => 'Overthere' },
    greatdivide   => { id => 118, x => -1813.22, y => 0,     z => 393.44,  h => 0,   req => 2,  label => 'Great Divide' },
    nexus         => { id => 152, x => 442,      y => 48,    z => -29,     h => 388, req => 3,  label => 'Nexus' },
    shadeweaver   => { id => 165, x => -2433,    y => -2970, z => -215,    h => 236, req => 3,  label => 'Shadeweaver' },
    potranquility => { id => 203, x => -1463,    y => 774,   z => -878,    h => 131, req => 4,  label => 'Plane of Tranquility' },
    gunthak       => { id => 224, x => -1030,    y => 1780,  z => 60,      h => 0,   req => 5,  label => 'Gunthak' },
    arena         => { id => 77,  x => 147.04,   y => -1014.25, z => 48,    h => 256, req => 0,  label => 'Arena' },
    crescent      => { id => 394, x => -2635,    y => -1240, z => -150.6,  h => 149, req => 12, label => 'Crescent Reach' }
);

my @book_network_order = (
    'qeynos2', 'gfaydark', 'misty', 'everfrost', 'butcher', 'rathemtn',
    'feerrott', 'nektulos', 'fieldofbone', 'firiona', 'overthere',
    'greatdivide', 'nexus', 'shadeweaver', 'potranquility', 'gunthak',
    'arena', 'crescent'
);

sub is_book_network_click {
    if (!defined $door) {
        return 0;
    }

    if (!$door->HasDestinationZone()) {
        return 0;
    }

    my $dz = lc($door->GetDestinationZoneName());
    return 1 if ($dz eq 'poknowledge');
    return 1 if (exists $book_network_destinations{$dz});

    return 0;
}

sub show_book_network_menu {
    my $exp = $expansion;
    my $line = '';
    my $count = 0;

    $client->Message(315, 'Book Network: choose a destination. Locked zones are marked.');

    foreach my $key (@book_network_order) {
        next if (!exists $book_network_destinations{$key});
        my $d = $book_network_destinations{$key};
        my $locked = ($d->{req} > 0 && $exp < $d->{req}) ? ' (Locked)' : '';
        $line .= plugin::saylink("bookgo_$key", $d->{label} . $locked) . '  ';
        $count++;
        if ($count % 3 == 0) {
            $client->Message(315, $line);
            $line = '';
        }
    }

    if ($line ne '') {
        $client->Message(315, $line);
    }
}

sub EVENT_CLICKDOOR {
    if (is_book_network_click()) {
        show_book_network_menu();
        return 1;
    }

    return 0;
}

sub EVENT_ENTERZONE { #message only appears in Cities / Pok and wherever the Wayfarer Camps (LDON) is in.  This message won't appear in the player's home city.
  if($ulevel >= 15 && !defined($qglobals{Wayfarer}) && quest::is_lost_dungeons_of_norrath_enabled()) {
    if($client->GetStartZone()!=$zoneid && ($zoneid == 1 || $zoneid == 2 || $zoneid == 3 || $zoneid == 8 || $zoneid == 9 || $zoneid == 10 || $zoneid == 19 || $zoneid == 22 || $zoneid == 23 || $zoneid == 24 || $zoneid == 29 || $zoneid == 30 || $zoneid == 34 || $zoneid == 35 || $zoneid == 40 || $zoneid == 41 || $zoneid == 42 || $zoneid == 45 || $zoneid == 49 || $zoneid == 52 || $zoneid == 54 || $zoneid == 55 || $zoneid == 60 || $zoneid == 61 || $zoneid == 62 || $zoneid == 67 || $zoneid == 68 || $zoneid == 75 || $zoneid == 82 || $zoneid == 106 || $zoneid == 155 || $zoneid == 202 || $zoneid == 382 || $zoneid == 383 || $zoneid == 392 || $zoneid == 393 || $zoneid == 408)) {
	  $client->Message(15,"A mysterious voice whispers to you, 'If you can feel me in your thoughts, know this -- something is changing in the world and I reckon you should be a part of it. I do not know much, but I do know that in every home city and the wilds there are agents of an organization called the Wayfarers Brotherhood. They are looking for recruits . . . If you can hear this message, you are one of the chosen. Rush to your home city, or search the West Karanas and Rathe Mountains for a contact if you have been exiled from your home for your deeds, and find out more. Adventure awaits you, my friend.'");
	}
  }
}

sub EVENT_COMBINE_VALIDATE {
	# $validate_type values = { "check_zone", "check_tradeskill" }
	# criteria exports:
	#	"check_zone"		=> zone_id
	#	"check_tradeskill"	=> tradeskill_id (not active)
	if ($recipe_id == 10344) {
		if ($validate_type =~/check_zone/i) {
			if ($zone_id != 289 && $zone_id != 290) {
				return 1;
			}
		}
	}

	return 0;
}

sub EVENT_COMBINE_SUCCESS {
    if ($recipe_id =~ /^1090[4-7]$/) {
        $client->Message(1,
            "The gem resonates with power as the shards placed within glow unlocking some of the stone's power. ".
            "You were successful in assembling most of the stone but there are four slots left to fill, ".
            "where could those four pieces be?"
        );
    }
    elsif ($recipe_id =~ /^10(903|346|334)$/) {
        my %reward = (
            melee  => {
                10903 => 67665,
                10346 => 67660,
                10334 => 67653
            },
            hybrid => {
                10903 => 67666,
                10346 => 67661,
                10334 => 67654
            },
            priest => {
                10903 => 67667,
                10346 => 67662,
                10334 => 67655
            },
            caster => {
                10903 => 67668,
                10346 => 67663,
                10334 => 67656
            }
        );
        my $type = plugin::ClassType($class);
        quest::summonitem($reward{$type}{$recipe_id});
        quest::summonitem(67704); # Item: Vaifan's Clockwork Gemcutter Tools
        $client->Message(1,"Success");
    }
}

sub EVENT_CONNECT {
    # the main key is the ID of the AA
    # the first set is the age required in seconds
    # the second is if to ignore the age and grant anyways live test server style
    # the third is enabled
    my %vet_aa = (
        481 => [31536000, 1, 1], ## Lesson of the Devote 1 yr
        482 => [63072000, 1, 1], ## Infusion of the Faithful 2 yr
        483 => [94608000, 1, 1], ## Chaotic Jester 3 yr
        484 => [126144000, 1, 1], ## Expedient Recovery 4 yr
        485 => [157680000, 1, 1], ## Steadfast Servant 5 yr
        486 => [189216000, 1, 1], ## Staunch Recovery 6 yr
        487 => [220752000, 1, 1], ## Intensity of the Resolute 7 yr
        511 => [252288000, 1, 1], ## Throne of Heroes 8 yr
        2000 => [283824000, 1, 1], ## Armor of Experience 9 yr
        8081 => [315360000, 1, 1], ## Summon Resupply Agent 10 yr
        8130 => [346896000, 1, 1], ## Summon Clockwork Banker 11 yr
        453 => [378432000, 1, 1], ## Summon Permutation Peddler 12 yr
        182 => [409968000, 1, 1], ## Summon Personal Tribute Master 13 yr
        600 => [441504000, 1, 1] ## Blessing of the Devoted 14 yr
    );
    my $age = $client->GetAccountAge();
    for (my ($aa, $v) = each %vet_aa) {
        if ($v[2] && ($v[1] || $age >= $v[0])) {
            $client->GrantAlternateAdvancementAbility($aa, 1);
        }
    }
}

sub EVENT_SAY {
    if ($text =~ /^bookgo_(\w+)$/i) {
        my $key = lc($1);
        if (!exists $book_network_destinations{$key}) {
            $client->Message(13, 'Unknown destination.');
            return;
        }

        my $d = $book_network_destinations{$key};
        if ($d->{req} > 0 && $expansion < $d->{req}) {
            $client->Message(13, 'That destination is expansion locked on this server.');
            return;
        }

        quest::movepc($d->{id}, $d->{x}, $d->{y}, $d->{z}, $d->{h});
        return;
    }
}
