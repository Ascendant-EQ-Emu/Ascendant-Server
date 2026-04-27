-- 03_set_min_cast_level.sql
-- Spells are awarded through the level-up system, so in-game casting level gates
-- are unnecessary once a spell is scribed. Set all non-255 classesX values to 1
-- so any character level can cast awarded spells.
-- classesX = 255 means "this class cannot use this spell" — those remain unchanged.
UPDATE spells_new
SET
    classes1  = IF(classes1  < 255, 1, 255),
    classes2  = IF(classes2  < 255, 1, 255),
    classes3  = IF(classes3  < 255, 1, 255),
    classes4  = IF(classes4  < 255, 1, 255),
    classes5  = IF(classes5  < 255, 1, 255),
    classes6  = IF(classes6  < 255, 1, 255),
    classes7  = IF(classes7  < 255, 1, 255),
    classes8  = IF(classes8  < 255, 1, 255),
    classes9  = IF(classes9  < 255, 1, 255),
    classes10 = IF(classes10 < 255, 1, 255),
    classes11 = IF(classes11 < 255, 1, 255),
    classes12 = IF(classes12 < 255, 1, 255),
    classes13 = IF(classes13 < 255, 1, 255),
    classes14 = IF(classes14 < 255, 1, 255),
    classes15 = IF(classes15 < 255, 1, 255),
    classes16 = IF(classes16 < 255, 1, 255)
WHERE id > 0 AND id < 60000;
