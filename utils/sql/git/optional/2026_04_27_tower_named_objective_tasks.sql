-- =============================================================================
-- Tower of Infinity: Named Objective Tasks (one per NPC, 25 total)
-- Task IDs 990075-990099
-- =============================================================================
-- Blackburrow:  990075=Lord Elgnub, 990076=Mannan, 990077=Master Brewer,
--               990078=Socho Darkpaw, 990079=Tranixx Darkpaw
-- Crushbone:    990080=Emperor Crush, 990081=Ambassador D'Vinn,
--               990082=Lord Darish, 990083=The Prophet, 990084=Retlon Brenclog
-- Befallen:     990085=Gynok Moltor, 990086=Priest Amiaz,
--               990087=Wraps McGee, 990088=Zeek, 990089=The Thaumaturgist
-- Najena:       990090=Drelzna, 990091=Najena, 990092=Rathyl,
--               990093=The Widowmistress, 990094=Tentacle Terror
-- Soldunga:     990095=Lord Gimblox, 990096=Solusek Goblin King,
--               990097=Singe, 990098=Kindle, 990099=Lynada the Exiled
-- =============================================================================

INSERT INTO tasks (
  id, type, duration, duration_code,
  title, description, reward_text, reward_id_list,
  cash_reward, exp_reward, reward_method, reward_points, reward_point_type,
  min_level, max_level, level_spread,
  min_players, max_players,
  repeatable, faction_reward, completion_emote,
  replay_timer_group, replay_timer_seconds, request_timer_group, request_timer_seconds,
  dz_template_id, lock_activity_id, faction_amount, enabled
) VALUES
  (990075, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990076, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990077, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990078, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990079, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990080, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990081, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990082, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990083, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990084, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990085, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990086, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990087, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990088, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990089, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990090, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990091, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990092, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990093, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990094, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990095, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990096, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990097, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990098, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1),
  (990099, 2, 0, 0, 'Tower of Infinity: Objective Hunt', 'Defeat the named target in your Tower floor.', 'Tower progression and rewards are granted by floor completion.', NULL, 0, 0, 0, 0, 0, 1, 255, 0, 1, 72, 1, 0, 'The Tower objective has been completed.', 0, 0, 0, 0, 0, -1, 0, 1)
ON DUPLICATE KEY UPDATE
  type = VALUES(type), duration = VALUES(duration), duration_code = VALUES(duration_code),
  title = VALUES(title), description = VALUES(description), reward_text = VALUES(reward_text),
  reward_id_list = VALUES(reward_id_list), cash_reward = VALUES(cash_reward),
  exp_reward = VALUES(exp_reward), reward_method = VALUES(reward_method),
  reward_points = VALUES(reward_points), reward_point_type = VALUES(reward_point_type),
  min_level = VALUES(min_level), max_level = VALUES(max_level), level_spread = VALUES(level_spread),
  min_players = VALUES(min_players), max_players = VALUES(max_players),
  repeatable = VALUES(repeatable), faction_reward = VALUES(faction_reward),
  completion_emote = VALUES(completion_emote), replay_timer_group = VALUES(replay_timer_group),
  replay_timer_seconds = VALUES(replay_timer_seconds), request_timer_group = VALUES(request_timer_group),
  request_timer_seconds = VALUES(request_timer_seconds), dz_template_id = VALUES(dz_template_id),
  lock_activity_id = VALUES(lock_activity_id), faction_amount = VALUES(faction_amount),
  enabled = VALUES(enabled);

-- -----------------------------------------------------------------------------
-- task_activities: one activity row per task, zone-specific
-- -----------------------------------------------------------------------------

INSERT INTO task_activities (
  taskid, activityid, req_activity_id, step, activitytype,
  target_name, goalmethod, goalcount, description_override,
  npc_match_list, item_id_list, item_list,
  dz_switch_id, min_x, min_y, min_z, max_x, max_y, max_z,
  skill_list, spell_list, zones, zone_version, optional, list_group
) VALUES
  -- Blackburrow
  (990075, 0, -1, 1, 2, 'Lord Elgnub',              1, 1, 'Defeat Lord Elgnub in your Tower floor.',              '17029', NULL, '', 0, 0,0,0,0,0,0, '-1','0','blackburrow',-1, 0, 0),
  (990076, 0, -1, 1, 2, 'Mannan of the Sabertooth', 1, 1, 'Defeat Mannan of the Sabertooth in your Tower floor.', '17050', NULL, '', 0, 0,0,0,0,0,0, '-1','0','blackburrow',-1, 0, 0),
  (990077, 0, -1, 1, 2, 'Master Brewer',            1, 1, 'Defeat Master Brewer in your Tower floor.',            '17049', NULL, '', 0, 0,0,0,0,0,0, '-1','0','blackburrow',-1, 0, 0),
  (990078, 0, -1, 1, 2, 'Socho Darkpaw',            1, 1, 'Defeat Socho Darkpaw in your Tower floor.',            '17048', NULL, '', 0, 0,0,0,0,0,0, '-1','0','blackburrow',-1, 0, 0),
  (990079, 0, -1, 1, 2, 'Tranixx Darkpaw',          1, 1, 'Defeat Tranixx Darkpaw in your Tower floor.',          '17051', NULL, '', 0, 0,0,0,0,0,0, '-1','0','blackburrow',-1, 0, 0),
  -- Crushbone
  (990080, 0, -1, 1, 2, 'Emperor Crush',     1, 1, 'Defeat Emperor Crush in your Tower floor.',     '58032', NULL, '', 0, 0,0,0,0,0,0, '-1','0','crushbone',-1, 0, 0),
  (990081, 0, -1, 1, 2, 'Ambassador D''Vinn',1, 1, 'Defeat Ambassador D''Vinn in your Tower floor.','58059', NULL, '', 0, 0,0,0,0,0,0, '-1','0','crushbone',-1, 0, 0),
  (990082, 0, -1, 1, 2, 'Lord Darish',       1, 1, 'Defeat Lord Darish in your Tower floor.',       '58028', NULL, '', 0, 0,0,0,0,0,0, '-1','0','crushbone',-1, 0, 0),
  (990083, 0, -1, 1, 2, 'The Prophet',       1, 1, 'Defeat The Prophet in your Tower floor.',       '58031', NULL, '', 0, 0,0,0,0,0,0, '-1','0','crushbone',-1, 0, 0),
  (990084, 0, -1, 1, 2, 'Retlon Brenclog',   1, 1, 'Defeat Retlon Brenclog in your Tower floor.',   '58017', NULL, '', 0, 0,0,0,0,0,0, '-1','0','crushbone',-1, 0, 0),
  -- Befallen
  (990085, 0, -1, 1, 2, 'Gynok Moltor',      1, 1, 'Defeat Gynok Moltor in your Tower floor.',      '36103', NULL, '', 0, 0,0,0,0,0,0, '-1','0','befallen',-1, 0, 0),
  (990086, 0, -1, 1, 2, 'Priest Amiaz',      1, 1, 'Defeat Priest Amiaz in your Tower floor.',      '36095', NULL, '', 0, 0,0,0,0,0,0, '-1','0','befallen',-1, 0, 0),
  (990087, 0, -1, 1, 2, 'Wraps McGee',       1, 1, 'Defeat Wraps McGee in your Tower floor.',       '36098', NULL, '', 0, 0,0,0,0,0,0, '-1','0','befallen',-1, 0, 0),
  (990088, 0, -1, 1, 2, 'Zeek',              1, 1, 'Defeat Zeek in your Tower floor.',              '36055', NULL, '', 0, 0,0,0,0,0,0, '-1','0','befallen',-1, 0, 0),
  (990089, 0, -1, 1, 2, 'The Thaumaturgist', 1, 1, 'Defeat The Thaumaturgist in your Tower floor.', '36097', NULL, '', 0, 0,0,0,0,0,0, '-1','0','befallen',-1, 0, 0),
  -- Najena
  (990090, 0, -1, 1, 2, 'Drelzna',           1, 1, 'Defeat Drelzna in your Tower floor.',           '44094', NULL, '', 0, 0,0,0,0,0,0, '-1','0','najena',-1, 0, 0),
  (990091, 0, -1, 1, 2, 'Najena',            1, 1, 'Defeat Najena in your Tower floor.',            '44100', NULL, '', 0, 0,0,0,0,0,0, '-1','0','najena',-1, 0, 0),
  (990092, 0, -1, 1, 2, 'Rathyl',            1, 1, 'Defeat Rathyl in your Tower floor.',            '44024', NULL, '', 0, 0,0,0,0,0,0, '-1','0','najena',-1, 0, 0),
  (990093, 0, -1, 1, 2, 'The Widowmistress', 1, 1, 'Defeat The Widowmistress in your Tower floor.', '44103', NULL, '', 0, 0,0,0,0,0,0, '-1','0','najena',-1, 0, 0),
  (990094, 0, -1, 1, 2, 'Tentacle Terror',   1, 1, 'Defeat Tentacle Terror in your Tower floor.',   '44061', NULL, '', 0, 0,0,0,0,0,0, '-1','0','najena',-1, 0, 0),
  -- Soldunga
  (990095, 0, -1, 1, 2, 'Lord Gimblox',          1, 1, 'Defeat Lord Gimblox in your Tower floor.',          '31126', NULL, '', 0, 0,0,0,0,0,0, '-1','0','soldunga',-1, 0, 0),
  (990096, 0, -1, 1, 2, 'Solusek Goblin King',   1, 1, 'Defeat Solusek Goblin King in your Tower floor.',   '31128', NULL, '', 0, 0,0,0,0,0,0, '-1','0','soldunga',-1, 0, 0),
  (990097, 0, -1, 1, 2, 'Singe',                 1, 1, 'Defeat Singe in your Tower floor.',                 '31127', NULL, '', 0, 0,0,0,0,0,0, '-1','0','soldunga',-1, 0, 0),
  (990098, 0, -1, 1, 2, 'Kindle',                1, 1, 'Defeat Kindle in your Tower floor.',                '31136', NULL, '', 0, 0,0,0,0,0,0, '-1','0','soldunga',-1, 0, 0),
  (990099, 0, -1, 1, 2, 'Lynada the Exiled',     1, 1, 'Defeat Lynada the Exiled in your Tower floor.',     '31001', NULL, '', 0, 0,0,0,0,0,0, '-1','0','soldunga',-1, 0, 0)
ON DUPLICATE KEY UPDATE
  req_activity_id = VALUES(req_activity_id), step = VALUES(step), activitytype = VALUES(activitytype),
  target_name = VALUES(target_name), goalmethod = VALUES(goalmethod), goalcount = VALUES(goalcount),
  description_override = VALUES(description_override), npc_match_list = VALUES(npc_match_list),
  item_id_list = VALUES(item_id_list), item_list = VALUES(item_list),
  dz_switch_id = VALUES(dz_switch_id), min_x = VALUES(min_x), min_y = VALUES(min_y),
  min_z = VALUES(min_z), max_x = VALUES(max_x), max_y = VALUES(max_y), max_z = VALUES(max_z),
  skill_list = VALUES(skill_list), spell_list = VALUES(spell_list), zones = VALUES(zones),
  zone_version = VALUES(zone_version), optional = VALUES(optional), list_group = VALUES(list_group);
