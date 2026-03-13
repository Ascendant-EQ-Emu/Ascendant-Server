# Ascendant EQ - Anti-Warp System
# Prevents player teleport hacking by validating movement speed
# Active for all players except GMs
# Author: Straps (adapted from Profusion)

use strict;
use warnings;

# Position tracking hash: charid => { x, y, z, time }
my %antiwarp_pos = ();

# Whitelist of legitimate teleport/movement spell IDs
my %move_spells = map { $_ => 1 } qw(
    3 388 391 392 770 994 1331 1342 1344 1345 1346 1524 1733 1771 1773 
    2080 2168 2169 2170 2171 2172 2213 2245 2246 2282 2738 2764 4589 
    5880 7207 8557 9079 10042 11268 12786 13143 14823 16531 18928 
    25555 27644 27651 28632 31597 32139 32161 32397 32503 34662 
    38058 38063 40456 40457 44014
);

# Zones where Anti-Warp is disabled
my %antiwarp_exempt_zones = map { $_ => 1 } qw(
    151     # Bazaar
    344     # Guild Lobby
    345     # Guild Hall
    71      # Airplane
    290     # Nexus
    202     # Plane of Knowledge
    61      # Felwithea Felwithe
    62      # Felwitheb Felwithe
    1       # qeynos South Qeynos
    2       # qeynos2 North Qeynos
    72      # fearplane Plane of Fear
    186     # hateplaneb The Plane of Hate
    105     # charasis Howling Stones
    75      # paineel Paineel
);


sub StartAntiWarp {
    my $client = shift;
    
        # Exempt high-status accounts (GMs)
    if ($client->Admin() > 150) {

        # Only message once
        unless ($client->GetEntityVariable("antiwarp_gm_notice")) {
            $client->Message(15, "Anti-Warp unloading (GM detected).");
            $client->SetEntityVariable("antiwarp_gm_notice", 1);
        }

        return;
    }
    
    # Exempt specific zones
    my $zone_id = $client->GetZoneID();
    return if $antiwarp_exempt_zones{$zone_id};

    
    # Skip if already running
    my $id = $client->CharacterID();
    return if $client->GetEntityVariable("antiwarp");
    
    # Initialize position tracking
    $antiwarp_pos{$id} = {
        x => $client->GetX(),
        y => $client->GetY(),
        z => $client->GetZ(),
        time => time
    };
    
    $client->SetEntityVariable("antiwarp", 1);
    quest::settimer("antiwarp_$id", 1);  # Check every 1 second
}

sub StopAntiWarp {
    my $client = shift;
    my $id = $client->CharacterID();
    
    $client->DeleteEntityVariable("antiwarp");
    $client->DeleteEntityVariable("antiwarp_allow");
    quest::stoptimer("antiwarp_$id");
    quest::stoptimer("antiwarp_allow_$id");
    delete $antiwarp_pos{$id};
}

sub AllowAntiWarpMovement {
    my ($client, $seconds) = @_;
    $seconds ||= 6;
    
    my $id = $client->CharacterID();
    $client->SetEntityVariable("antiwarp_allow", 1);
    quest::settimer("antiwarp_allow_$id", $seconds);
}

sub CheckAntiWarp {
    my $client = shift;
    my $id = $client->CharacterID();
    my $pos = $antiwarp_pos{$id};
    
    return unless $pos;
    
    my $x = $client->GetX();
    my $y = $client->GetY();
    my $z = $client->GetZ();
    my $time = time;
    
    # If movement is temporarily allowed, just update position
    if ($client->GetEntityVariable("antiwarp_allow")) {
        $antiwarp_pos{$id} = { x => $x, y => $y, z => $z, time => $time };
        return;
    }
    
    # Calculate 2D distance moved
    my $dx = $x - $pos->{x};
    my $dy = $y - $pos->{y};
    my $dist = sqrt($dx**2 + $dy**2);
    my $dt = $time - $pos->{time} || 1;
    
    # Threshold: 150 units per second (allows SoW, mounts, etc.)
    my $threshold = 150 * $dt;
    
    # If moved too far too fast, warp back
    if ($dist > $threshold) {
        $client->MovePCInstance(
            $client->GetZoneID(), 
            $client->GetInstanceID(), 
            $pos->{x}, 
            $pos->{y}, 
            $pos->{z}, 
            $client->GetHeading()
        );
        return;
    }
    
    # Update baseline position for next check
    $antiwarp_pos{$id} = { x => $x, y => $y, z => $z, time => $time };
}

sub HandleAntiWarpTimer {
    my ($client, $timer) = @_;
    my $id = $client->CharacterID();
    
    # Handle temporary movement allowance expiration
    if ($timer eq "antiwarp_allow_$id") {
        $client->DeleteEntityVariable("antiwarp_allow");
        quest::stoptimer($timer);
        return 1;
    }
    
    # Handle position checking
    if ($timer eq "antiwarp_$id") {
        plugin::CheckAntiWarp($client);
        return 1;
    }
    
    return 0;
}

sub HandleMovementSpell {
    my ($client, $spell_id) = @_;
    
    # Check if this is a legitimate movement spell
    if (exists $move_spells{$spell_id}) {
        # Allow movement for caster
        plugin::AllowAntiWarpMovement($client, 6);
        
        # Allow movement for target (summon/rez target)
        my $target = $client->GetTarget();
        if ($target && $target->IsClient()) {
            plugin::AllowAntiWarpMovement($target->CastToClient(), 6);
        }
    }
}

return 1;
