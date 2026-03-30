# Spirekeeper Aethen - Wizard Spire Teleporter (Guild Lobby)
# Author: Straps
#
# Teleports players to wizard spire locations across Classic and Kunark zones.
# Level-gated destinations for planar zones (46+).
# Also offers expedition teleport if the player has an Expedition Port Pass.

# Set to 1 to restrict Velious ports to GMs only, 0 for all players
my $VELIOUS_ADMIN_ONLY = 0;

sub EVENT_SAY {
  if ($text =~ /hail/i) {
    my $eras = quest::saylink("classic", 1, "classic")." or ".quest::saylink("kunark", 1, "kunark");
    if (!$VELIOUS_ADMIN_ONLY || $client->Admin() >= 100) {
      $eras .= " or ".quest::saylink("velious", 1, "velious");
    }
    plugin::Whisper("Greetings, $name. I am Spirekeeper Aethen, master of the arcane spires. " .
                    "I can transport you to the great wizard spires across Norrath. " .
                    "Choose an era: $eras.");
    
    if (plugin::HasExpeditionPortPass($client) && $client->GetExpedition()) {
        my $exp = $client->GetExpedition();
        my $exp_zone = quest::GetZoneLongName(quest::GetZoneShortName($exp->GetZoneID()));
        plugin::Whisper("I sense you have an active expedition in $exp_zone. I can " . quest::saylink("send me to expedition", 1) . ".");
    }
  }
  elsif ($text =~ /^classic$/i) {
    my $level = $client->GetLevel();
    my $dest = quest::saylink("North Karana", 1).", " .
               quest::saylink("Toxxulia Forest", 1).", ".quest::saylink("Greater Faydark", 1).", " .
               quest::saylink("West Commonlands", 1).", ".quest::saylink("Nektulos Forest", 1).", " .
               quest::saylink("North Ro", 1).", ".quest::saylink("Temple of Solusek Ro", 1).", " .
               quest::saylink("Cazic-Thule", 1).", or ".quest::saylink("West Karana", 1);
    if ($level >= 46) {
      $dest .= ". For the experienced: ".quest::saylink("Plane of Hate", 1)." or ".quest::saylink("Plane of Sky", 1);
    }
    plugin::Whisper("Classic wizard spires: $dest.");
  }
  elsif ($text =~ /^kunark$/i) {
    plugin::Whisper("Kunark wizard spires: ".quest::saylink("Dreadlands Combine", 1).", " .
                    quest::saylink("Skyfire", 1).", or ".quest::saylink("Emerald Jungle", 1)."." );
  }
  elsif ($text =~ /^velious$/i) {
    if ($VELIOUS_ADMIN_ONLY && $client->Admin() < 100) {
      plugin::Whisper("The Velious spires are not yet open to travelers.");
      return;
    }
    plugin::Whisper("Velious wizard spires: ".quest::saylink("Iceclad", 1).", " .
                    quest::saylink("Great Divide", 1).", ".quest::saylink("Wakening Lands", 1).", or " .
                    quest::saylink("Cobalt Scar", 1)."." );
  }
  elsif ($text =~ /^iceclad$/i) {
    if ($VELIOUS_ADMIN_ONLY && $client->Admin() < 100) { return; }
    plugin::Whisper("Transporting you to Iceclad wizard spire...");
    quest::movepc(110, 4925, -630, 113);
  }
  elsif ($text =~ /^great divide$/i) {
    if ($VELIOUS_ADMIN_ONLY && $client->Admin() < 100) { return; }
    plugin::Whisper("Transporting you to Great Divide wizard spire...");
    quest::movepc(118, 3651, -3766, -237);
  }
  elsif ($text =~ /^wakening lands$/i) {
    if ($VELIOUS_ADMIN_ONLY && $client->Admin() < 100) { return; }
    plugin::Whisper("Transporting you to Wakening Lands wizard spire...");
    quest::movepc(119, -3032, -3040, 28);
  }
  elsif ($text =~ /^cobalt scar$/i) {
    if ($VELIOUS_ADMIN_ONLY && $client->Admin() < 100) { return; }
    plugin::Whisper("Transporting you to Cobalt Scar wizard spire...");
    quest::movepc(117, -1634, -1065, 299);
  }
  elsif ($text =~ /^dreadlands combine$/i) {
    plugin::Whisper("Transporting you to the Combine area in Dreadlands...");
    quest::movepc(86, 9664, 3061, 1050, 388);
  }
  elsif ($text =~ /^skyfire$/i) {
    plugin::Whisper("Transporting you to Skyfire Mountains wizard spire...");
    quest::movepc(91, 2725, -3205, -168, 469);
  }
  elsif ($text =~ /^emerald jungle$/i) {
    plugin::Whisper("Transporting you to Emerald Jungle wizard spire...");
    quest::movepc(94, 3516, -1255, -342, 332);
  }
  elsif ($text =~ /north karana/i) {
    plugin::Whisper("Transporting you to North Karana wizard spire...");
    quest::movepc(13, 1209, -3685, -5);
  }
  elsif ($text =~ /toxxulia forest/i) {
    plugin::Whisper("Transporting you to Toxxulia Forest wizard spire...");
    quest::movepc(38, -907, -1510, -36);
  }
  elsif ($text =~ /greater faydark/i) {
    plugin::Whisper("Transporting you to Greater Faydark wizard spire...");
    quest::movepc(54, -441, -2023, 4);
  }
  elsif ($text =~ /west commonlands/i) {
    plugin::Whisper("Transporting you to West Commonlands wizard spire...");
    quest::movepc(21, 1839, -1, -14);
  }
  elsif ($text =~ /nektulos forest/i) {
    plugin::Whisper("Transporting you to Nektulos Forest wizard spire...");
    quest::movepc(25, -715, -57, 42);
  }
  elsif ($text =~ /north ro/i) {
    plugin::Whisper("Transporting you to North Ro wizard spire...");
    quest::movepc(34, 823, 1378, 11);
  }
  elsif ($text =~ /temple of solusek ro/i) {
    plugin::Whisper("Transporting you to the Temple of Solusek Ro...");
    quest::movepc(80, 36, 262, 2.75, 384);
  }
  elsif ($text =~ /cazic-thule/i) {
    plugin::Whisper("Transporting you to Cazic-Thule wizard spire...");
    quest::movepc(48, -466, 253, 23);
  }
  elsif ($text =~ /west karana/i) {
    plugin::Whisper("Transporting you to West Karana wizard spire...");
    quest::movepc(12, -14815, -3569, 36);
  }
  elsif ($text =~ /plane of hate/i) {
    if ($client->GetLevel() >= 46) {
      plugin::Whisper("Transporting you to the Plane of Hate...");
      quest::movepc(186, -393, 656, 4);
    } else {
      plugin::Whisper("You must be at least level 46 to travel to the Plane of Hate.");
    }
  }
  elsif ($text =~ /plane of sky/i) {
    if ($client->GetLevel() >= 46) {
      plugin::Whisper("Transporting you to the Plane of Sky...");
      quest::movepc(71, 539, 1384, -664);
    } else {
      plugin::Whisper("You must be at least level 46 to travel to the Plane of Sky.");
    }
  }
      elsif ($text =~ /send me to expedition/i) {
        if (!plugin::HasExpeditionPortPass($client)) {
            plugin::Whisper("You do not have the Expedition Port Pass.");
            return;
        }
        if (!$client->GetExpedition()) {
            plugin::Whisper("You do not have an active expedition.");
            return;
        }
        my $exp = $client->GetExpedition();
        my $exp_zone = quest::GetZoneLongName(quest::GetZoneShortName($exp->GetZoneID()));
        
        $client->Popup2(
            "Expedition Transport",
            "Transport to your expedition in <c \"#00FF00\">$exp_zone</c>?<br><br>"
            . "Choose how you wish to travel:",
            2001,
            2002,
            2, 0,
            "Just Me", "My Group"
        );
    }
}

sub EVENT_POPUPRESPONSE {
    if ($popupid == 2001) {
        plugin::TeleportToExpeditionFromLobby();
    }
    elsif ($popupid == 2002) {
        plugin::TeleportGroupToExpeditionFromLobby();
    }
}

1;
