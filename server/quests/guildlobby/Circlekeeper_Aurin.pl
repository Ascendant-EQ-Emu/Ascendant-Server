# Circlekeeper Aurin - Druid Ring Teleporter (Guild Lobby)
# Author: Straps
#
# Teleports players to druid ring locations across Classic and Kunark zones.
# Also offers expedition teleport if the player has an Expedition Port Pass.

# Set to 1 to restrict Velious ports to GMs only, 0 for all players
my $VELIOUS_ADMIN_ONLY = 0;

sub EVENT_SAY {
  if ($text =~ /hail/i) {
    my $eras = quest::saylink("classic", 1, "classic")." or ".quest::saylink("kunark", 1, "kunark");
    if (!$VELIOUS_ADMIN_ONLY || $client->Admin() >= 100) {
      $eras .= " or ".quest::saylink("velious", 1, "velious");
    }
    plugin::Whisper("Greetings, $name. I am Circlekeeper Aurin, guardian of the ancient druid rings. " .
                    "I can guide you to the sacred circles across Norrath. " .
                    "Choose an era: $eras.");
                    if (plugin::HasExpeditionPortPass($client) && $client->GetExpedition()) {
                    my $exp = $client->GetExpedition();
                    my $exp_zone = quest::GetZoneLongName(quest::GetZoneShortName($exp->GetZoneID()));
                    plugin::Whisper("I sense you have an active expedition in $exp_zone. I can " . quest::saylink("send me to expedition", 1) . ".");
                }

  }
  elsif ($text =~ /^classic$/i) {
    plugin::Whisper("Classic druid rings: ".quest::saylink("North Karana", 1).", " .
                    quest::saylink("Toxxulia Forest", 1).", ".quest::saylink("Butcherblock", 1).", " .
                    quest::saylink("Surefall Glade", 1).", ".quest::saylink("West Commonlands", 1).", " .
                    quest::saylink("Lavastorm", 1).", ".quest::saylink("Steamfont", 1).", " .
                    quest::saylink("South Ro", 1).", ".quest::saylink("Feerrott", 1).", " .
                    quest::saylink("Misty Thicket", 1).", ".quest::saylink("Sharvahl", 1).", or " .
                    quest::saylink("Arena", 1).".") ;  
  }
  elsif ($text =~ /^kunark$/i) {
    plugin::Whisper("Kunark druid rings: ".quest::saylink("Dreadlands", 1).", " .
                    quest::saylink("Emerald Jungle", 1).", or ".quest::saylink("Skyfire", 1)."." );
  }
  elsif ($text =~ /^velious$/i) {
    if ($VELIOUS_ADMIN_ONLY && $client->Admin() < 100) {
      plugin::Whisper("The Velious circles are not yet open to travelers.");
      return;
    }
    plugin::Whisper("Velious druid rings: ".quest::saylink("Iceclad", 1).", " .
                    quest::saylink("Great Divide", 1).", ".quest::saylink("Wakening Lands", 1).", or " .
                    quest::saylink("Cobalt Scar", 1)."." );
  }
  elsif ($text =~ /^iceclad$/i) {
    if ($VELIOUS_ADMIN_ONLY && $client->Admin() < 100) { return; }
    plugin::Whisper("Transporting you to Iceclad druid ring...");
    quest::movepc(110, 4925, -630, 113);
  }
  elsif ($text =~ /^great divide$/i) {
    if ($VELIOUS_ADMIN_ONLY && $client->Admin() < 100) { return; }
    plugin::Whisper("Transporting you to Great Divide druid ring...");
    quest::movepc(118, 3651, -3766, -237);
  }
  elsif ($text =~ /^wakening lands$/i) {
    if ($VELIOUS_ADMIN_ONLY && $client->Admin() < 100) { return; }
    plugin::Whisper("Transporting you to Wakening Lands druid ring...");
    quest::movepc(119, -3032, -3040, 28);
  }
  elsif ($text =~ /^cobalt scar$/i) {
    if ($VELIOUS_ADMIN_ONLY && $client->Admin() < 100) { return; }
    plugin::Whisper("Transporting you to Cobalt Scar druid ring...");
    quest::movepc(117, -1634, -1065, 299);
  }
  elsif ($text =~ /^dreadlands$/i) {
    plugin::Whisper("Transporting you to Dreadlands druid ring...");
    quest::movepc(86, 7689, 2494, 1047, 319);
  }
  elsif ($text =~ /^emerald jungle$/i) {
    plugin::Whisper("Transporting you to Emerald Jungle druid ring...");
    quest::movepc(94, 3494, -3056, -340, 393);
  }
  elsif ($text =~ /^skyfire$/i) {
    plugin::Whisper("Transporting you to Skyfire Mountains druid ring...");
    quest::movepc(91, 2726, -3217, -168, 500);
  }
  elsif ($text =~ /north karana/i) {
    plugin::Whisper("Transporting you to North Karana druid ring...");
    quest::movepc(13, -1494, -2706, -4);
  }
  elsif ($text =~ /toxxulia forest/i) {
    plugin::Whisper("Transporting you to Toxxulia Forest druid ring...");
    quest::movepc(38, -340, 1047, -54);
  }
  elsif ($text =~ /butcherblock/i) {
    plugin::Whisper("Transporting you to Butcherblock Mountains druid ring...");
    quest::movepc(68, 1984, -2135, 3);
  }
  elsif ($text =~ /surefall glade/i) {
    plugin::Whisper("Transporting you to Surefall Glade druid ring...");
    quest::movepc(3, -391, -209, 9);
  }
  elsif ($text =~ /west commonlands/i) {
    plugin::Whisper("Transporting you to West Commonlands druid ring...");
    quest::movepc(21, 1592, 678, -41);
  }
  elsif ($text =~ /lavastorm/i) {
    plugin::Whisper("Transporting you to Lavastorm Mountains druid ring...");
    quest::movepc(27, 1367, 965, 126);
  }
  elsif ($text =~ /steamfont/i) {
    plugin::Whisper("Transporting you to Steamfont Mountains druid ring...");
    quest::movepc(56, 1680, -1726, -108);
  }
  elsif ($text =~ /south ro/i) {
    plugin::Whisper("Transporting you to South Ro druid ring...");
    quest::movepc(35, 345, -2101, -19);
  }
  elsif ($text =~ /feerrott/i) {
    plugin::Whisper("Transporting you to Feerrott druid ring...");
    quest::movepc(47, -1885, 367, 16);
  }
  elsif ($text =~ /misty thicket/i) {
    plugin::Whisper("Transporting you to Misty Thicket druid ring...");
    quest::movepc(33, -1854, -492, 124);
  }
  elsif ($text =~ /arena/i) {
    plugin::Whisper("Transporting you to the Arena...");
    quest::movepc(77, -28.10, -916.62, 50.54);
  }
    elsif ($text =~ /sharvahl/i) {
    plugin::Whisper("Transporting you to Sharvahl druid ring...");
    quest::movepc(155, 82.38, -1235, -189);
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
            2001,   # Just Me
            2002,   # My Group
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
