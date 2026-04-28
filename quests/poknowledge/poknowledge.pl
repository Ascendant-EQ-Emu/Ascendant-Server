#!/usr/bin/perl
# Plane of Knowledge Book-to-Book Travel Network
# Global player event handler for inter-portal travel system
# Converts hardcoded PoK book destinations to dynamic inter-book network with interactive menu
# Date: 2026-04-25

# Destination zone data - fetched from database
my %destinations = ();

sub load_destinations {
    my $player_expansion = shift || 0;
    
    # Hardcoded destination list with zone_id and safe coordinates
    # These come from the return portal books in each zone
    %destinations = (
        'arena' => { zone_id => 33, x => -84.56, y => 402.27, z => 3.75, heading => 193 },
        'butcher' => { zone_id => 50, x => 226.84, y => 279.44, z => -23.63, heading => 229 },
        'crescent' => { zone_id => 137, x => -68.32, y => 209.98, z => 7.85, heading => 164 },
        'everfrost' => { zone_id => 29, x => 169.46, y => -1124.79, z => -100.31, heading => 30 },
        'feerrott' => { zone_id => 25, x => -380, y => -425, z => 20, heading => 0 },
        'feerrott2' => { zone_id => 153, x => -380, y => -425, z => 20, heading => 0 },
        'fieldofbone' => { zone_id => 87, x => -166, y => 96, z => -23, heading => 0 },
        'firiona' => { zone_id => 34, x => 236.86, y => 264.72, z => 0, heading => 191 },
        'freeportwest' => { zone_id => 9, x => 28.18, y => -283.52, z => 3.75, heading => 233 },
        'freportw' => { zone_id => 9, x => 28.18, y => -283.52, z => 3.75, heading => 233 },
        'gfaydark' => { zone_id => 104, x => 395.63, y => -94.66, z => 3.75, heading => 78 },
        'greatdivide' => { zone_id => 120, x => -233, y => -1169, z => 240, heading => 0 },
        'guildlobby' => { zone_id => 330, x => -40.72, y => 0.04, z => -95.06, heading => 128 },
        'gunthak' => { zone_id => 182, x => -1220, y => -1160, z => 107, heading => 0 },
        'innothule' => { zone_id => 32, x => 152.8, y => 261.14, z => 3.75, heading => 168 },
        'innothuleb' => { zone_id => 194, x => 152.8, y => 261.14, z => 3.75, heading => 168 },
        'misty' => { zone_id => 110, x => -265.21, y => 8.95, z => 3.75, heading => 183 },
        'mistythicket' => { zone_id => 110, x => -265.21, y => 8.95, z => 3.75, heading => 183 },
        'nektulos' => { zone_id => 27, x => 244.23, y => 379.6, z => 3.75, heading => 152 },
        'nexus' => { zone_id => 327, x => 0.04, y => 0.04, z => 3.75, heading => 0 },
        'overthere' => { zone_id => 79, x => -1328.79, y => 396.67, z => -57.5, heading => 129 },
        'potranquility' => { zone_id => 201, x => 1.19, y => -5.26, z => 3.75, heading => 0 },
        'qeynos2' => { zone_id => 8, x => -380.11, y => 28.42, z => 3.75, heading => 136 },
        'rathemtn' => { zone_id => 53, x => 108.13, y => 384.78, z => 3.75, heading => 183 },
        'shadeweaver' => { zone_id => 218, x => -500, y => 300, z => 3.75, heading => 0 },
        'shadowrest' => { zone_id => 228, x => 0, y => 0, z => 0, heading => 0 },
        'steamfont' => { zone_id => 24, x => 462.24, y => -316.41, z => 3.75, heading => 142 },
        'steamfontmts' => { zone_id => 24, x => 462.24, y => -316.41, z => 3.75, heading => 142 },
        'tox' => { zone_id => 102, x => 400, y => 1450, z => 450, heading => 0 },
        'toxxulia' => { zone_id => 102, x => 400, y => 1450, z => 450, heading => 0 },
        'weddingchapel' => { zone_id => 289, x => 81.81, y => -1.1, z => 3.75, heading => 30 },
        'weddingchapeldark' => { zone_id => 290, x => 81.81, y => -1.1, z => 3.75, heading => 30 },
    );
}

sub EVENT_CLICKDOOR {
    my $client = shift;
    
    # Only handle PoK zone clicks
    return 0 if (quest::zone() ne "poknowledge");
    
    # Load destinations
    load_destinations($client->GetExpansion());
    
    # Show menu
    show_travel_menu($client);
    
    # Prevent default door behavior
    return 1;
}

sub show_travel_menu {
    my $client = shift;
    my $expansion = $client->GetExpansion();
    
    my $menu = "<c \"#00FF00\">Book of Travel Destinations</c>\n\n";
    my $count = 1;
    
    foreach my $zone (sort keys %destinations) {
        my $entry = $destinations{$zone};
        $menu .= plugin::saylink(ucfirst($zone), "poktravel $zone") . "\n";
    }
    
    # Store destination data in player quest variable
    foreach my $zone (keys %destinations) {
        my $entry = $destinations{$zone};
        quest::setglobal("pokdest_$zone",
            $entry->{zone_id} . "|" .
            $entry->{x} . "|" .
            $entry->{y} . "|" .
            $entry->{z} . "|" .
            $entry->{heading},
            0);
    }
    
    $client->Message(315, $menu);
}

sub EVENT_SAY {
    my $client = shift;
    my $text = shift;
    
    # Handle travel selection
    if ($text =~ /^poktravel\s+(\w+)/i) {
        my $zone = lc($1);
        
        # Check if zone is valid
        if (!exists($destinations{$zone})) {
            $client->Message(13, "That destination is not available!");
            return 1;
        }
        
        my $entry = $destinations{$zone};
        
        $client->Message(315, "Traveling to " . ucfirst($zone) . "...");
        $client->MovePC($entry->{zone_id}, $entry->{x}, $entry->{y}, $entry->{z}, $entry->{heading});
        
        return 1;
    }
    
    return 0;
}
