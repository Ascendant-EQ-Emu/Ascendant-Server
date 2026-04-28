-- =============================================================================
-- 2026_04_27_tower_of_infinity_system.sql
--
-- Tower of Infinity package:
--   1) Adds Bazaar NPC 990230 (Archivist Kaelis) and spawn.
--   2) Adds 50 Epic-only Tower augment tiers (IDs 610100-610149).
--   3) Ensures Epic 1.0 weapons have an AugType 30 slot for Tower augments.
--
-- Notes:
--   - Quest logic uses client bucket key: toi_highest_completed
--   - Augment stat bonus formula by completed level is handled in Lua:
--       bonus = floor((completed_level - 1) / 10) + 1
-- =============================================================================

USE peq;

-- -----------------------------------------------------------------------------
-- 1) Archivist Kaelis in Bazaar (new NPC + spawn)
-- -----------------------------------------------------------------------------
INSERT INTO npc_types (
  id, name, lastname, level, race, class, bodytype, gender,
  hp, mana, size, texture, helmtexture,
  STR, STA, DEX, AGI, _INT, WIS, CHA,
  MR, CR, DR, FR, PR,
  runspeed, walkspeed,
  loottable_id, merchant_id, npc_spells_id,
  aggroradius, assistradius, see_invis, see_invis_undead,
  special_abilities
) VALUES (
  990230, 'Archivist_Kaelis', 'Tower of Infinity', 70, 1, 12, 1, 0,
  350000, 350000, 6.0, 0, 0,
  255, 255, 255, 255, 255, 255, 255,
  255, 255, 255, 255, 255,
  0, 0,
  0, 0, 0,
  0, 0, 1, 1,
  ''
)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  lastname = VALUES(lastname),
  level = VALUES(level),
  race = VALUES(race),
  class = VALUES(class),
  bodytype = VALUES(bodytype),
  gender = VALUES(gender),
  hp = VALUES(hp),
  mana = VALUES(mana),
  size = VALUES(size),
  texture = VALUES(texture),
  helmtexture = VALUES(helmtexture),
  STR = VALUES(STR),
  STA = VALUES(STA),
  DEX = VALUES(DEX),
  AGI = VALUES(AGI),
  _INT = VALUES(_INT),
  WIS = VALUES(WIS),
  CHA = VALUES(CHA),
  MR = VALUES(MR),
  CR = VALUES(CR),
  DR = VALUES(DR),
  FR = VALUES(FR),
  PR = VALUES(PR),
  runspeed = VALUES(runspeed),
  walkspeed = VALUES(walkspeed),
  loottable_id = VALUES(loottable_id),
  merchant_id = VALUES(merchant_id),
  npc_spells_id = VALUES(npc_spells_id),
  aggroradius = VALUES(aggroradius),
  assistradius = VALUES(assistradius),
  see_invis = VALUES(see_invis),
  see_invis_undead = VALUES(see_invis_undead),
  special_abilities = VALUES(special_abilities);

INSERT INTO spawngroup (
  id, name, spawn_limit, dist, max_x, min_x, max_y, min_y,
  delay, mindelay, despawn, despawn_timer, wp_spawns
) VALUES (
  990230, 'BazaarArchivistKaelis', 1, 0, 0, 0, 0, 0,
  0, 0, 0, 100, 0
)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  spawn_limit = VALUES(spawn_limit),
  dist = VALUES(dist),
  max_x = VALUES(max_x),
  min_x = VALUES(min_x),
  max_y = VALUES(max_y),
  min_y = VALUES(min_y),
  delay = VALUES(delay),
  mindelay = VALUES(mindelay),
  despawn = VALUES(despawn),
  despawn_timer = VALUES(despawn_timer),
  wp_spawns = VALUES(wp_spawns);

INSERT INTO spawnentry (
  spawngroupID, npcID, chance, condition_value_filter, min_time, max_time
) VALUES (
  990230, 990230, 100, 1, 0, 0
)
ON DUPLICATE KEY UPDATE
  npcID = VALUES(npcID),
  chance = VALUES(chance),
  condition_value_filter = VALUES(condition_value_filter),
  min_time = VALUES(min_time),
  max_time = VALUES(max_time);

INSERT INTO spawn2 (
  id, spawngroupID, zone, version, x, y, z, heading, respawntime, variance, pathgrid
) VALUES (
  990230, 990230, 'bazaar', 0, -240.000000, -837.000000, 3.750000, 160, 600, 0, 0
)
ON DUPLICATE KEY UPDATE
  spawngroupID = VALUES(spawngroupID),
  zone = VALUES(zone),
  version = VALUES(version),
  x = VALUES(x),
  y = VALUES(y),
  z = VALUES(z),
  heading = VALUES(heading),
  respawntime = VALUES(respawntime),
  variance = VALUES(variance),
  pathgrid = VALUES(pathgrid);

-- -----------------------------------------------------------------------------
-- 2) Tower objective boss NPC templates (random mission targets)
-- -----------------------------------------------------------------------------
INSERT INTO npc_types (
  id, name, lastname, level, race, class, bodytype, gender,
  hp, mana, size, texture, helmtexture,
  STR, STA, DEX, AGI, _INT, WIS, CHA,
  MR, CR, DR, FR, PR,
  runspeed, walkspeed,
  loottable_id, merchant_id, npc_spells_id,
  aggroradius, assistradius, see_invis, see_invis_undead,
  special_abilities
) VALUES (
  990231, 'a_tower_echo', 'Objective of Infinity', 70, 240, 1, 1, 2,
  450000, 0, 8.0, 0, 0,
  255, 255, 255, 255, 255, 255, 255,
  255, 255, 255, 255, 255,
  1.2, 0,
  0, 0, 0,
  65, 0, 1, 1,
  ''
)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  lastname = VALUES(lastname),
  level = VALUES(level),
  race = VALUES(race),
  class = VALUES(class),
  bodytype = VALUES(bodytype),
  gender = VALUES(gender),
  hp = VALUES(hp),
  mana = VALUES(mana),
  size = VALUES(size),
  texture = VALUES(texture),
  helmtexture = VALUES(helmtexture),
  STR = VALUES(STR),
  STA = VALUES(STA),
  DEX = VALUES(DEX),
  AGI = VALUES(AGI),
  _INT = VALUES(_INT),
  WIS = VALUES(WIS),
  CHA = VALUES(CHA),
  MR = VALUES(MR),
  CR = VALUES(CR),
  DR = VALUES(DR),
  FR = VALUES(FR),
  PR = VALUES(PR),
  runspeed = VALUES(runspeed),
  walkspeed = VALUES(walkspeed),
  loottable_id = VALUES(loottable_id),
  merchant_id = VALUES(merchant_id),
  npc_spells_id = VALUES(npc_spells_id),
  aggroradius = VALUES(aggroradius),
  assistradius = VALUES(assistradius),
  see_invis = VALUES(see_invis),
  see_invis_undead = VALUES(see_invis_undead),
  special_abilities = VALUES(special_abilities);

INSERT INTO npc_types (
  id, name, lastname, level, race, class, bodytype, gender,
  hp, mana, size, texture, helmtexture,
  STR, STA, DEX, AGI, _INT, WIS, CHA,
  MR, CR, DR, FR, PR,
  runspeed, walkspeed,
  loottable_id, merchant_id, npc_spells_id,
  aggroradius, assistradius, see_invis, see_invis_undead,
  special_abilities
) VALUES
  (990232, 'a_tower_echo_of_shadow', 'Objective of Infinity', 70, 240, 1, 1, 2, 450000, 0, 8.0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1.2, 0, 0, 0, 0, 65, 0, 1, 1, ''),
  (990233, 'a_tower_echo_of_frost', 'Objective of Infinity', 70, 240, 1, 1, 2, 450000, 0, 8.0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1.2, 0, 0, 0, 0, 65, 0, 1, 1, ''),
  (990234, 'a_tower_echo_of_embers', 'Objective of Infinity', 70, 240, 1, 1, 2, 450000, 0, 8.0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1.2, 0, 0, 0, 0, 65, 0, 1, 1, ''),
  (990235, 'a_tower_echo_of_rot', 'Objective of Infinity', 70, 240, 1, 1, 2, 450000, 0, 8.0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1.2, 0, 0, 0, 0, 65, 0, 1, 1, '')
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  lastname = VALUES(lastname),
  level = VALUES(level),
  race = VALUES(race),
  class = VALUES(class),
  bodytype = VALUES(bodytype),
  gender = VALUES(gender),
  hp = VALUES(hp),
  mana = VALUES(mana),
  size = VALUES(size),
  texture = VALUES(texture),
  helmtexture = VALUES(helmtexture),
  STR = VALUES(STR),
  STA = VALUES(STA),
  DEX = VALUES(DEX),
  AGI = VALUES(AGI),
  _INT = VALUES(_INT),
  WIS = VALUES(WIS),
  CHA = VALUES(CHA),
  MR = VALUES(MR),
  CR = VALUES(CR),
  DR = VALUES(DR),
  FR = VALUES(FR),
  PR = VALUES(PR),
  runspeed = VALUES(runspeed),
  walkspeed = VALUES(walkspeed),
  loottable_id = VALUES(loottable_id),
  merchant_id = VALUES(merchant_id),
  npc_spells_id = VALUES(npc_spells_id),
  aggroradius = VALUES(aggroradius),
  assistradius = VALUES(assistradius),
  see_invis = VALUES(see_invis),
  see_invis_undead = VALUES(see_invis_undead),
  special_abilities = VALUES(special_abilities);

-- -----------------------------------------------------------------------------
-- 3) Tower Epic augment tiers (shared loregroup, epic-only aug type)
-- -----------------------------------------------------------------------------

INSERT INTO items (
  id,
  Name,
  lore,
  comment,
  itemclass,
  itemtype,
  icon,
  idfile,
  magic,
  nodrop,
  norent,
  stackable,
  stacksize,
  classes,
  races,
  slots,
  augtype,
  augrestrict,
  loregroup,
  astr,
  asta,
  aagi,
  adex,
  aint,
  awis,
  acha,
  questitemflag,
  price,
  sellrate,
  weight
)
SELECT
  610100 + seq.n AS id,
  CONCAT('Infinite Epic Augmentation Tier ', seq.n + 1) AS Name,
  'Epic Augmentation of the Infinite' AS lore,
  CONCAT('Tower of Infinity epic augment tier ', seq.n + 1) AS comment,
  0 AS itemclass,
  54 AS itemtype,
  646 AS icon,
  'IT63' AS idfile,
  1 AS magic,
  0 AS nodrop,
  1 AS norent,
  0 AS stackable,
  1 AS stacksize,
  65535 AS classes,
  65535 AS races,
  0 AS slots,
  536870912 AS augtype,
  2 AS augrestrict,
  610999 AS loregroup,
  seq.n + 1 AS astr,
  seq.n + 1 AS asta,
  seq.n + 1 AS aagi,
  seq.n + 1 AS adex,
  seq.n + 1 AS aint,
  seq.n + 1 AS awis,
  seq.n + 1 AS acha,
  0 AS questitemflag,
  0 AS price,
  0 AS sellrate,
  0 AS weight
FROM (
  SELECT ones.n + (tens.n * 10) AS n
  FROM (
    SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
  ) ones
  CROSS JOIN (
    SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  ) tens
) seq
ON DUPLICATE KEY UPDATE
  Name = VALUES(Name),
  lore = VALUES(lore),
  comment = VALUES(comment),
  itemclass = VALUES(itemclass),
  itemtype = VALUES(itemtype),
  icon = VALUES(icon),
  idfile = VALUES(idfile),
  magic = VALUES(magic),
  nodrop = VALUES(nodrop),
  norent = VALUES(norent),
  stackable = VALUES(stackable),
  stacksize = VALUES(stacksize),
  classes = VALUES(classes),
  races = VALUES(races),
  slots = VALUES(slots),
  augtype = VALUES(augtype),
  augrestrict = VALUES(augrestrict),
  loregroup = VALUES(loregroup),
  astr = VALUES(astr),
  asta = VALUES(asta),
  aagi = VALUES(aagi),
  adex = VALUES(adex),
  aint = VALUES(aint),
  awis = VALUES(awis),
  acha = VALUES(acha),
  questitemflag = VALUES(questitemflag),
  price = VALUES(price),
  sellrate = VALUES(sellrate),
  weight = VALUES(weight);

-- -----------------------------------------------------------------------------
-- 4) Allow Tower epic augments in Epic 1.0 weapons via AugType 30 slot
-- -----------------------------------------------------------------------------
UPDATE items
SET augslot6type = 30,
    augslot6visible = 1
WHERE Name IN (
  'Ragebringer',
  'Jagged Blade of War',
  'Water Sprinkler of Nem Ankh',
  'Fiery Defender',
  'Innoruuk''s Curse',
  'Nature Walkers Scimitar',
  'Nature Walker''s Scimitar',
  'Swiftwind',
  'Earthcaller',
  'Celestial Fists',
  'Singing Short Sword',
  'Spear of Fate',
  'Scythe of the Shadowed Soul',
  'Staff of the Four',
  'Orb of Mastery',
  'Staff of the Serpent'
);

-- -----------------------------------------------------------------------------
-- 5) Unlock all doors in Tower objective mission zones
-- -----------------------------------------------------------------------------
UPDATE doors
SET lockpick = 0,
    keyitem = 0,
    nokeyring = 0
WHERE zone IN ('soldunga', 'crushbone', 'blackburrow', 'befallen', 'najena');

-- -----------------------------------------------------------------------------
-- 6) Add Tower objective journal task (shown in Quest Journal)
-- -----------------------------------------------------------------------------
INSERT INTO tasks (
  id, type, duration, duration_code,
  title, description, reward_text, reward_id_list,
  cash_reward, exp_reward, reward_method, reward_points, reward_point_type,
  min_level, max_level, level_spread,
  min_players, max_players,
  repeatable, faction_reward, completion_emote,
  replay_timer_group, replay_timer_seconds, request_timer_group, request_timer_seconds,
  dz_template_id, lock_activity_id, faction_amount, enabled
) VALUES (
  990075, 2, 0, 0,
  'Tower of Infinity: Objective Hunt',
  'Defeat the current named objective target in your Tower floor.',
  'Tower progression and rewards are granted by floor completion.',
  NULL,
  0, 0, 0, 0, 0,
  1, 255, 0,
  1, 72,
  1, 0, 'The Tower objective has been completed.',
  0, 0, 0, 0,
  0, -1, 0, 1
)
ON DUPLICATE KEY UPDATE
  type = VALUES(type),
  duration = VALUES(duration),
  duration_code = VALUES(duration_code),
  title = VALUES(title),
  description = VALUES(description),
  reward_text = VALUES(reward_text),
  reward_id_list = VALUES(reward_id_list),
  cash_reward = VALUES(cash_reward),
  exp_reward = VALUES(exp_reward),
  reward_method = VALUES(reward_method),
  reward_points = VALUES(reward_points),
  reward_point_type = VALUES(reward_point_type),
  min_level = VALUES(min_level),
  max_level = VALUES(max_level),
  level_spread = VALUES(level_spread),
  min_players = VALUES(min_players),
  max_players = VALUES(max_players),
  repeatable = VALUES(repeatable),
  faction_reward = VALUES(faction_reward),
  completion_emote = VALUES(completion_emote),
  replay_timer_group = VALUES(replay_timer_group),
  replay_timer_seconds = VALUES(replay_timer_seconds),
  request_timer_group = VALUES(request_timer_group),
  request_timer_seconds = VALUES(request_timer_seconds),
  dz_template_id = VALUES(dz_template_id),
  lock_activity_id = VALUES(lock_activity_id),
  faction_amount = VALUES(faction_amount),
  enabled = VALUES(enabled);

INSERT INTO task_activities (
  taskid, activityid, req_activity_id, step, activitytype,
  target_name, goalmethod, goalcount, description_override,
  npc_match_list, item_id_list, item_list,
  dz_switch_id, min_x, min_y, min_z, max_x, max_y, max_z,
  skill_list, spell_list, zones, zone_version,
  optional, list_group
) VALUES (
  990075, 0, -1, 1, 2,
  'Named objective defeated', 1, 1, 'Defeat your current Tower named objective target.',
  '17029|17050|17049|17048|17051|58032|58059|58028|58031|58017|36103|36095|36098|36055|36097|44094|44100|44024|44103|44061|31126|31128|31127|31136|31001',
  NULL, '',
  0, 0, 0, 0, 0, 0, 0,
  '-1', '0', '', -1,
  0, 0
)
ON DUPLICATE KEY UPDATE
  req_activity_id = VALUES(req_activity_id),
  step = VALUES(step),
  activitytype = VALUES(activitytype),
  target_name = VALUES(target_name),
  goalmethod = VALUES(goalmethod),
  goalcount = VALUES(goalcount),
  description_override = VALUES(description_override),
  npc_match_list = VALUES(npc_match_list),
  item_id_list = VALUES(item_id_list),
  item_list = VALUES(item_list),
  dz_switch_id = VALUES(dz_switch_id),
  min_x = VALUES(min_x),
  min_y = VALUES(min_y),
  min_z = VALUES(min_z),
  max_x = VALUES(max_x),
  max_y = VALUES(max_y),
  max_z = VALUES(max_z),
  skill_list = VALUES(skill_list),
  spell_list = VALUES(spell_list),
  zones = VALUES(zones),
  zone_version = VALUES(zone_version),
  optional = VALUES(optional),
  list_group = VALUES(list_group);

-- -----------------------------------------------------------------------------
-- 7) Mark Ashrem as complete through Tower difficulty 75
-- -----------------------------------------------------------------------------
INSERT INTO data_buckets (
  `key`, value, expires, account_id, character_id, npc_id, bot_id, zone_id, instance_id
)
SELECT
  'toi_highest_completed', '75', 0, 0, c.id, 0, 0, 0, 0
FROM character_data c
WHERE c.name = 'Ashrem'
ON DUPLICATE KEY UPDATE
  value = VALUES(value),
  expires = VALUES(expires),
  account_id = VALUES(account_id),
  character_id = VALUES(character_id),
  npc_id = VALUES(npc_id),
  bot_id = VALUES(bot_id),
  zone_id = VALUES(zone_id),
  instance_id = VALUES(instance_id);

-- -----------------------------------------------------------------------------
-- 8) Remove Planeshifter Tyrael from Tower instance zones
-- -----------------------------------------------------------------------------
DELETE s2
FROM spawn2 s2
JOIN spawnentry se ON se.spawngroupID = s2.spawngroupID
WHERE se.npcID = 186202
  AND s2.zone IN ('guka', 'ruja', 'taka', 'mira', 'mmca', 'soldunga', 'crushbone', 'blackburrow', 'befallen', 'najena');

-- -----------------------------------------------------------------------------
-- 9) Ensure expansion context includes Lost Dungeons of Norrath (min expansion 6)
-- -----------------------------------------------------------------------------
INSERT INTO rule_values (ruleset_id, rule_name, rule_value, notes)
VALUES (1, 'Expansion:CurrentExpansion', '6', 'Current expansion level (LDoN enabled for Tower system)')
ON DUPLICATE KEY UPDATE
  rule_value = IF(CAST(rule_value AS SIGNED) < 6, '6', rule_value);

-- -----------------------------------------------------------------------------
-- Verification snippets
-- -----------------------------------------------------------------------------
-- SELECT id, name, lastname FROM npc_types WHERE id = 990230;
-- SELECT id, zone, x, y, z FROM spawn2 WHERE id = 990230;
-- SELECT id, Name, augtype, augrestrict, loregroup, astr, asta, aagi, adex, aint, awis, acha
-- FROM items WHERE id BETWEEN 610100 AND 610149 ORDER BY id;
-- SELECT id, Name, augslot6type, augslot6visible
-- FROM items
-- WHERE Name IN (
--  'Ragebringer','Jagged Blade of War','Water Sprinkler of Nem Ankh','Fiery Defender',
--  'Innoruuk''s Curse','Nature Walkers Scimitar','Nature Walker''s Scimitar','Swiftwind',
--  'Earthcaller','Celestial Fists','Singing Short Sword','Spear of Fate',
--  'Scythe of the Shadowed Soul','Staff of the Four','Orb of Mastery','Staff of the Serpent'
-- )
-- ORDER BY Name, id;
-- SELECT b.`key`, b.value, b.character_id
-- FROM data_buckets b
-- JOIN character_data c ON c.id = b.character_id
-- WHERE c.name = 'Ashrem' AND b.`key` = 'toi_highest_completed';
