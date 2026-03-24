# Ascendant EQ - Expedition Configuration
# Defines zone-specific settings for expeditions
# Author: Straps

use strict;
use warnings;

# Zone configuration hash
# zone_version: Zone version to use (default 0)
# default_name: Display name for the zone
# entry_override: {x, y, z, h} — custom zone-in point inside the DZ (optional)
# has_raid_tier: 1 if zone offers the "Raid Expedition" option
my %expedition_zones = (
    # ---- Classic ----
    'fearplane' => {
        zone_version => 0,
        default_name => 'Plane of Fear',
        has_raid_tier => 1
    },
    'hateplaneb' => {
        zone_version => 0,
        default_name => 'Plane of Hate',
        has_raid_tier => 1
    },
    'permafrost' => {
        zone_version => 0,
        default_name => 'Permafrost Keep',
        has_raid_tier => 1
    },
    'soldungb' => {
        zone_version => 0,
        default_name => "Nagafen's Lair",
        has_raid_tier => 1
    },
    'airplane' => {
        zone_version => 0,
        default_name => 'Plane of Sky',
        has_raid_tier => 1
    },
    'cazicthule' => {
        zone_version => 0,
        default_name => 'Cazic-Thule',
        has_raid_tier => 1
    },
    'hole' => {
        zone_version => 0,
        default_name => 'The Hole',
        has_raid_tier => 1
    },
    'kedge' => {
        zone_version => 0,
        default_name => 'Kedge Keep',
        has_raid_tier => 1
    },
    'hateplane' => {
        zone_version => 0,
        default_name => 'The Plane of Hate'
    },
    'mischiefplane' => {
        zone_version => 0,
        default_name => 'Plane of Mischief',
        has_raid_tier => 1
    },
    'potimeb' => {
        zone_version => 0,
        default_name => 'Plane of Time'
    },
    'crushbone' => {
        zone_version => 0,
        default_name => 'Crushbone'
    },
    'gukbottom' => {
        zone_version => 0,
        default_name => 'Lower Guk'
    },

    # ---- Kunark ----
    'citymist' => {
        zone_version => 1,
        default_name => 'City of Mist',
        has_raid_tier => 1
    },
    'sebilis' => {
        zone_version => 0,
        default_name => 'Old Sebilis',
        has_raid_tier => 1
    },
    'chardok' => {
        zone_version => 0,
        default_name => 'Chardok',
        has_raid_tier => 1,
        entry_override => { x => 911, y => -104, z => 104, h => 400 }
    },
    'charasis' => {
        zone_version => 0,
        default_name => 'Howling Stones',
        has_raid_tier => 1
    },
    'karnor' => {
        zone_version => 0,
        default_name => "Karnor's Castle",
        has_raid_tier => 1
    },
    'timorous' => {
        zone_version => 0,
        default_name => 'Timorous Deep',
        has_raid_tier => 1
    },
    'skyfire' => {
        zone_version => 0,
        default_name => 'Skyfire Mountains',
        has_raid_tier => 1
    },
    'emeraldjungle' => {
        zone_version => 0,
        default_name => 'Emerald Jungle',
        has_raid_tier => 1
    },
    'veeshan' => {
        zone_version => 0,
        default_name => "Veeshan's Peak",
        has_raid_tier => 1
    },

    # ---- Velious ----
    'iceclad' => {
        zone_version => 0,
        default_name => 'Iceclad Ocean',
        has_raid_tier => 1
    },
    'sirens' => {
        zone_version => 0,
        default_name => 'Sirens Grotto',
        has_raid_tier => 1
    },
    'velketor' => {
        zone_version => 0,
        default_name => "Velketor's Labyrinth",
        has_raid_tier => 1
    },
    'kael' => {
        zone_version => 0,
        default_name => 'Kael Drakkel',
        has_raid_tier => 1
    },
    'sleeper' => {
        zone_version => 0,
        default_name => "Sleeper's Tomb",
        has_raid_tier => 1
    },
    'templeveeshan' => {
        zone_version => 0,
        default_name => 'Temple of Veeshan',
        has_raid_tier => 1
    },
    'necropolis' => {
        zone_version => 0,
        default_name => 'Dragon Necropolis',
        has_raid_tier => 1
    },
    'growthplane' => {
        zone_version => 0,
        default_name => 'Plane of Growth',
        has_raid_tier => 1
    },
    'wakening' => {
        zone_version => 0,
        default_name => 'Wakening Land',
        has_raid_tier => 1
    },
    'skyshrine' => {
        zone_version => 0,
        default_name => 'Skyshrine',
        has_raid_tier => 1
    },
    'thurgadinb' => {
        zone_version => 0,
        default_name => 'Thurgadin',
        has_raid_tier => 1
    },
    'cobaltscar' => {
        zone_version => 0,
        default_name => 'Cobalt Scar',
        has_raid_tier => 1
    },
    'westwastes' => {
        zone_version => 0,
        default_name => 'Western Wastes',
        has_raid_tier => 1
    },

    # ---- Luclin+ ----
    'ssratemple' => {
        zone_version => 0,
        default_name => 'Ssraeshza Temple'
    },
    'vexthal' => {
        zone_version => 0,
        default_name => 'Vex Thal'
    },
    'anguish' => {
        zone_version => 0,
        default_name => 'Anguish, the Fallen Palace'
    },

    # ---- Overland / Outdoor ----
    'dreadlands' => {
        zone_version => 0,
        default_name => 'Dreadlands',
        has_raid_tier => 1,
        entry_override => { x => 5405, y => -841, z => 1251.1, h => 0 }
    },
    'greatdivide' => {
        zone_version => 0,
        default_name => 'Great Divide',
        has_raid_tier => 1,
        entry_override => { x => 138.19, y => -1040.24, z => 21.93, h => 250.75 }
    },
    'eastwastes' => {
        zone_version => 0,
        default_name => 'Eastern Wastes',
        has_raid_tier => 1,
        entry_override => { x => -375.17, y => -2667.32, z => 178.12, h => 140.75 }
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
        zone_version => 0,
        default_name => quest::GetZoneLongName($zone_name)
    };
}

sub HasRaidTier {
    my $zone_name = shift;

    my $config = GetExpeditionConfig($zone_name);
    return ($config->{has_raid_tier} && $config->{has_raid_tier} == 1) ? 1 : 0;
}

return 1;
