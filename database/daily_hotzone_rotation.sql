-- Daily rotating hot-zone style ZEM system for EQEmu
-- Applies a day-based bonus to a rotating set of non-city-labeled zones.

USE peq;

CREATE TABLE IF NOT EXISTS daily_hotzone_config (
    id TINYINT UNSIGNED NOT NULL PRIMARY KEY,
    zones_per_day TINYINT UNSIGNED NOT NULL DEFAULT 11,
    per_zone_spread_pct DECIMAL(6,4) NOT NULL DEFAULT 0.1000,
    underpop_threshold TINYINT UNSIGNED NOT NULL DEFAULT 5,
    overpop_threshold TINYINT UNSIGNED NOT NULL DEFAULT 5,
    overpop_grace_minutes INT NOT NULL DEFAULT 15,
    bonus_step_minutes INT NOT NULL DEFAULT 240,
    bonus_step_pct DECIMAL(6,4) NOT NULL DEFAULT 0.1000,
    bonus_cap_pct DECIMAL(6,4) NOT NULL DEFAULT 0.7500,
    active TINYINT UNSIGNED NOT NULL DEFAULT 1,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

ALTER TABLE daily_hotzone_config ADD COLUMN IF NOT EXISTS underpop_threshold TINYINT UNSIGNED NOT NULL DEFAULT 5;
ALTER TABLE daily_hotzone_config ADD COLUMN IF NOT EXISTS overpop_threshold TINYINT UNSIGNED NOT NULL DEFAULT 5;
ALTER TABLE daily_hotzone_config ADD COLUMN IF NOT EXISTS overpop_grace_minutes INT NOT NULL DEFAULT 15;
ALTER TABLE daily_hotzone_config ADD COLUMN IF NOT EXISTS bonus_step_minutes INT NOT NULL DEFAULT 240;
ALTER TABLE daily_hotzone_config ADD COLUMN IF NOT EXISTS bonus_step_pct DECIMAL(6,4) NOT NULL DEFAULT 0.1000;
ALTER TABLE daily_hotzone_config ADD COLUMN IF NOT EXISTS bonus_cap_pct DECIMAL(6,4) NOT NULL DEFAULT 0.7500;

INSERT INTO daily_hotzone_config (
    id,
    zones_per_day,
    per_zone_spread_pct,
    underpop_threshold,
    overpop_threshold,
    overpop_grace_minutes,
    bonus_step_minutes,
    bonus_step_pct,
    bonus_cap_pct,
    active
)
VALUES (1, 11, 0.0400, 5, 5, 15, 240, 0.1000, 0.7500, 1)
ON DUPLICATE KEY UPDATE
    zones_per_day = VALUES(zones_per_day),
    per_zone_spread_pct = VALUES(per_zone_spread_pct),
    underpop_threshold = VALUES(underpop_threshold),
    overpop_threshold = VALUES(overpop_threshold),
    overpop_grace_minutes = VALUES(overpop_grace_minutes),
    bonus_step_minutes = VALUES(bonus_step_minutes),
    bonus_step_pct = VALUES(bonus_step_pct),
    bonus_cap_pct = VALUES(bonus_cap_pct),
    active = VALUES(active);

CREATE TABLE IF NOT EXISTS daily_hotzone_day_bonus (
    day_of_week TINYINT UNSIGNED NOT NULL PRIMARY KEY,
    bonus_pct DECIMAL(6,4) NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- MySQL/MariaDB DAYOFWEEK: 1=Sunday ... 7=Saturday
INSERT INTO daily_hotzone_day_bonus (day_of_week, bonus_pct)
VALUES
    (1, 0.2500),
    (2, 0.2500),
    (3, 0.2500),
    (4, 0.2500),
    (5, 0.2500),
    (6, 0.2500),
    (7, 0.2500)
ON DUPLICATE KEY UPDATE bonus_pct = VALUES(bonus_pct);

CREATE TABLE IF NOT EXISTS daily_hotzone_zone_exclusions (
    zoneidnumber INT NOT NULL PRIMARY KEY,
    reason VARCHAR(200) NULL
);

-- Curated exclusions: cities, hubs, guild/social zones, and travel utility zones.
INSERT IGNORE INTO daily_hotzone_zone_exclusions (zoneidnumber, reason) VALUES
    (1,   'City hub: South Qeynos'),
    (2,   'City hub: North Qeynos'),
    (4,   'Near-city travel hub: Qeynos Hills'),
    (8,   'City hub: North Freeport'),
    (9,   'City hub: West Freeport'),
    (10,  'City hub: East Freeport'),
    (45,  'City adjacent: Qeynos Aqueducts'),
    (71,  'Utility/travel zone: Plane of Sky'),
    (77,  'Social zone: The Arena'),
    (151, 'Trade hub: The Bazaar'),
    (152, 'Travel hub: Nexus'),
    (180, 'Social zone: The Arena Two'),
    (202, 'Global hub: Plane of Knowledge'),
    (203, 'Travel hub: Plane of Tranquility'),
    (344, 'Guild hub: Guild Lobby'),
    (345, 'Guild hub: Guild Hall'),
    (382, 'City hub: East Freeport revamp'),
    (383, 'City hub: West Freeport revamp'),
    (384, 'City adjacent: Freeport Sewers'),
    (387, 'City adjacent: Freeport Militia House'),
    (19,  'City hub: Rivervale'),
    (23,  'City hub: Erudin Palace'),
    (24,  'City hub: Erudin'),
    (29,  'City hub: Halas'),
    (40,  'City hub: Neriak Foreign Quarter'),
    (41,  'City hub: Neriak Commons'),
    (42,  'City hub: Neriak Third Gate'),
    (43,  'City hub: Neriak Palace'),
    (49,  'City hub: Oggok'),
    (52,  'City hub: Grobb'),
    (55,  'City hub: AkAnon'),
    (60,  'City hub: South Kaladim'),
    (61,  'City hub: Northern Felwithe'),
    (62,  'City hub: Southern Felwithe'),
    (67,  'City hub: North Kaladim'),
    (82,  'City hub: Cabilis West'),
    (106, 'City hub: Cabilis East'),
    (115, 'City hub: Thurgadin'),
    (155, 'City hub: Shar Vahl'),
    (389, 'City hub: Freeport City Hall'),
    (189, 'Tutorial zone: The Mines of Gloomingdeep'),
    (72,  'Raid zone: Plane of Fear'),
    (76,  'Raid zone: Plane of Hate'),
    (97,  'Raid zone: Plane of Growth (legacy id safeguard)'),
    (127, 'Raid zone: Plane of Growth'),
    (108, 'Raid zone: Veeshan''s Peak'),
    (124, 'Raid zone: Temple of Veeshan'),
    (128, 'Raid zone: Sleeper''s Tomb');

CREATE TABLE IF NOT EXISTS daily_hotzone_base_zem (
    zone_row_id INT NOT NULL PRIMARY KEY,
    zoneidnumber INT NOT NULL,
    version TINYINT UNSIGNED NOT NULL,
    short_name VARCHAR(32) NULL,
    base_zem DECIMAL(6,2) NOT NULL,
    captured_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_daily_hotzone_base_zone_version (zoneidnumber, version)
);

CREATE TABLE IF NOT EXISTS daily_hotzone_rotation_log (
    rotation_date DATE NOT NULL,
    zoneidnumber INT NOT NULL,
    bonus_pct DECIMAL(6,4) NOT NULL,
    applied_zem DECIMAL(6,2) NOT NULL,
    day_bonus_pct DECIMAL(6,4) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (rotation_date, zoneidnumber)
);

CREATE TABLE IF NOT EXISTS daily_hotzone_population_state (
    rotation_date DATE NOT NULL,
    zoneidnumber INT NOT NULL,
    current_player_count INT NOT NULL DEFAULT 0,
    under_threshold_minutes INT NOT NULL DEFAULT 0,
    over_threshold_minutes INT NOT NULL DEFAULT 0,
    growth_paused TINYINT UNSIGNED NOT NULL DEFAULT 0,
    adaptive_bonus_pct DECIMAL(6,4) NOT NULL DEFAULT 0.0000,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (rotation_date, zoneidnumber)
);

-- Preserve your original MOTD so dynamic updates can safely append hot-zones.
INSERT IGNORE INTO variables (varname, value, information)
SELECT 'MOTD_BASE', value, 'Base MOTD prior to hot-zone append'
    FROM variables
 WHERE varname = 'MOTD';

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_refresh_daily_hotzone_motd $$
CREATE PROCEDURE sp_refresh_daily_hotzone_motd()
motd_block: BEGIN
    DECLARE v_run_date DATE DEFAULT CURDATE();
    DECLARE v_classic_list TEXT DEFAULT '';
    DECLARE v_kunark_list TEXT DEFAULT '';
    DECLARE v_velious_list TEXT DEFAULT '';
    DECLARE v_hotzone_list TEXT DEFAULT '';

    SELECT GROUP_CONCAT(
               CONCAT(
                   t.rn,
                   ') ',
                   t.long_name,
                   ' +',
                   t.effective_bonus_pct,
                   '%'
               )
               ORDER BY t.rn
               SEPARATOR '\n'
           )
      INTO v_classic_list
      FROM (
          SELECT
              ROW_NUMBER() OVER (ORDER BY z.zone_exp_multiplier DESC, r.zoneidnumber) AS rn,
              r.zoneidnumber,
              z.long_name,
              z.zone_exp_multiplier,
              ROUND((r.bonus_pct + COALESCE(s.adaptive_bonus_pct, 0)) * 100, 1) AS effective_bonus_pct
          FROM daily_hotzone_rotation_log r
          JOIN zone z
            ON z.zoneidnumber = r.zoneidnumber
           AND z.version = 0
     LEFT JOIN daily_hotzone_population_state s
            ON s.rotation_date = r.rotation_date
           AND s.zoneidnumber = r.zoneidnumber
         WHERE r.rotation_date = v_run_date
           AND z.expansion = 0
         ORDER BY z.zone_exp_multiplier DESC, r.zoneidnumber
      ) t;

    SELECT GROUP_CONCAT(
               CONCAT(
                   t.rn,
                   ') ',
                   t.long_name,
                   ' +',
                   t.effective_bonus_pct,
                   '%'
               )
               ORDER BY t.rn
               SEPARATOR '\n'
           )
      INTO v_kunark_list
      FROM (
          SELECT
              ROW_NUMBER() OVER (ORDER BY z.zone_exp_multiplier DESC, r.zoneidnumber) AS rn,
              r.zoneidnumber,
              z.long_name,
              z.zone_exp_multiplier,
              ROUND((r.bonus_pct + COALESCE(s.adaptive_bonus_pct, 0)) * 100, 1) AS effective_bonus_pct
          FROM daily_hotzone_rotation_log r
          JOIN zone z
            ON z.zoneidnumber = r.zoneidnumber
           AND z.version = 0
     LEFT JOIN daily_hotzone_population_state s
            ON s.rotation_date = r.rotation_date
           AND s.zoneidnumber = r.zoneidnumber
         WHERE r.rotation_date = v_run_date
           AND z.expansion = 1
         ORDER BY z.zone_exp_multiplier DESC, r.zoneidnumber
      ) t;

    SELECT GROUP_CONCAT(
               CONCAT(
                   t.rn,
                   ') ',
                   t.long_name,
                   ' +',
                   t.effective_bonus_pct,
                   '%'
               )
               ORDER BY t.rn
               SEPARATOR '\n'
           )
      INTO v_velious_list
      FROM (
          SELECT
              ROW_NUMBER() OVER (ORDER BY z.zone_exp_multiplier DESC, r.zoneidnumber) AS rn,
              r.zoneidnumber,
              z.long_name,
              z.zone_exp_multiplier,
              ROUND((r.bonus_pct + COALESCE(s.adaptive_bonus_pct, 0)) * 100, 1) AS effective_bonus_pct
          FROM daily_hotzone_rotation_log r
          JOIN zone z
            ON z.zoneidnumber = r.zoneidnumber
           AND z.version = 0
     LEFT JOIN daily_hotzone_population_state s
            ON s.rotation_date = r.rotation_date
           AND s.zoneidnumber = r.zoneidnumber
         WHERE r.rotation_date = v_run_date
           AND z.expansion = 2
         ORDER BY z.zone_exp_multiplier DESC, r.zoneidnumber
      ) t;

    SET v_hotzone_list = CONCAT(
        CHAR(10), '-Classic-', CHAR(10), COALESCE(NULLIF(v_classic_list, ''), 'None'),
        CHAR(10), '-Kunark-', CHAR(10), COALESCE(NULLIF(v_kunark_list, ''), 'None'),
        CHAR(10), '-Velious-', CHAR(10), COALESCE(NULLIF(v_velious_list, ''), 'None')
    );

    INSERT INTO variables (varname, value, information)
    VALUES (
        'MOTD',
        CONCAT('Daily Hot Zones:', v_hotzone_list),
        'Auto-generated by daily hot-zone rotation'
    )
    ON DUPLICATE KEY UPDATE
        value = VALUES(value),
        information = VALUES(information);
END $$

DROP PROCEDURE IF EXISTS sp_scale_daily_hotzones_by_population $$
CREATE PROCEDURE sp_scale_daily_hotzones_by_population()
scale_block: BEGIN
        DECLARE v_run_date DATE DEFAULT CURDATE();
        DECLARE v_eval_minutes INT DEFAULT 5;
        DECLARE v_underpop_threshold INT DEFAULT 5;
        DECLARE v_overpop_threshold INT DEFAULT 5;
        DECLARE v_overpop_grace_minutes INT DEFAULT 15;
        DECLARE v_bonus_step_minutes INT DEFAULT 240;
        DECLARE v_bonus_step_pct DECIMAL(6,4) DEFAULT 0.1000;
        DECLARE v_bonus_cap_pct DECIMAL(6,4) DEFAULT 0.7500;
    DECLARE v_active TINYINT UNSIGNED DEFAULT 1;

        SELECT underpop_threshold,
               overpop_threshold,
               overpop_grace_minutes,
               bonus_step_minutes,
               bonus_step_pct,
               bonus_cap_pct,
               active
          INTO v_underpop_threshold,
               v_overpop_threshold,
               v_overpop_grace_minutes,
               v_bonus_step_minutes,
               v_bonus_step_pct,
               v_bonus_cap_pct,
             v_active
          FROM daily_hotzone_config
         WHERE id = 1
         LIMIT 1;

        IF COALESCE(v_active, 1) = 0 THEN
            LEAVE scale_block;
        END IF;

        IF NOT EXISTS (
                SELECT 1 FROM daily_hotzone_rotation_log WHERE rotation_date = v_run_date LIMIT 1
        ) THEN
                LEAVE scale_block;
        END IF;

        DELETE FROM daily_hotzone_population_state
         WHERE rotation_date <> v_run_date;

        INSERT IGNORE INTO daily_hotzone_population_state (
                rotation_date,
                zoneidnumber,
                current_player_count,
                under_threshold_minutes,
                over_threshold_minutes,
                growth_paused,
                adaptive_bonus_pct
        )
        SELECT v_run_date, r.zoneidnumber, 0, 0, 0, 0, 0.0000
            FROM daily_hotzone_rotation_log r
         WHERE r.rotation_date = v_run_date;

        DROP TEMPORARY TABLE IF EXISTS tmp_hotzone_player_counts;
        CREATE TEMPORARY TABLE tmp_hotzone_player_counts (
                zoneidnumber INT PRIMARY KEY,
                player_count INT NOT NULL
        ) ENGINE=MEMORY;

        INSERT INTO tmp_hotzone_player_counts (zoneidnumber, player_count)
        SELECT c.zone_id, COUNT(*)
            FROM character_data c
         WHERE c.ingame = 1
             AND c.deleted_at IS NULL
             AND EXISTS (
                        SELECT 1
                            FROM daily_hotzone_rotation_log r
                         WHERE r.rotation_date = v_run_date
                             AND r.zoneidnumber = c.zone_id
             )
         GROUP BY c.zone_id;

        UPDATE daily_hotzone_population_state s
        LEFT JOIN tmp_hotzone_player_counts p
            ON p.zoneidnumber = s.zoneidnumber
             SET s.current_player_count = COALESCE(p.player_count, 0)
         WHERE s.rotation_date = v_run_date;

        -- Fewer than 5 players: growth always resumes and accumulates.
        UPDATE daily_hotzone_population_state s
             SET s.under_threshold_minutes = s.under_threshold_minutes + v_eval_minutes,
                     s.over_threshold_minutes = 0,
                     s.growth_paused = 0
         WHERE s.rotation_date = v_run_date
             AND s.current_player_count < v_underpop_threshold;

        -- Exactly 5 players: hold current state, but clear any crowd timer.
        UPDATE daily_hotzone_population_state s
             SET s.over_threshold_minutes = 0,
                     s.growth_paused = 0
         WHERE s.rotation_date = v_run_date
             AND s.current_player_count = v_underpop_threshold;

        -- More than 5 players for up to 15 minutes: allow existing growth timer to continue.
        UPDATE daily_hotzone_population_state s
             SET s.under_threshold_minutes = s.under_threshold_minutes + v_eval_minutes,
                     s.over_threshold_minutes = s.over_threshold_minutes + v_eval_minutes,
                     s.growth_paused = 0
         WHERE s.rotation_date = v_run_date
             AND s.current_player_count > v_overpop_threshold
             AND s.over_threshold_minutes < v_overpop_grace_minutes;

        -- More than 5 players sustained beyond 15 minutes: freeze further growth.
        UPDATE daily_hotzone_population_state s
             SET s.over_threshold_minutes = s.over_threshold_minutes + v_eval_minutes,
                     s.growth_paused = 1
         WHERE s.rotation_date = v_run_date
             AND s.current_player_count > v_overpop_threshold
             AND s.over_threshold_minutes >= v_overpop_grace_minutes;

        UPDATE daily_hotzone_population_state s
        JOIN daily_hotzone_rotation_log r
            ON r.rotation_date = s.rotation_date
         AND r.zoneidnumber = s.zoneidnumber
             SET s.adaptive_bonus_pct = LEAST(
                        GREATEST(0.0000, v_bonus_cap_pct - r.bonus_pct),
                        FLOOR(s.under_threshold_minutes / v_bonus_step_minutes) * v_bonus_step_pct
             )
         WHERE s.rotation_date = v_run_date;

        UPDATE zone z
        JOIN daily_hotzone_rotation_log r
            ON r.zoneidnumber = z.zoneidnumber
         AND r.rotation_date = v_run_date
        LEFT JOIN daily_hotzone_population_state s
            ON s.rotation_date = r.rotation_date
         AND s.zoneidnumber = r.zoneidnumber
        JOIN (
                SELECT zoneidnumber, MAX(base_zem) AS base_zem
                    FROM daily_hotzone_base_zem
                 GROUP BY zoneidnumber
        ) b ON b.zoneidnumber = z.zoneidnumber
             SET z.zone_exp_multiplier = ROUND(
                             b.base_zem * (1 + LEAST(v_bonus_cap_pct, r.bonus_pct + COALESCE(s.adaptive_bonus_pct, 0.0000))),
                             2
                     ),
                     z.hotzone = 1;

        CALL sp_refresh_daily_hotzone_motd();

        DROP TEMPORARY TABLE IF EXISTS tmp_hotzone_player_counts;
END $$

DROP PROCEDURE IF EXISTS sp_rotate_daily_hotzones $$
CREATE PROCEDURE sp_rotate_daily_hotzones(IN p_force TINYINT UNSIGNED)
main_block: BEGIN
    DECLARE v_run_date DATE DEFAULT CURDATE();
    DECLARE v_day_bonus DECIMAL(6,4) DEFAULT 0.2000;
    DECLARE v_spread DECIMAL(6,4) DEFAULT 0.1000;
    DECLARE v_zones_per_day TINYINT UNSIGNED DEFAULT 12;
    DECLARE v_active TINYINT UNSIGNED DEFAULT 1;
    DECLARE v_current_expansion INT DEFAULT 2;
    DECLARE v_remaining INT DEFAULT 0;

    SELECT bonus_pct
      INTO v_day_bonus
      FROM daily_hotzone_day_bonus
     WHERE day_of_week = DAYOFWEEK(v_run_date)
     LIMIT 1;

    SELECT zones_per_day, per_zone_spread_pct, active
      INTO v_zones_per_day, v_spread, v_active
      FROM daily_hotzone_config
     WHERE id = 1
     LIMIT 1;

        SELECT CAST(rule_value AS SIGNED)
            INTO v_current_expansion
            FROM rule_values
         WHERE rule_name = 'Expansion:CurrentExpansion'
         ORDER BY ruleset_id
         LIMIT 1;

        IF v_current_expansion IS NULL THEN
                SET v_current_expansion = 2;
        END IF;

    IF v_active = 0 THEN
        LEAVE main_block;
    END IF;

    IF p_force = 0 AND EXISTS (
        SELECT 1 FROM daily_hotzone_rotation_log WHERE rotation_date = v_run_date LIMIT 1
    ) THEN
        LEAVE main_block;
    END IF;

    -- Snapshot original per-row ZEM once.
    INSERT IGNORE INTO daily_hotzone_base_zem (zone_row_id, zoneidnumber, version, short_name, base_zem)
    SELECT z.id, z.zoneidnumber, z.version, z.short_name, z.zone_exp_multiplier
      FROM zone z;

    -- Reset all zones to original ZEM and clear hotzone flag before applying today's picks.
    UPDATE zone z
    JOIN daily_hotzone_base_zem b
      ON b.zone_row_id = z.id
       SET z.zone_exp_multiplier = b.base_zem,
           z.hotzone = 0;

    -- Rebuild today's rotation when forcing.
    DELETE FROM daily_hotzone_rotation_log WHERE rotation_date = v_run_date;

        DROP TEMPORARY TABLE IF EXISTS tmp_daily_hotzone_candidates;
        CREATE TEMPORARY TABLE tmp_daily_hotzone_candidates (
        zoneidnumber INT PRIMARY KEY,
        priority_bucket TINYINT UNSIGNED NOT NULL DEFAULT 1
    ) ENGINE=MEMORY;

        DROP TEMPORARY TABLE IF EXISTS tmp_daily_hotzone_eligible;
        CREATE TEMPORARY TABLE tmp_daily_hotzone_eligible (
                zoneidnumber INT PRIMARY KEY,
            expansion TINYINT UNSIGNED NOT NULL,
                level_hint INT NOT NULL,
                level_bracket TINYINT UNSIGNED NOT NULL
        ) ENGINE=MEMORY;

        INSERT INTO tmp_daily_hotzone_eligible (zoneidnumber, expansion, level_hint, level_bracket)
        SELECT
                z.zoneidnumber,
            z.expansion,
                CASE
                        WHEN z.min_level > 0 THEN z.min_level
                        WHEN z.max_level > 0 AND z.max_level < 255 THEN GREATEST(1, FLOOR(z.max_level / 2))
                        ELSE 45
                END AS level_hint,
                CASE
                        WHEN (CASE
                                        WHEN z.min_level > 0 THEN z.min_level
                                        WHEN z.max_level > 0 AND z.max_level < 255 THEN GREATEST(1, FLOOR(z.max_level / 2))
                                        ELSE 45
                                    END) <= 10 THEN 1
                        WHEN (CASE
                                        WHEN z.min_level > 0 THEN z.min_level
                                        WHEN z.max_level > 0 AND z.max_level < 255 THEN GREATEST(1, FLOOR(z.max_level / 2))
                                        ELSE 45
                                    END) <= 20 THEN 2
                        WHEN (CASE
                                        WHEN z.min_level > 0 THEN z.min_level
                                        WHEN z.max_level > 0 AND z.max_level < 255 THEN GREATEST(1, FLOOR(z.max_level / 2))
                                        ELSE 45
                                    END) <= 30 THEN 3
                        WHEN (CASE
                                        WHEN z.min_level > 0 THEN z.min_level
                                        WHEN z.max_level > 0 AND z.max_level < 255 THEN GREATEST(1, FLOOR(z.max_level / 2))
                                        ELSE 45
                                    END) <= 40 THEN 4
                        WHEN (CASE
                                        WHEN z.min_level > 0 THEN z.min_level
                                        WHEN z.max_level > 0 AND z.max_level < 255 THEN GREATEST(1, FLOOR(z.max_level / 2))
                                        ELSE 45
                                    END) <= 50 THEN 5
                        WHEN (CASE
                                        WHEN z.min_level > 0 THEN z.min_level
                                        WHEN z.max_level > 0 AND z.max_level < 255 THEN GREATEST(1, FLOOR(z.max_level / 2))
                                        ELSE 45
                                    END) <= 60 THEN 6
                        ELSE 7
                END AS level_bracket
            FROM zone z
         WHERE z.version = 0
             AND z.zoneidnumber > 0
             AND z.zone_exp_multiplier > 0
             AND z.cancombat = 1
             AND z.type IN (0, 1)
             AND z.zoneidnumber <> 189
             AND NOT (z.zoneidnumber BETWEEN 229 AND 276)
             AND z.expansion <= v_current_expansion
             AND (z.min_expansion = -1 OR z.min_expansion <= v_current_expansion)
             AND (z.max_expansion = -1 OR z.max_expansion >= v_current_expansion)
             AND LOWER(COALESCE(z.short_name, '')) NOT LIKE '%city%'
             AND LOWER(COALESCE(z.short_name, '')) NOT LIKE '%test%'
             AND LOWER(z.long_name) NOT LIKE '%city%'
             AND LOWER(z.long_name) NOT LIKE '%test%'
             AND NOT EXISTS (
                        SELECT 1
                            FROM daily_hotzone_zone_exclusions x
                         WHERE x.zoneidnumber = z.zoneidnumber
             );

          -- Guarantee target distribution from Classic, Kunark, and Velious (when available).
          INSERT IGNORE INTO tmp_daily_hotzone_candidates (zoneidnumber, priority_bucket)
          SELECT e.zoneidnumber, 0
             FROM tmp_daily_hotzone_eligible e
            WHERE e.expansion = 0
        ORDER BY RAND()
            LIMIT 5;

          INSERT IGNORE INTO tmp_daily_hotzone_candidates (zoneidnumber, priority_bucket)
          SELECT e.zoneidnumber, 0
             FROM tmp_daily_hotzone_eligible e
            WHERE e.expansion = 1
        ORDER BY RAND()
            LIMIT 3;

          INSERT IGNORE INTO tmp_daily_hotzone_candidates (zoneidnumber, priority_bucket)
          SELECT e.zoneidnumber, 0
             FROM tmp_daily_hotzone_eligible e
            WHERE e.expansion = 2
        ORDER BY RAND()
            LIMIT 3;

        -- Backfill any shortfall from any remaining eligible zones.
        SET v_remaining = v_zones_per_day - (SELECT COUNT(*) FROM tmp_daily_hotzone_candidates);
        IF v_remaining < 0 THEN
            SET v_remaining = 0;
        END IF;

        INSERT IGNORE INTO tmp_daily_hotzone_candidates (zoneidnumber, priority_bucket)
        SELECT e.zoneidnumber,
               1
          FROM tmp_daily_hotzone_eligible e
         LEFT JOIN tmp_daily_hotzone_candidates c
            ON c.zoneidnumber = e.zoneidnumber
         WHERE c.zoneidnumber IS NULL
          ORDER BY RAND()
         LIMIT v_remaining;

    INSERT INTO daily_hotzone_rotation_log (rotation_date, zoneidnumber, bonus_pct, applied_zem, day_bonus_pct)
    SELECT
        v_run_date,
        c.zoneidnumber,
        ROUND(v_day_bonus + ((RAND(c.zoneidnumber + TO_DAYS(v_run_date)) - 0.5) * v_spread), 4) AS bonus_pct,
        ROUND(b.base_zem * (1 + ROUND(v_day_bonus + ((RAND(c.zoneidnumber + TO_DAYS(v_run_date)) - 0.5) * v_spread), 4)), 2) AS applied_zem,
        v_day_bonus
    FROM (
        SELECT c.zoneidnumber
          FROM tmp_daily_hotzone_candidates c
      ORDER BY c.priority_bucket ASC, RAND()
         LIMIT v_zones_per_day
    ) c
    JOIN (
        SELECT zoneidnumber, MAX(base_zem) AS base_zem
          FROM daily_hotzone_base_zem
         GROUP BY zoneidnumber
    ) b ON b.zoneidnumber = c.zoneidnumber;

    UPDATE zone z
    JOIN daily_hotzone_rotation_log r
      ON r.zoneidnumber = z.zoneidnumber
     AND r.rotation_date = v_run_date
       SET z.zone_exp_multiplier = r.applied_zem,
           z.hotzone = 1;

        DELETE FROM daily_hotzone_population_state WHERE rotation_date <> v_run_date;
        DELETE FROM daily_hotzone_population_state WHERE rotation_date = v_run_date;

        INSERT INTO daily_hotzone_population_state (
                rotation_date,
                zoneidnumber,
                current_player_count,
                under_threshold_minutes,
                over_threshold_minutes,
                growth_paused,
                adaptive_bonus_pct
        )
        SELECT v_run_date, r.zoneidnumber, 0, 0, 0, 0, 0.0000
            FROM daily_hotzone_rotation_log r
         WHERE r.rotation_date = v_run_date;

        CALL sp_scale_daily_hotzones_by_population();

    DROP TEMPORARY TABLE IF EXISTS tmp_daily_hotzone_candidates;
END $$

DELIMITER ;

DROP EVENT IF EXISTS ev_rotate_daily_hotzones;
CREATE EVENT ev_rotate_daily_hotzones
    ON SCHEDULE EVERY 1 DAY
    STARTS (TIMESTAMP(CURRENT_DATE, '00:05:00') + INTERVAL 1 DAY)
    DO CALL sp_rotate_daily_hotzones(0);

DROP EVENT IF EXISTS ev_scale_daily_hotzones_by_population;
CREATE EVENT ev_scale_daily_hotzones_by_population
    ON SCHEDULE EVERY 5 MINUTE
    STARTS CURRENT_TIMESTAMP + INTERVAL 5 MINUTE
    DO CALL sp_scale_daily_hotzones_by_population();

-- Run once now so you get immediate rotation results.
CALL sp_rotate_daily_hotzones(1);
