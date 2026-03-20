# global_player.pl - Global Player Event Handlers
# Author: Straps
#
# Handles all server-wide player events: zone entry, combat, timers, casting, etc.
# Key systems wired here:
#   - Ascendant Aura reapplication on zone (benedictions)
#   - Mark of Ascendance online timer + combat roll (MoA tokens)
#   - Marked Passage bookmark spell (zone-in/zone-out clearing)
#   - Buff Satchel wand activation (Crystalize Essence)
#   - Alt currency pending check timer

my $bucket_name = "marked_passage_loc";

# Forward declaration
sub ApplyAscendantAuras;

# Known safe Guild Lobby (Zone 146) spawns
my @lobby_locs = (
    [ 0, 315, 2, 0 ],
    [ -262, 414, 2, 0 ],
    [ 257, 411, 2, 0 ],
    [ -2, 515, 2, 0 ],
);

# items: 67704
sub EVENT_ENTERZONE { #message only appears in Cities / Pok and wherever the Wayfarer Camps (LDON) is in.  This message won't appear in the player's home city.
  # Auto-reapply Ascendant Auras on zone
  ApplyAscendantAuras();
  
  # Start alt currency pending check timer
  quest::settimer("altcur_pending_check", 10);
  
  # Start anti-warp system
  #plugin::StartAntiWarp($client);

  
  # Clear Marked Passage bucket if zoning to anywhere other than bazaar (151) or guild lobby (344)
  my $bazaar_zone_id = 151;
  my $guild_lobby_zone_id = 344;
  if ($zoneid != $bazaar_zone_id && $zoneid != $guild_lobby_zone_id) {
    my $marked_passage_key = "marked_passage_" . $client->CharacterID();
    if (quest::get_data($marked_passage_key)) {
      quest::delete_data($marked_passage_key);
    }
  }
  
  ##if($ulevel >= 15 && !defined($qglobals{Wayfarer}) && quest::is_lost_dungeons_of_norrath_enabled()) {
   ## if($client->GetStartZone()!=$zoneid && ($zoneid == 1 || $zoneid == 2 || $zoneid == 3 || $zoneid == 8 || $zoneid == 9 || $zoneid == 10 || $zoneid == 19 || $zoneid == 22 || $zoneid == 23 || $zoneid == 24 || $zoneid == 29 || $zoneid == 30 || $zoneid == 34 || $zoneid == 35 || $zoneid == 40 || $zoneid == 41 || $zoneid == 42 || $zoneid == 45 || $zoneid == 49 || $zoneid == 52 || $zoneid == 54 || $zoneid == 55 || $zoneid == 60 || $zoneid == 61 || $zoneid == 62 || $zoneid == 67 || $zoneid == 68 || $zoneid == 75 || $zoneid == 82 || $zoneid == 106 || $zoneid == 155 || $zoneid == 202 || $zoneid == 382 || $zoneid == 383 || $zoneid == 392 || $zoneid == 393 || $zoneid == 408)) {
	##  $client->Message(15,"A mysterious voice whispers to you, 'If you can feel me in your thoughts, know this -- something is changing in the world and I reckon you should be a part of it. I do not know much, but I do know that in every home city and the wilds there are agents of an organization called the Wayfarers Brotherhood. They are looking for recruits . . . If you can hear this message, you are one of the chosen. Rush to your home city, or search the West Karanas and Rathe Mountains for a contact if you have been exiled from your home for your deeds, and find out more. Adventure awaits you, my friend.'");
	##}
  ##}
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
    elsif ($recipe_id == 9834) {
        my $item_link = quest::varlink(710908);
        quest::we(15, "$name has obtained $item_link! Congratulations, $name!");

        my $first_key = "first_epic_class_" . $client->GetClass();
        unless (quest::get_data($first_key)) {
            quest::set_data($first_key, $name);
            quest::enabletitle(406);
            quest::we(15, "A historic moment! $name is the FIRST " . $client->GetClassName() . " to obtain their class epic on this server! A title of legend has been bestowed!");
        }
    }
}



sub EVENT_SIGNAL {
	# Signal 999 = Apply Ascendant Auras immediately
	if ($signal == 999) {
		ApplyAscendantAuras();
	}
}

sub EVENT_CONNECT {
    # Welcome new players with popup and task assignment
    my $welcome_bucket = "player_welcomed_" . $client->CharacterID();
    if (!quest::get_data($welcome_bucket)) {
        my $welcome_msg = "<c \"#00FFFF\">Welcome to the Server!</c><br><br>" .
            "<c \"#FFFF00\">Key Features:</c><br>" .
            "- <c \"#00FF00\">Classic zones are unlocked</c><br>" .
            "- <c \"#00FF00\">Marked Passage AA</c> sends you to the Guild Lobby hub and returns you when done<br>" .
            "- <c \"#00FF00\">Tiered Items</c> drop with enhanced stats (T1/T2/T3)<br>" .
            "- <c \"#00FF00\">Marks of Ascendance</c> (alt currency) earned from combat and being online<br>" .
            "- Spend Marks on <c \"#FFD700\">server-wide buffs</c>, exp potions, bags, and more<br>" .
            "- <c \"#00FF00\">AA Tomes</c> let you learn AAs from other classes - find books and translate them<br>" .
            "- <c \"#00FF00\">All AAs through Dragons of Norrath</c> available with relaxed level restrictions<br><br>" .
            "<c \"#FF8800\">Visit Chronicler Elodin in the Guild Lobby for more information!</c><br><br>" .
            "Good luck on your adventures!";
        
        quest::popup("Welcome!", $welcome_msg, 0, 0, 0);
        quest::set_data($welcome_bucket, 1);
        
        $client->AssignTask(3);
        $client->UpdateTaskActivity(3, 0, 1);
    }
    # Start MOA online timer (always restart since EQ timers don't persist)
    plugin::MoA_StartOnlineTimer($client);

    
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


sub EVENT_TIMER {

    # Check for pending alt currency grants from MOA granting system
    if ($timer eq "altcur_pending_check") {
        my $char_id = $client->CharacterID();
        
        # Query pending grants for this character
        my $dbh = plugin::LoadMysql();
        if ($dbh) {
            my $sth = $dbh->prepare(
                "SELECT id, currency_id, amount FROM pending_currency_grants WHERE character_id = ? ORDER BY id ASC"
            );
            $sth->execute($char_id);
            
            while (my $row = $sth->fetchrow_hashref()) {
                my $grant_id = $row->{id};
                my $currency_id = $row->{currency_id};
                my $amount = $row->{amount};
                
                # Apply the grant using native client method
                $client->AddAlternateCurrencyValue($currency_id, $amount);
                $client->Message(4, "Thank you for supporting the server!");
                
                # Delete the processed grant
                my $del_sth = $dbh->prepare("DELETE FROM pending_currency_grants WHERE id = ?");
                $del_sth->execute($grant_id);
                $del_sth->finish();
            }
            
            $sth->finish();
        }
        return;
    }
    

	if ($timer eq "moa_online_roll") {
        # MOA online timer - check for award
        plugin::MoA_HandleOnlineTimerFire($client, $zoneid);
    }
    # Handle marked passage goto (to Guild Lobby)
    if ($timer eq "marked_passage_goto") {
        quest::stoptimer("marked_passage_goto");
        
        my $teleport_key = "marked_passage_teleport_" . $client->CharacterID();
        my $teleport_data = quest::get_data($teleport_key);
        
        if ($teleport_data) {
            quest::delete_data($teleport_key);
            
            my @coords = split(/,/, $teleport_data);
            if (scalar(@coords) == 6) {
                my ($zone_id, $instance_id, $x, $y, $z, $heading) = @coords;
                
                # Use MovePCInstance to handle both regular zones and instances
                $client->MovePCInstance($zone_id, $instance_id, $x, $y, $z, $heading);
            }
        }
        return;
    }
    
    # Handle marked passage return (back to marked location)
    if ($timer eq "marked_passage_return") {
        quest::stoptimer("marked_passage_return");
        
        my $teleport_key = "marked_passage_teleport_" . $client->CharacterID();
        my $teleport_data = quest::get_data($teleport_key);
        
        if ($teleport_data) {
            quest::delete_data($teleport_key);
            
            my @coords = split(/,/, $teleport_data);
            if (scalar(@coords) == 6) {
                my ($zone_id, $instance_id, $x, $y, $z, $heading) = @coords;
                
                # Use MovePCInstance to handle both regular zones and instances
                $client->MovePCInstance($zone_id, $instance_id, $x, $y, $z, $heading);
            }
        }
        return;
    }
    # Handle anti-warp timers
    elsif (plugin::HandleAntiWarpTimer($client, $timer)) {
        return;
    }
}

use strict;
use warnings;

our (
    $client,
    $text,
    $status,
    $zoneid,

    # spell-related
    $spell_id,
    $caster_id,
    $tics_remaining,
    $caster_level,
    $buff_slot,

    # EXP events
    $exp,
    $aa_exp,

    # popup
    $popupid,
    # death-related
    # death complete exports
    $killed_x,
    $killed_y,
    $killed_z,
    $killed_h,
    $killed_corpse_id,
    $killer_id,
    $killer_damage,
    $killer_spell,
    $killer_skill,
    $killed_entity_id,
    $combat_start_time,
    $combat_end_time,
    $damage_received,
    $healing_received,
    $killed_merc_id,
    $killed_npc_id,
    $killer,
);


sub _get_dbh {
  return plugin::LoadMysql() if defined &plugin::LoadMysql;
  return undef;
}

sub EVENT_SPELL_FADE {
    # Exported variables: $spell_id, $caster_id, $tics_remaining, $caster_level, $buff_slot
    
    # Check if faded spell is one of our Ascendant Auras
    my %aura_spells = (
        25543 => 1,
        25544 => 1,
        25545 => 1,
        25546 => 1,
    );
    
    if (exists $aura_spells{$spell_id}) {
        # Reuse the same recalibration logic
        ApplyAscendantAuras();
    }
}



sub EVENT_SAY {
    

    if ($text =~ /^#myaacredits$/i) {
        plugin::ShowAllAACredits($client);
    }
    

  ############################
  # Player command: #setaa
  ############################
  if ($text =~ /^#setaa/i) {

    my $current = $client->GetAAEXPPercentage();

    # No argument: show help + current value
    if ($text =~ /^#setaa\s*$/i) {
      $client->Message(15,
        "Usage: #setaa <0-100>\n" .
        "This sets how much experience is diverted to AA.\n" .
        "Your current AA percentage is: $current%."
      );
      return;
    }

    # Parse numeric argument
    if ($text =~ /^#setaa\s+(\d{1,3})$/i) {
      my $value = $1;

      if ($value < 0 || $value > 100) {
        $client->Message(13, "AA percentage must be between 0 and 100.");
        return;
      }

      $client->SetAAEXPPercentage($value);
      $client->Message(15, "Your AA experience has been set to $value%.");
      return;
    }

    # Bad syntax fallback
    $client->Message(13, "Invalid usage. Example: #setaa 50");
    return;
  }

#############################################
  # GM command: #expdump [start] [end]
  # Prints raw XP required per level using
  #   $client->GetEXPForLevel($level)
  #############################################
  if ($text =~ /^#expdump(?:\s+(\d{1,3}))?(?:\s+(\d{1,3}))?$/i && $status >= 200) {

    my $start = defined $1 ? int($1) : 1;
    my $end   = defined $2 ? int($2) : 60;

    # clamp/sanity
    $start = 1   if $start < 1;
    $end   = 125 if $end > 125;   # adjust if you run higher level caps
    ($start, $end) = ($end, $start) if $start > $end;

    $client->Message(15, "=== RAW EXP REQUIRED PER LEVEL (GetEXPForLevel) ===");
    $client->Message(15, "Range: $start -> $end");

    for (my $lvl = $start; $lvl <= $end; $lvl++) {
      my $raw = $client->GetEXPForLevel($lvl);
      $client->Message(15, sprintf("Level %3d -> %3d : %u raw XP", $lvl, $lvl + 1, $raw));
    }

    $client->Message(15, "=== END EXP DUMP ===");
    return;
  }


  #############################################
  # GM command: #testtier (unchanged behavior)
  #############################################
  if ($text =~ /^#testtier$/i && $status >= 200) {

    my $target = $client->GetTarget();

    unless ($target && $target->IsNPC()) {
      $client->Message(15, "You must target an NPC to use this command.");
      return;
    }

    my $npc = $target->CastToNPC();
    my $loottable_id = $npc->GetLoottableID();

    if ($loottable_id == 0) {
      $client->Message(15, "This NPC has no loot table.");
      return;
    }

    my $dbh = _get_dbh();
    unless ($dbh) {
      $client->Message(13, "Error: DB handle unavailable.");
      return;
    }

    my $sql = q{
      SELECT
        lde.item_id AS base_item_id,
        i.Name AS item_name,
        MAX(CASE WHEN itm.tier_code = 1 THEN itm.variant_item_id END) AS t1,
        MAX(CASE WHEN itm.tier_code = 2 THEN itm.variant_item_id END) AS t2,
        MAX(CASE WHEN itm.tier_code = 3 THEN itm.variant_item_id END) AS t3
      FROM loottable_entries lte
      JOIN lootdrop_entries lde
        ON lte.lootdrop_id = lde.lootdrop_id
      JOIN items i
        ON i.id = lde.item_id
      JOIN item_tier_map itm
        ON itm.base_item_id = lde.item_id
      WHERE lte.loottable_id = ?
        AND lde.item_id > 0
      GROUP BY lde.item_id, i.Name
      LIMIT 20
    };

    my $sth = $dbh->prepare($sql);
    $sth->execute($loottable_id);

    $client->Message(15, "=== Tier Loot Test ===");
    $client->Message(15, "NPC: " . $npc->GetCleanName() . " (ID: " . $npc->GetNPCTypeID() . ")");
    $client->Message(15, "Loottable: $loottable_id");
    $client->Message(15, "Items with tier variants (showing up to 20):");

    my $found = 0;
    while (my $r = $sth->fetchrow_hashref()) {
      my @tiers;
      push @tiers, "T1=$r->{t1}" if $r->{t1};
      push @tiers, "T2=$r->{t2}" if $r->{t2};
      push @tiers, "T3=$r->{t3}" if $r->{t3};
      next unless @tiers;

      $found++;
      $client->Message(15, " - [$r->{base_item_id}] $r->{item_name} :: " . join(", ", @tiers));
    }

    $sth->finish();

    if (!$found) {
      $client->Message(13, "No tier-variant items found on this NPC's loottable.");
      $client->Message(13, "This NPC will not drop tier items.");
    } else {
      $client->Message(10, "Found $found items with tier variants!");
      $client->Message(10, "Kill this NPC to test tier drops (20% T1, 2% T2, 1.33% T3)");
    }

    return;
  }
  
}


sub ApplyAscendantAuras {
    return unless $client;
    return unless $client->Connected();
    return if $client->GetHP() <= 0;
    return if $client->IsLD();

    my $now = time();
    my $max_chunk_seconds = 4 * 3600; # 4 hours in seconds

    my %auras = (
        ascendant_aura_speed_expires   => 25543,
        ascendant_aura_healing_expires => 25544,
        ascendant_aura_thought_expires => 25545,
        ascendant_aura_haste_expires   => 25546,
    );

    my $applied = 0;
    
    foreach my $bucket (keys %auras) {
        my $spell = $auras{$bucket};
        my $expire = quest::get_data($bucket);
        
        next unless $expire; # No bucket, skip
        
        my $remaining = $expire - $now;
        
        if ($remaining <= 0) {
            # Expired - remove bucket and fade buff
            quest::delete_data($bucket);
            $client->BuffFadeBySpellID($spell);
            next;
        }
        
        # Apply the full remaining duration
        my $ticks = int($remaining / 6);
        
        # Remove existing buff and reapply with full remaining duration
        $client->BuffFadeBySpellID($spell);
        $client->ApplySpell($spell, $ticks);
        $applied++;
    }
    
    if ($applied > 0) {
        $client->Message(15, "Applied $applied Ascendant Aura(s).");
    }
}

sub EVENT_TASK_COMPLETE {
    our $task_id;
    our $activity_id;
    our $donecount;

    if ($task_id == 3) {
        $client->Message(15,
            "Welcome to Ascendant! Use this coin and your Marked Passage AA to go back and buy your spells if needed. " .
            "Venture forth - grow, gear up, and ascend!"
        );

        quest::ding();

        # Grant 3 spendable AA points
        $client->AddAAPoints(3);
        $client->Message(15,"Granted 3 AA points for Task 3 completion.");
    }
}

sub EVENT_DISCOVER_ITEM {
    our $client;
    our $itemid;

    return unless defined $itemid;
    return unless $itemid > 300000;

    my $item_link = quest::varlink($itemid);
    my $player    = $client->GetCleanName();

    quest::we(
        18,
        "$player has discovered $item_link!"
    );
}

sub EVENT_DEATH {
    my $charid      = $client->CharacterID();

    my $death_key = "leaderboard_deaths_${charid}";
    my $deaths = int(quest::get_data($death_key) || 0) + 1;
    quest::set_data($death_key, $deaths);

    my $x           = $client->GetX();
    my $y           = $client->GetY();
    my $z           = $client->GetZ() + 1;
    my $h           = $client->GetHeading();
    my $instance_id = $client->GetInstanceID() || 0;
 
    quest::debug("divine_recall DEATH_COMPLETE: zone=$zoneid instance=$instance_id x=$x y=$y z=$z h=$h");
 
    my $loc = $zoneid . "," . $x . "," . $y . "," . $z . "," . $h . "," . $instance_id;
    quest::set_data("divine_recall_loc_" . $charid, $loc, 1800);
    quest::debug("divine_recall stored: " . $loc);
}

sub EVENT_DISCONNECT {
  #plugin::StopAntiWarp($client);

  quest::stoptimer("moa_online_roll");
}


sub EVENT_CAST {
    # Handle legitimate movement spells
    plugin::HandleMovementSpell($client, $spell_id);

    # Ascendant Buff Satchel - wand click (spell 17782)
    if ($spell_id == plugin::GetSatchelClaspSpellID()) {
        plugin::ApplyBuffsFromSatchel($client);
    }

    # Crystalize Essence - forge a buff scroll (spells 26716-26722)
    if (plugin::IsCrystalizeSpell($spell_id)) {
        plugin::CrystalizeEssence($client, $spell_id);
    }
}


sub EVENT_EXP_GAIN {
    # MOA combat award - roll for Mark on kill
    plugin::MoA_TryCombatRoll($client, $zoneid);
    


    TryLoreAABonus(
        client => $client,
        amount => $exp
    );
}

sub EVENT_AA_EXP_GAIN {
    # MOA combat award - roll for Mark on kill
    plugin::MoA_TryCombatRoll($client, $zoneid);
    #quest::debug("eventexp");
    TryLoreAABonus(
        client => $client,
        amount => $aa_exp
    );
}


sub TryLoreAABonus {
    my (%args) = @_;
 
    my $client = $args{client};
    my $amount = $args{amount};
 
    return unless $client;
    return if $client->IsLD();
    
 
    my $level = $client->GetLevel();
 
    # 5-minute cooldown between bonus AA awards
    my $cd_key = "lore_aa_bonus_cd_" . $client->CharacterID();
    my $now = time();
    if (my $last = quest::get_data($cd_key)) {
        my $remaining = 300 - ($now - $last);
        if ($remaining > 0) {
            #quest::debug("Lore AA: On cooldown ($remaining seconds remaining)");
            return;
        }
    }
 
 
     # Level-based proc chance (per eligible XP gain event)
    my $proc_chance;
    if    ($level < 10) { $proc_chance = 1; }  # 0.25% (1 in 400 kills)
    elsif ($level < 20) { $proc_chance = 1; }  # 0.33% (1 in 300 kills)
    elsif ($level < 30) { $proc_chance = 1; }  # 0.44% (1 in 225 kills)
    elsif ($level < 40) { $proc_chance = 1; }  # 0.57% (1 in 175 kills)
    elsif ($level <= 50){ $proc_chance = 1; }  # 0.67% (1 in 150 kills)
    else                { $proc_chance = 1; }  # 0.67% (1 in 150 kills)
 
 
    #quest::debug("Lore AA: Rolling for bonus (Level $level, $proc_chance% chance, XP: $amount)");
 
    # Roll for bonus AA (convert percentage to decimal for rand())
    my $roll = rand(100);
    if ($roll >= $proc_chance) {
        #quest::debug("Lore AA: Roll failed ($roll >= $proc_chance)");
        return;
    }
 
    # Award 1 AA (80% chance) or 2 AA (20% chance)
    my $aa_roll = rand(100);
    my $aa = ($aa_roll < 20) ? 2 : 1;
 
    #quest::debug("Lore AA: SUCCESS! Awarding $aa AA point(s) (AA roll: $aa_roll)");
 
    $client->AddAAPoints($aa);
    quest::set_data($cd_key, $now);
 
    # Flavor messages
    my @messages = (
        "You gain a moment of insight and feel your understanding deepen.",
        "Experience sharpens your instincts.",
        "Your recent experiences begin to come together.",
        "You reflect and feel more capable.",
        "Hard-earned experience reveals new possibilities.",
    );
 
    $client->Message(18, $messages[ int(rand(@messages)) ]);
    $client->Message(
        10,
        "You gain $aa bonus Alternate Advancement point" .
        ($aa > 1 ? "s" : "") . "!"
    );
}

sub EVENT_LEVEL_UP {
    our ($ulevel, $name);
    if ($ulevel == 60) {
        my $first_key = "first_level60_class_" . $client->GetClass();
        unless (quest::get_data($first_key)) {
            quest::set_data($first_key, $name);
            quest::we(15, "SERVER FIRST! " . $name . " is the FIRST " . $client->GetClassName() . " to reach level 60 on this server!");
        }
    }
}


sub EVENT_POPUPRESPONSE {
    if ($popupid == 3001) {
        my $charid = $client->CharacterID();

        my $pending_key = "divine_recall_pending_" . $charid;
        unless (quest::get_data($pending_key)) {
            $client->Message(13, "Divine Recall request has expired.");
            return;
        }

        my $loc = quest::get_data("divine_recall_loc_" . $charid);
        unless ($loc) {
            $client->Message(13, "No death location found.");
            return;
        }

        quest::delete_data($pending_key);

        my ($zone_id, $x, $y, $z, $heading, $instance_id) = split(/,/, $loc);
        $instance_id ||= 0;
        if ($instance_id > 0) {
            quest::MovePCInstance($zone_id, $instance_id, $x, $y, $z, $heading);
        } else {
            quest::movepc($zone_id, $x, $y, $z, $heading);
        }
    }
}

1;
