# Ascendant Anti-Warp System

## Overview
Prevents player teleport hacking by validating movement speed. Active for all players except GMs (admin level 80+).

## How It Works
- Tracks player position every second
- Validates movement distance against speed threshold (150 units/second)
- Allows normal running, SoW, mounts, and legitimate teleport spells
- Warps players back if they move too far too fast
- Automatically exempts GMs from checks

## Installation

### 1. Copy Plugin File
Copy `ascendant_antiwarp.pl` to your server's `plugins` directory:
```
quests/plugins/ascendant_antiwarp.pl
```

### 2. Integrate with global_player.pl
Add the code from `global_player_antiwarp_snippet.pl` to your `quests/global/global_player.pl` file.

Add to each event:
- **EVENT_ENTERZONE**: `plugin::StartAntiWarp($client);`
- **EVENT_DISCONNECT**: `plugin::StopAntiWarp($client);`
- **EVENT_DEATH**: `plugin::StopAntiWarp($client);`
- **EVENT_TIMER**: `if (plugin::HandleAntiWarpTimer($client, $timer)) { return; }`
- **EVENT_CAST**: `plugin::HandleMovementSpell($client, $spell_id);`

### 3. Reload Quests
```
#reloadquest
```

## Configuration

### Speed Threshold
Default: 150 units per second (line 89 in ascendant_antiwarp.pl)
```perl
my $threshold = 150 * $dt;
```
Adjust if needed:
- Lower = stricter (may catch legitimate fast movement)
- Higher = more lenient (may miss some hacks)

### GM Exemption Level
Default: Admin level 80+ (line 25 in ascendant_antiwarp.pl)
```perl
return if $client->Admin() >= 80;
```

### Check Frequency
Default: Every 1 second (line 39 in ascendant_antiwarp.pl)
```perl
quest::settimer("antiwarp_$id", 1);
```
- 0.5 seconds = tighter detection, more server load
- 2 seconds = looser detection, less server load

### Legitimate Movement Spells
Whitelist is in lines 13-18. Add your custom teleport spell IDs:
```perl
my %move_spells = map { $_ => 1 } qw(
    3 388 391 392 770 994 1342 1344 1345 1346 1524 1733 1771 1773 
    2080 2168 2169 2170 2171 2172 2213 2245 2246 2738 2764 4589 
    5880 7207 8557 9079 10042 11268 12786 13143 14823 16531 18928 
    25555 27644 27651 28632 31597 32139 32161 32397 32503 34662 
    38058 38063 40456 40457 44014
    # Add your custom spell IDs here
);
```

## Features

### Automatic Activation
- Starts when player enters any zone
- No opt-in required
- GMs automatically exempted

### Legitimate Movement Handling
- 6-second grace period after casting teleport spells
- Both caster and target are flagged
- Includes summons, resurrections, teleports, etc.

### Clean Punishment
- Simply warps player back to last valid position
- No kicks, no bans, no messages
- Silent operation

### Proper Cleanup
- Stops on disconnect
- Stops on death
- Clears all timers and memory

## Testing

### Test as Non-GM
1. Log in with a regular player account
2. Try to use a teleport hack
3. Should be warped back to previous position

### Test as GM
1. Log in with GM account (level 80+)
2. Use `/zone` or other GM commands
3. Should work normally without interference

### Test Legitimate Movement
1. Cast Gate, Translocate, or other teleport spells
2. Should work normally
3. Get resurrected or summoned
4. Should work normally

## Troubleshooting

### Players Getting Warped Back Legitimately
- Check if their spell ID is in the whitelist
- Consider increasing the speed threshold
- Check for lag causing position desync

### Hackers Not Being Caught
- Decrease check frequency (1 second → 0.5 seconds)
- Decrease speed threshold (150 → 100)
- Check server logs for timer issues

### Performance Issues
- Increase check frequency (1 second → 2 seconds)
- Only affects online players, scales well

## Technical Details

### Position Tracking
- Stores X, Y, Z coordinates and timestamp
- Only checks 2D distance (X/Y)
- Z-axis ignored (allows falling, levitation)

### Memory Management
- Hash cleared on disconnect/death
- No memory leaks
- Scales with concurrent players

### Timer Management
- One timer per player for position checking
- One timer per player for temporary allowance
- All timers cleaned up properly

## Credits
Adapted from Profusion server's anti-warp system.
Modified for Ascendant EQ by Straps.
