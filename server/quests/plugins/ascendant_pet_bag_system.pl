# Ascendant EQ - Pet Bag System
# 8-slot container that automatically equips items to pets when they spawn
# Items are equipped to appropriate slots based on item type
# Author: Straps

package plugin;

use strict;
use warnings;

# Item IDs for pet bags
my $PET_BAG_ITEM_ID        = 93861;  # Original pet bag (6-slot)
my $CASTER_PET_BAG_ITEM_ID = 2828;   # Ascendant Casters Pet Bag (10-slot, Enc/Mag/Wiz/Nec)

sub EquipPetFromBag {
    my $npc = shift;  # The pet NPC
    
    # Make sure this is actually a pet
    return unless $npc->IsPet();
    
    # Get the pet's owner
    my $owner_id = $npc->GetOwnerID();
    return unless $owner_id;
    
    my $entity_list = plugin::val('$entity_list');
    return unless $entity_list;

    my $PET_BAG_HEAL_COOLDOWN_SEC = 600;  # 10 minutes

    
    my $owner = $entity_list->GetClientByID($owner_id);
    unless ($owner) {
        quest::debug("PetBag: Could not find owner for pet");
        return;
    }
    
    quest::debug("PetBag: Checking for pet bag for " . $owner->GetCleanName());
    
    # Find the pet bag in owner's inventory or bank
    my ($pet_bag, $bag_inv_slot) = FindPetBag($owner);
    unless ($pet_bag) {
        quest::debug("PetBag: No pet bag found for " . $owner->GetCleanName());
        return;
    }
    
    quest::debug("PetBag: Found pet bag, checking contents");
    
    my $char_id   = $owner->CharacterID();
    my $pet_eid    = $npc->GetID();
    my $base_key   = "petbag_base:${char_id}_${pet_eid}";
    my $existing_base = quest::get_data($base_key);

    # Clear all existing loot before re-adding fresh from bag
    $npc->ClearItemList();
    quest::debug("PetBag: Cleared all existing items from pet");

    # On re-equip, restore AddItem-affected stats to baseline values.
    # ClearItemList() does NOT revert stat bonuses from previous AddItem() calls,
    # so without this reset, stats stack every time the bag is re-equipped.
    if ($existing_base) {
        my @b = split(',', $existing_base);
        $npc->ModifyNPCStat("max_hp",       $b[0]);
        $npc->ModifyNPCStat("str",           $b[3]);
        $npc->ModifyNPCStat("sta",           $b[4]);
        $npc->ModifyNPCStat("agi",           $b[5]);
        $npc->ModifyNPCStat("dex",           $b[6]);
        $npc->ModifyNPCStat("int",           $b[7]);
        $npc->ModifyNPCStat("wis",           $b[8]);
        $npc->ModifyNPCStat("cha",           $b[9]);
        $npc->ModifyNPCStat("mr",            $b[10]);
        $npc->ModifyNPCStat("fr",            $b[11]);
        $npc->ModifyNPCStat("cr",            $b[12]);
        $npc->ModifyNPCStat("pr",            $b[13]);
        $npc->ModifyNPCStat("dr",            $b[14]);
        $npc->ModifyNPCStat("min_hit",       $b[15]);
        $npc->ModifyNPCStat("max_hit",       $b[16]);
        $npc->ModifyNPCStat("attack_delay",  $b[17] / 100);  # stored as centiseconds, ModifyNPCStat takes raw
        quest::debug("PetBag: Restored all stats to baseline before re-equip");
    }

    my $equipped_count = 0;

    # Snapshot baseline stats on first equip only (before AddItem changes anything)
    my @base_vals = (
        $npc->GetMaxHP(), $npc->GetAC(), $npc->GetATK(),
        $npc->GetSTR(), $npc->GetSTA(), $npc->GetAGI(), $npc->GetDEX(),
        $npc->GetINT(), $npc->GetWIS(), $npc->GetCHA(),
        $npc->GetMR(), $npc->GetFR(), $npc->GetCR(), $npc->GetPR(), $npc->GetDR(),
        $npc->GetMinDMG(), $npc->GetMaxDMG(), $npc->GetAttackDelay()
    );
    unless ($existing_base) {
        quest::set_data($base_key, join(',', @base_vals), 14400);
        quest::debug("PetBag: Stored initial baselines: " . join(',', @base_vals));
    }

    # Pre-equip pet combat stats for DPS gate — always use stored baseline (not current inflated values)
    my $pre_min   = $existing_base ? (split(',', $existing_base))[15] : $base_vals[15];
    my $pre_max   = $existing_base ? (split(',', $existing_base))[16] : $base_vals[16];
    my $pre_delay = $existing_base ? (split(',', $existing_base))[17] : $base_vals[17];  # centiseconds
    my $pre_avg   = ($pre_min + $pre_max) / 2.0;

    # Accumulators for stats that AddItem does NOT apply
    my $ac_bonus       = 0;
    my $atk_bonus      = 0;
    my $spelldmg_bonus = 0;
    my $healamt_bonus  = 0;

    # Track best primary-hand weapon by DPS
    my $best_wpn_dmg   = 0;
    my $best_wpn_min   = 0;
    my $best_wpn_delay = 0;
    my $best_wpn_dps   = 0;

    my $is_charm_pet = (eval { $npc->GetPetType() } // 0) == 3;

    # Procs applied once per pet lifetime via entity variable (auto-cleared on death)
    # Charm pets: procs may persist on NPC after charm break (no RemoveMeleeProc exists)
    my $procs_already_applied = ($npc->GetEntityVariable('petbag_procs_applied') || 0);

    # Loop through each slot in the pet bag (up to 24 — empty slots past bag size are skipped)
    my %proc_counts;  # track how many times we see each proc spell

    for my $bag_slot (0..23) {
        my $item = $pet_bag->GetItem($bag_slot);
        next unless $item;
        
        my $item_id = $item->GetID();
        my $item_name = $item->GetName();
        
        quest::debug("PetBag: Found item in slot $bag_slot: $item_name (ID: $item_id)");
        
        $npc->AddItem($item_id, 1, 1);
        $equipped_count++;

        # Accumulate AC/ATK bonuses (AddItem does NOT apply these to pets)
        $ac_bonus      += ($npc->GetItemStat($item_id, "ac")       || 0);
        $atk_bonus     += ($npc->GetItemStat($item_id, "atk")      || 0);
        my $item_spelldmg = ($npc->GetItemStat($item_id, "spelldmg") || 0);
        my $item_healamt  = ($npc->GetItemStat($item_id, "healamt")  || 0);
        $spelldmg_bonus += $item_spelldmg;
        $healamt_bonus  += $item_healamt;
        if ($item_spelldmg || $item_healamt) {
            quest::debug("PetBag: Item $item_name spelldmg=$item_spelldmg healamt=$item_healamt (running total: sd=$spelldmg_bonus ha=$healamt_bonus)");
        }

        # Accumulate stats from augments on this item
        my $item_abs_slot;
        if ($bag_inv_slot >= 2000) {
            my $bankbags_begin = quest::getinventoryslotid("bankbags.begin");
            $item_abs_slot = $bankbags_begin + ($bag_inv_slot - 2000) * 10 + $bag_slot;
        } else {
            my $generalbags_begin = quest::getinventoryslotid("generalbags.begin");
            $item_abs_slot = $generalbags_begin + ($bag_inv_slot - 23) * 10 + $bag_slot;
        }
        my @aug_sockets = (
            quest::getinventoryslotid("augsocket.begin")..quest::getinventoryslotid("augsocket.end")
        );
        for my $aug_socket (@aug_sockets) {
            my $aug_id = $owner->GetAugmentIDAt($item_abs_slot, $aug_socket);
            next unless $aug_id && $aug_id > 0;
            my $aug_ac = ($npc->GetItemStat($aug_id, "ac")       || 0);
            my $aug_atk = ($npc->GetItemStat($aug_id, "atk")      || 0);
            my $aug_sd = ($npc->GetItemStat($aug_id, "spelldmg") || 0);
            my $aug_ha = ($npc->GetItemStat($aug_id, "healamt")  || 0);
            $ac_bonus       += $aug_ac;
            $atk_bonus      += $aug_atk;
            $spelldmg_bonus += $aug_sd;
            $healamt_bonus  += $aug_ha;
            if ($aug_ac || $aug_atk || $aug_sd || $aug_ha) {
                quest::debug("PetBag: Aug $aug_id on $item_name ac=$aug_ac atk=$aug_atk sd=$aug_sd ha=$aug_ha (total: sd=$spelldmg_bonus ha=$healamt_bonus)");
            }
        }

        # Track best primary-hand weapon by DPS
        my $slots  = $npc->GetItemStat($item_id, "slots")  || 0;
        my $damage = $npc->GetItemStat($item_id, "damage") || 0;
        my $delay  = $npc->GetItemStat($item_id, "delay")  || 0;

        if (($slots & 8192) && $damage > 0 && $delay > 0) {
            my $pet_level = $npc->GetLevel();
            my $dmg_bonus = ($pet_level >= 28) ? 1 + int(($pet_level - 28) / 3) : 0;
            my $wpn_avg   = $damage * 2.0 + $dmg_bonus;  # player-equivalent avg hit
            my $haste_f   = 1 + ($npc->GetHaste() / 100);
            my $wpn_dps   = $wpn_avg / ($delay / $haste_f);
            if ($wpn_dps > $best_wpn_dps) {
                $best_wpn_dps   = $wpn_dps;
                $best_wpn_dmg   = int($damage * 3.0 + $dmg_bonus);  # new max_hit
                $best_wpn_min   = $dmg_bonus;                        # new min_hit
                $best_wpn_delay = $delay;
                quest::debug("PetBag: New best weapon: $item_name wpn_avg=$wpn_avg delay=$delay dps=$wpn_dps");
            }
        }

        # Track procs from weapon-slot items only (primary/secondary)
        if ($slots & (8192 | 16384)) {
            my $proc_id = $npc->GetItemStat($item_id, "proceffect");
            if ($proc_id && $proc_id > 0 && $proc_id != 65535) {
                $proc_counts{$proc_id}++;
            }
        }
        
        quest::debug("PetBag: Equipped $item_name to pet");
    }

    # Register weapon procs — hard cap of 2, applied once per pet lifetime only
    if (!$procs_already_applied) {
        my $proc_limit = 0;
        foreach my $proc_id (sort keys %proc_counts) {
            last if $proc_limit >= 2;
            my $count = $proc_counts{$proc_id};
            my $rate  = 50 * $count;
            $npc->AddMeleeProc($proc_id, $rate);
            $proc_limit++;
            quest::debug("PetBag: Added weapon proc spell=$proc_id rate=$rate (x$count weapons) [$proc_limit/2]");
        }
        $npc->SetEntityVariable('petbag_procs_applied', 1);
        quest::debug("PetBag: Procs applied ($proc_limit total) and entity variable set");
    } else {
        quest::debug("PetBag: Procs already applied this pet lifetime, skipping");
    }
    
    quest::debug("PetBag: Total items equipped: $equipped_count");

    # Apply AC/ATK bonuses via ModifyNPCStat (AddItem does not apply these to pets)
    # Use stored baseline to prevent stacking on repeated equips
    my $base_ac  = $existing_base ? (split(',', $existing_base))[1] : $base_vals[1];
    my $base_atk = $existing_base ? (split(',', $existing_base))[2] : $base_vals[2];

    if ($ac_bonus > 0) {
        my $new_ac = $base_ac + $ac_bonus;
        $npc->ModifyNPCStat("ac", $new_ac);
        quest::debug("PetBag: Applied AC bonus: base=$base_ac +$ac_bonus = $new_ac");
    }
    if ($atk_bonus > 0) {
        my $new_atk = $base_atk + $atk_bonus;
        $npc->ModifyNPCStat("atk", $new_atk);
        quest::debug("PetBag: Applied ATK bonus: base=$base_atk +$atk_bonus = $new_atk");
    }

    # Apply SpellFocusDMG/Heal — flat bonus added to all pet spell damage including procs
    # Hardcoded to 0 in npc.cpp, only settable via SetSpellFocusDMG/Heal()
    my $FOCUS_DMG_MULT  = 1.5;
    my $FOCUS_HEAL_MULT = 1.5;
    if ($spelldmg_bonus > 0) {
        my $focus_dmg = $spelldmg_bonus * $FOCUS_DMG_MULT;
        $npc->SetSpellFocusDMG($focus_dmg);
        quest::debug("PetBag: SetSpellFocusDMG: $spelldmg_bonus*$FOCUS_DMG_MULT = $focus_dmg");
    } else {
        $npc->SetSpellFocusDMG(0);
    }
    if ($healamt_bonus > 0) {
        my $focus_heal = $healamt_bonus * $FOCUS_HEAL_MULT;
        $npc->SetSpellFocusHeal($focus_heal);
        quest::debug("PetBag: SetSpellFocusHeal: $healamt_bonus*$FOCUS_HEAL_MULT = $focus_heal");
    } else {
        $npc->SetSpellFocusHeal(0);
    }

    # Always reset active delay to base first — prevents stale value from prior equip
    my $base_delay_raw = $pre_delay / 100;  # centiseconds -> raw (2800->28)
    quest::set_data("petbag_active_delay:${char_id}_${pet_eid}", $base_delay_raw, 14400);

    if ($best_wpn_dps > 0) {
        my $haste_factor = 1 + ($npc->GetHaste() / 100);
        my $pet_dps = ($base_delay_raw > 0) ? $pre_avg / ($base_delay_raw / $haste_factor) : 0;
        quest::debug("PetBag: pre_avg=$pre_avg base_delay_raw=$base_delay_raw pet_dps=$pet_dps best_wpn_dps=$best_wpn_dps");

        if ($best_wpn_dps > $pet_dps) {
            $npc->ModifyNPCStat("max_hit",      $best_wpn_dmg);
            $npc->ModifyNPCStat("min_hit",      $best_wpn_min);
            $npc->ModifyNPCStat("attack_delay", $best_wpn_delay);
            quest::set_data("petbag_active_delay:${char_id}_${pet_eid}", $best_wpn_delay, 14400);  # override with weapon raw delay
            quest::debug("PetBag: Weapon upgrade: min=$best_wpn_min max=$best_wpn_dmg delay=$best_wpn_delay wpn_dps=$best_wpn_dps pet_dps=$pet_dps");
        } else {
            quest::debug("PetBag: Weapon DPS ($best_wpn_dps) did not beat pet DPS ($pet_dps), keeping base");
        }
    }

    # Heal pet after equipping (cooldown-gated, inline)
    if ($equipped_count > 0) {

        # Only bother if pet is not already full HP
        my $hp_cur = $npc->GetHP();
        my $hp_max = $npc->GetMaxHP();

        if ($hp_max > 0 && $hp_cur < $hp_max) {

            # Per-owner cooldown key (CharacterID-based)
            my $char_id = $owner->CharacterID();
            my $pet_id  = $npc->GetID();   # or $npc->GetNPCTypeID() if you prefer
            my $cd_key  = "petbag_heal_cd:$char_id:$pet_id";


            # If key exists, cooldown is active (set_data auto-expires)
            my $on_cd = quest::get_data($cd_key) ? 1 : 0;

            if (!$on_cd) {
                $npc->SetHP($hp_max);

                # Start cooldown (value doesn't matter, expiry does)
                quest::set_data($cd_key, 1, $PET_BAG_HEAL_COOLDOWN_SEC);

                quest::debug("PetBag: Healed pet to full HP ($hp_max) and started cooldown ($PET_BAG_HEAL_COOLDOWN_SEC sec)");
            } else {
                quest::debug("PetBag: Heal skipped (cooldown active) for " . $owner->GetCleanName());
            }

        } else {
            quest::debug("PetBag: Heal skipped (already full HP)");
        }
    }


    
    # Notify owner if items were equipped
    if ($equipped_count > 0) {
        $owner->Message(18, "Your pet has been equipped with $equipped_count item(s) from your Pet Bag!");
    } else {
        quest::debug("PetBag: No items found in pet bag to equip");
    }
    
    return $equipped_count;
}

sub FindPetBag {
    my $client = shift;

    # Determine which bag IDs to search for, in priority order
    # Enc(11)/Mag(13)/Wiz(14)/Nec(10) get the caster bag first, then fallback to original
    my $class_id = $client->GetClass();
    my @bag_ids;
    if ($class_id == 10 || $class_id == 11 || $class_id == 13 || $class_id == 14) {
        @bag_ids = ($CASTER_PET_BAG_ITEM_ID, $PET_BAG_ITEM_ID);
    } else {
        @bag_ids = ($PET_BAG_ITEM_ID);
    }

    quest::debug("PetBag: Searching for pet bag (IDs: " . join(',', @bag_ids) . ") class=$class_id");

    # Search each bag ID in priority order — first match wins
    foreach my $target_id (@bag_ids) {
        # Search general inventory slots (23-32 = general1-general10)
        for my $slot (23..32) {
            my $item = $client->GetItemAt($slot);
            next unless $item;
            if ($item->GetID() == $target_id) {
                quest::debug("PetBag: Found bag $target_id in inventory slot $slot");
                return ($item, $slot);
            }
        }

        # Search bank slots (2000-2023)
        for my $slot (2000..2023) {
            my $item = $client->GetItemAt($slot);
            next unless $item;
            if ($item->GetID() == $target_id) {
                quest::debug("PetBag: Found bag $target_id in bank slot $slot");
                return ($item, $slot);
            }
        }
    }

    quest::debug("PetBag: Pet bag not found in inventory or bank");
    return (undef, undef);
}

sub ShowPetBagContents {
    my $client = shift;
    
    my ($pet_bag, $bag_inv_slot) = FindPetBag($client);
    
    unless ($pet_bag) {
        $client->Message(13, "You don't have a Pet Bag in your inventory or bank.");
        return;
    }
    
    $client->Message(10, "=== Pet Bag Contents ===");
    
    my $has_items = 0;
    for my $bag_slot (0..23) {
        my $item = $pet_bag->GetItem($bag_slot);
        if ($item) {
            my $item_name = $item->GetName();
            $client->Message(10, "Slot " . ($bag_slot + 1) . ": $item_name");
            $has_items = 1;
        }
    }
    
    unless ($has_items) {
        $client->Message(18, "Your Pet Bag is empty.");
    }
}

sub _delta_str {
    my ($cur, $base) = @_;
    return "" unless defined $base;
    my $diff = $cur - $base;
    return "" if $diff == 0;
    return " <c '#00FF00'>+$diff</c>" if $diff > 0;
    return " <c '#FF4444'>$diff</c>";
}

sub ShowPetStats {
    my ($npc, $client) = @_;

    return unless $npc && $client;

    my $name  = $npc->GetCleanName();
    my $level = $npc->GetLevel();

    # Current stats
    my $hp_cur  = $npc->GetHP();
    my $hp_max  = $npc->GetMaxHP();
    my $hp_pct  = ($hp_max > 0) ? int(($hp_cur / $hp_max) * 100) : 0;
    my $hp_reg  = $npc->GetNPCStat("hp_regen") || 0;
    my $ac      = $npc->GetAC();
    my $atk     = $npc->GetATK();
    my $min_hit = $npc->GetMinDMG();
    my $max_hit = $npc->GetMaxDMG();
    my $delay   = $npc->GetAttackDelay();
    my $haste   = $npc->GetHaste();
    my $acc     = $npc->GetNPCStat("accuracy") || 0;
    my $avoid   = $npc->GetNPCStat("avoidance") || 0;
    my $slowmit = $npc->GetNPCStat("slow_mitigation") || 0;
    my $focus_dmg  = $npc->GetSpellFocusDMG()  || 0;
    my $focus_heal = $npc->GetSpellFocusHeal() || 0;

    my $str = $npc->GetSTR();  my $sta = $npc->GetSTA();
    my $agi = $npc->GetAGI();  my $dex = $npc->GetDEX();
    my $int = $npc->GetINT();  my $wis = $npc->GetWIS();
    my $cha = $npc->GetCHA();

    my $mr = $npc->GetMR();  my $fr = $npc->GetFR();
    my $cr = $npc->GetCR();  my $pr = $npc->GetPR();
    my $dr = $npc->GetDR();

    # Equipped item count
    my @loot = $npc->GetLootList();
    my $item_count = scalar(grep { $_ && $_ > 0 } @loot);

    # Load baselines for delta display — keyed per pet entity to handle charm pets
    my $char_id  = $client->CharacterID();
    my $pet_eid  = $npc->GetID();
    my $base_key = "petbag_base:${char_id}_${pet_eid}";
    my $base_raw = quest::get_data($base_key);
    my @b;
    if ($base_raw) {
        @b = split(',', $base_raw);
    }
    # Order: hp,ac,atk,str,sta,agi,dex,int,wis,cha,mr,fr,cr,pr,dr,min,max,delay,spellscale,healscale

    # GetAttackDelay() returns raw*100 (2800 = raw 28)
    my $delay_raw = $delay / 100;       # raw EQ delay (28)
    my $avg_hit = ($min_hit + $max_hit) / 2;
    # Stored active delay is raw (set during equip)
    my $stored_active_delay = quest::get_data("petbag_active_delay:${char_id}_${pet_eid}");
    my $active_delay_raw = ($stored_active_delay && $stored_active_delay > 0) ? $stored_active_delay : $delay_raw;
    # Haste reduces delay — apply to raw delay, then use raw for DPS (consistent units)
    my $eff_delay_raw = ($haste > 0) ? $active_delay_raw / (1 + $haste / 100) : $active_delay_raw;
    my $est_dps   = ($eff_delay_raw > 0) ? $avg_hit / $eff_delay_raw : 0;

    # Base pet DPS from stored baselines — all raw delay units
    my $base_dps_str   = "N/A";
    my $base_delay_str = "N/A";
    my $base_avg_str   = "N/A";
    my $base_ratio_str = "N/A";
    if (scalar @b >= 18) {
        my $b_min       = $b[15];
        my $b_max       = $b[16];
        my $b_delay_raw = $b[17] / 100;  # GetAttackDelay() -> raw (2800->28)
        my $b_eff_raw   = ($haste > 0) ? $b_delay_raw / (1 + $haste / 100) : $b_delay_raw;
        my $b_avg       = ($b_min + $b_max) / 2;
        my $b_dps       = ($b_eff_raw > 0) ? $b_avg / $b_eff_raw : 0;
        my $b_ratio     = ($b_delay_raw > 0) ? $b_avg / $b_delay_raw : 0;
        $base_delay_str = sprintf("%d", $b_delay_raw);
        $base_dps_str   = sprintf("%.1f", $b_dps);
        $base_avg_str   = sprintf("%.1f", $b_avg);
        $base_ratio_str = sprintf("%.2f", $b_ratio);
    }

    # Best equipped weapon DPS from loot — find highest DPS primary weapon
    my $wpn_dps_str   = "None";
    my $wpn_delay_str = "N/A";
    my $wpn_dmg_str   = "N/A";
    my $wpn_avg_str   = "N/A";
    my $wpn_ratio_str = "N/A";
    my $best_wpn_dps  = 0;
    foreach my $wid (@loot) {
        next unless $wid && $wid > 0;
        my $wslots  = $npc->GetItemStat($wid, "slots")  || 0;
        my $wdamage = $npc->GetItemStat($wid, "damage") || 0;
        my $wdelay  = $npc->GetItemStat($wid, "delay")  || 0;
        if (($wslots & 8192) && $wdamage > 0 && $wdelay > 0) {
            # Mirrors EquipPetFromBag formula exactly
            my $w_dmg_bonus  = ($level >= 28) ? 1 + int(($level - 28) / 3) : 0;
            my $w_avg        = $wdamage * 2.0 + $w_dmg_bonus;  # player-equivalent avg hit
            my $w_haste_f    = 1 + ($haste / 100);
            my $w_eff_delay  = ($w_haste_f > 0) ? $wdelay / $w_haste_f : $wdelay;
            my $w_dps        = ($w_eff_delay > 0) ? $w_avg / $w_eff_delay : 0;
            my $w_ratio      = ($wdelay > 0) ? $w_avg / $wdelay : 0;
            if ($w_dps > $best_wpn_dps) {
                $best_wpn_dps  = $w_dps;
                $wpn_dps_str   = sprintf("%.2f", $w_dps);
                $wpn_delay_str = sprintf("%d", $wdelay);
                $wpn_dmg_str   = "$wdamage" . ($w_dmg_bonus > 0 ? "+$w_dmg_bonus" : "");
                $wpn_avg_str   = sprintf("%.1f", $w_avg);
                $wpn_ratio_str = sprintf("%.2f", $w_ratio);
            }
        }
    }

    # Determine which is in use
    my $wpn_status = "";
    if (scalar @b >= 17) {
        my $base_min = $b[15];
        my $base_max = $b[16];
        if ($min_hit != $base_min || $max_hit != $base_max) {
            $wpn_status = "<c '#00FF00'>Using Weapon</c>";
        } else {
            $wpn_status = "<c '#FF4444'>Using Base</c>";
        }
    }

    my $active_delay_disp = sprintf("%d", $active_delay_raw);
    $avg_hit  = sprintf("%.1f", $avg_hit);
    $est_dps  = sprintf("%.1f", $est_dps);

    my $d_hp  = (scalar @b >= 1)  ? _delta_str($hp_max,  $b[0])  : "";
    my $d_ac  = (scalar @b >= 2)  ? _delta_str($ac,      $b[1])  : "";
    my $d_atk = (scalar @b >= 3)  ? _delta_str($atk,     $b[2])  : "";
    my $d_str = (scalar @b >= 4)  ? _delta_str($str,     $b[3])  : "";
    my $d_sta = (scalar @b >= 5)  ? _delta_str($sta,     $b[4])  : "";
    my $d_agi = (scalar @b >= 6)  ? _delta_str($agi,     $b[5])  : "";
    my $d_dex = (scalar @b >= 7)  ? _delta_str($dex,     $b[6])  : "";
    my $d_int = (scalar @b >= 8)  ? _delta_str($int,     $b[7])  : "";
    my $d_wis = (scalar @b >= 9)  ? _delta_str($wis,     $b[8])  : "";
    my $d_cha = (scalar @b >= 10) ? _delta_str($cha,     $b[9])  : "";
    my $d_mr  = (scalar @b >= 11) ? _delta_str($mr,      $b[10]) : "";
    my $d_fr  = (scalar @b >= 12) ? _delta_str($fr,      $b[11]) : "";
    my $d_cr  = (scalar @b >= 13) ? _delta_str($cr,      $b[12]) : "";
    my $d_pr  = (scalar @b >= 14) ? _delta_str($pr,      $b[13]) : "";
    my $d_dr  = (scalar @b >= 15) ? _delta_str($dr,      $b[14]) : "";
    my $d_min = (scalar @b >= 16) ? _delta_str($min_hit, $b[15]) : "";
    my $d_max = (scalar @b >= 17) ? _delta_str($max_hit, $b[16]) : "";
    my $d_del = (scalar @b >= 18) ? _delta_str($delay,   $b[17]) : "";

    # Build equipped items list with slot labels
    my %slot_names = (
        1 => 'Charm', 2 => 'Ear', 4 => 'Head', 8 => 'Face', 16 => 'Ear',
        32 => 'Neck', 64 => 'Shoulders', 128 => 'Arms', 256 => 'Back',
        512 => 'Wrist', 1024 => 'Wrist', 2048 => 'Range',
        4096 => 'Hands', 8192 => 'Primary', 16384 => 'Secondary',
        32768 => 'Ring', 65536 => 'Ring', 131072 => 'Chest',
        262144 => 'Legs', 524288 => 'Feet', 1048576 => 'Waist',
    );
    my @slot_order = (8192, 16384, 2048, 4, 8, 131072, 64, 128, 4096,
                      262144, 524288, 1048576, 256, 32, 2, 16, 512, 1024,
                      32768, 65536, 1);

    my $equip_lines = "";
    my $proc_lines  = "";
    my %seen_procs;
    my %used_slots;
    my %item_counts;

    # Count how many of each item appear in loot
    foreach my $lid (@loot) {
        next unless $lid && $lid > 0;
        $item_counts{$lid}++;
    }
    my %item_displayed;

    foreach my $lid (@loot) {
        next unless $lid && $lid > 0;
        next if $item_displayed{$lid}++; # show each unique item once, with count

        my $iname = quest::getitemname($lid) || "Unknown";
        my $islots = $npc->GetItemStat($lid, "slots") || 0;

        # Find best slot label
        my $slot_label = "Gear";
        if ($islots > 0) {
            foreach my $bit (@slot_order) {
                if (($islots & $bit) && !$used_slots{$bit}) {
                    $slot_label = $slot_names{$bit} || "Gear";
                    $used_slots{$bit} = 1;
                    last;
                }
            }
        }
        my $cnt = $item_counts{$lid} || 1;
        my $cnt_str = ($cnt > 1) ? " <c '#AAAAAA'>x$cnt</c>" : "";
        $equip_lines .= "<c '#FFAA00'>$slot_label:</c> $iname$cnt_str<br>";

        # Show procs — cap at 2 total (matches AddMeleeProc hard cap)
        if (scalar(keys %seen_procs) < 2) {
            my $proc_id = $npc->GetItemStat($lid, "proceffect");
            if ($proc_id && $proc_id > 0 && $proc_id != 65535 && !$seen_procs{$proc_id}) {
                my $spell_name = quest::getspellname($proc_id) || "Spell $proc_id";
                $proc_lines .= "<c '#FF4444'>- $spell_name</c><br>";
                $seen_procs{$proc_id} = 1;
            }
        }
    }

    $equip_lines = "<c '#888888'>None</c><br>" unless $equip_lines;
    if ($proc_lines) {
        $proc_lines = "<c '#FF8800'><b>Procs</b></c><br>" . $proc_lines;
    } else {
        $proc_lines = "<c '#FF8800'><b>Procs</b></c><br><c '#888888'>None</c><br>";
    }

    my $body = qq{
    <c "#00FFFF"><b>Pet Stats: $name</b></c><br>
    <c "#888888">----------------------------</c><br>
    <c "#888888">Green values show bonus over base pet stats.</c><br>
    <c "#888888">Weapon with highest DPS is used if it beats base.</c><br><br>
    <b>Level:</b> <c "#FFFF00">$level</c><br><br>

    <c "#00FF00"><b>Health</b></c><br>
    <b>HP:</b> $hp_cur / $hp_max - $hp_pct%$d_hp | <b>Regen:</b> $hp_reg<br><br>

    <c "#CCCC00"><b>Attributes</b></c><br>
    <b>STR:</b> $str$d_str  <b>STA:</b> $sta$d_sta  <b>AGI:</b> $agi$d_agi<br>
    <b>DEX:</b> $dex$d_dex  <b>INT:</b> $int$d_int  <b>WIS:</b> $wis$d_wis<br>
    <b>CHA:</b> $cha$d_cha<br><br>

    <c "#FF8800"><b>Combat</b></c><br>
    <b>AC:</b> $ac$d_ac | <b>ATK:</b> $atk$d_atk<br>
    <b>Damage:</b> $min_hit$d_min - $max_hit$d_max | Avg: $avg_hit<br>
    <b>Haste:</b> $haste%<br><br>

    <b>Base Pet:</b> Avg $base_avg_str | Delay $base_delay_str | Ratio $base_ratio_str | DPS $base_dps_str<br>
    <b>Best Weapon:</b> Dmg $wpn_dmg_str | Avg $wpn_avg_str | Delay $wpn_delay_str | Ratio $wpn_ratio_str | DPS $wpn_dps_str<br>
    <b>Active:</b> $wpn_status - Avg $avg_hit | Delay $active_delay_disp | DPS $est_dps<br><br>

    <b>Accuracy:</b> $acc | <b>Avoidance:</b> $avoid | <b>Slow Mit:</b> $slowmit<br><br>

    <c "#DD88FF"><b>Spell Power</b></c><br>
    <b>Focus DMG:</b> +$focus_dmg | <b>Focus Heal:</b> +$focus_heal<br><br>

    <c "#8888FF"><b>Resistances</b></c><br>
    <b>MR:</b> $mr$d_mr | <b>FR:</b> $fr$d_fr | <b>CR:</b> $cr$d_cr<br>
    <b>PR:</b> $pr$d_pr | <b>DR:</b> $dr$d_dr<br><br>

    <c "#CCCC00"><b>Equipment</b></c> - $item_count items<br>
    $equip_lines<br>
    $proc_lines
    };

    quest::popup("Pet Stats: $name", $body, 0, 0, 0);
}

sub ShowPetInventory {
    my ($npc, $client) = @_;
    
    return unless $npc && $client;
    
    my $name = $npc->GetCleanName();
    
    my $content = "
    <c \"#00FFFF\"><b>== Pet Inventory: $name ==</b></c><br>
    <c \"#888888\">----------------------------</c><br><br>
    ";

    my @loot_list = $npc->GetLootList();

    if (@loot_list && scalar(@loot_list) > 0) {
        my %slot_names = (
            1     => 'Charm',      2     => 'Ear (L)',    4     => 'Head',
            8     => 'Face',       16    => 'Ear (R)',    32    => 'Neck',
            64    => 'Shoulders',  128   => 'Arms',       256   => 'Back',
            512   => 'Wrist (L)',  1024  => 'Wrist (R)',  2048  => 'Range',
            4096  => 'Hands',      8192  => 'Primary',    16384 => 'Secondary',
            32768 => 'Finger (L)', 65536 => 'Finger (R)', 131072 => 'Chest',
            262144 => 'Legs',      524288 => 'Feet',      1048576 => 'Waist',
            2097152 => 'Ammo',
        );

        my @slot_order = (8192, 16384, 2048, 4, 8, 131072, 64, 128, 4096, 262144, 524288, 1048576, 256, 32, 2, 16, 512, 1024, 32768, 65536, 1, 2097152);

        my %categorized;
        my %filled_slots;
        my @uncategorized;

        # Use CountItem to detect duplicates in loot list
        foreach my $item_id (@loot_list) {
            next unless $item_id && $item_id > 0;
            my $item_name = quest::getitemname($item_id);
            next unless $item_name;

            my $count = $npc->CountItem($item_id);
            $count = 1 if (!$count || $count < 1);

            my $slots = $npc->GetItemStat($item_id, "slots");
            my $proc_id = $npc->GetItemStat($item_id, "proceffect");

            my $proc_info = "";
            if ($proc_id && $proc_id > 0 && $proc_id != 65535) {
                my $spell_name = quest::getspellname($proc_id);
                $proc_info = $spell_name ? $spell_name : "Spell $proc_id";
            }

            for my $i (1..$count) {
                my $placed = 0;
                if ($slots && $slots > 0) {
                    foreach my $bit (@slot_order) {
                        if (($slots & $bit) && !$filled_slots{$bit}) {
                            push @{$categorized{$bit}}, { name => $item_name, id => $item_id, proc => $proc_info };
                            $filled_slots{$bit} = 1;
                            $placed = 1;
                            last;
                        }
                    }
                }
                push @uncategorized, { name => $item_name, id => $item_id, proc => $proc_info } unless $placed;
            }
        }

        foreach my $bit (@slot_order) {
            next unless exists $categorized{$bit};
            my $slot_label = $slot_names{$bit} || "Unknown";
            foreach my $entry (@{$categorized{$bit}}) {
                $content .= "<c \"#FFAA00\"><b>[$slot_label]</b></c> $entry->{name} <c \"#888888\">(ID: $entry->{id})</c><br>";
                if ($entry->{proc} ne "") {
                    $content .= "  <c \"#FF4444\">Proc: $entry->{proc}</c><br>";
                }
            }
        }

        if (@uncategorized) {
            $content .= "<br><c \"#AAAAAA\"><b>Other Loot:</b></c><br>";
            foreach my $entry (@uncategorized) {
                $content .= "- $entry->{name} <c \"#888888\">(ID: $entry->{id})</c><br>";
            }
        }

        $content .= "<br><c \"#888888\">----------------------------</c><br>";
        if ($npc->HasProcs()) {
            $content .= "<c \"#00FF00\"><b>Proc Status:</b> Active</c><br>";
        } else {
            $content .= "<c \"#FF0000\"><b>Proc Status:</b> NONE (no active procs!)</c><br>";
        }
    } else {
        $content .= "<c \"#FF0000\">No items equipped</c><br>";
    }
    
    plugin::DiaWind($content);
}

return 1;
