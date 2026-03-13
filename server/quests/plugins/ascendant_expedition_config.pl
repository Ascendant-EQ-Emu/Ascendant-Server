# Ascendant EQ - Expedition Configuration
# Defines zone-specific settings for expeditions including mega-boss exclusions
# Author: Straps

use strict;
use warnings;

# Zone configuration hash
# mega_bosses: Array of NPC IDs to depop in respawning expeditions
# zone_version: Zone version to use (default 0)
# default_name: Display name for the zone
my %expedition_zones = (
    'fearplane' => {
        mega_bosses => [72003, 72000, 72004, 72002, 72090],  # Cazic Thule - verify NPC ID
        zone_version => 0,
        default_name => 'Plane of Fear'
    },
    'hateplaneb' => {
        mega_bosses => [186158],  # Innoruuk - verify NPC ID
        zone_version => 0,
        default_name => 'Plane of Hate'
    },
    'permafrost' => {
        mega_bosses => [73057],  # Lady Vox - verify NPC ID
        zone_version => 0,
        default_name => 'Permafrost Keep'
    },
    'soldungb' => {
        mega_bosses => [32040],  # Lord Nagafen - verify NPC ID
        zone_version => 0,
        default_name => "Nagafen's Lair"
    },
    'airplane' => {
        mega_bosses => [],  # No mega-boss exclusions for Plane of Sky
        zone_version => 0,
        default_name => 'Plane of Sky'
    },
    'potimeb' => {
        mega_bosses => [],  # Add Quarm NPC ID if needed
        zone_version => 0,
        default_name => 'Plane of Time'
    },
    'crushbone' => {
        mega_bosses => [],  # No mega-boss exclusions
        zone_version => 0,
        default_name => 'Crushbone'
    },
    'gukbottom' => {
        mega_bosses => [],  # No mega-boss exclusions
        zone_version => 0,
        default_name => 'Lower Guk'
    },
    'citymist' => {
        mega_bosses => [],
        zone_version => 1,
        default_name => 'City of Mist'
    },
    'sebilis' => {
        mega_bosses => [],  # Add Trakanon if needed
        zone_version => 0,
        default_name => 'Old Sebilis'
    },
    'chardok' => {
        mega_bosses => [],  # No mega-boss exclusions
        zone_version => 0,
        default_name => 'Chardok'
    },
    'velketor' => {
        mega_bosses => [],  # No mega-boss exclusions
        zone_version => 0,
        default_name => "Velketor's Labyrinth"
    },
    'kael' => {
        mega_bosses => [],  # Add King Tormax if needed
        zone_version => 0,
        default_name => 'Kael Drakkel'
    },
    'sleeper' => {
        mega_bosses => [],  # Add Kerafyrm if needed
        zone_version => 0,
        default_name => "Sleeper's Tomb"
    },
    'ssratemple' => {
        mega_bosses => [],  # Add Emperor Ssraeshza if needed
        zone_version => 0,
        default_name => 'Ssraeshza Temple'
    },
    'vexthal' => {
        mega_bosses => [],  # No mega-boss exclusions
        zone_version => 0,
        default_name => 'Vex Thal'
    },
    'anguish' => {
        mega_bosses => [],  # Add Overlord Mata Muram if needed
        zone_version => 0,
        default_name => 'Anguish, the Fallen Palace'
    }
);

sub GetExpeditionConfig {
    my $zone_name = shift;
    
    # Return config if exists, otherwise return default
    if (exists $expedition_zones{$zone_name}) {
        return $expedition_zones{$zone_name};
    }
    
    # Default configuration for zones not in the list
    return {
        mega_bosses => [],
        zone_version => 0,
        default_name => quest::GetZoneLongName($zone_name)
    };
}

sub GetMegaBosses {
    my $zone_name = shift;
    
    my $config = GetExpeditionConfig($zone_name);
    return @{$config->{mega_bosses}};
}

sub HasMegaBosses {
    my $zone_name = shift;
    
    my $config = GetExpeditionConfig($zone_name);
    return scalar(@{$config->{mega_bosses}}) > 0;
}

return 1;
