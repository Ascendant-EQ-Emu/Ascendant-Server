-- ============================================================
-- Spell Class Normalization Migration
-- Purpose: Make every castable spell available to all classes
--          at its historical minimum level requirement.
-- Effect:  classes1-16 all set to the lowest non-255 value
--          found across all 16 class columns.
-- Run ONCE after importing Ascendant spell data.
-- Safe to re-run (idempotent via backup table guard).
-- ============================================================

-- Backup original class columns before touching them
CREATE TABLE IF NOT EXISTS spells_new_class_backup AS
  SELECT id, name,
         classes1,  classes2,  classes3,  classes4,
         classes5,  classes6,  classes7,  classes8,
         classes9,  classes10, classes11, classes12,
         classes13, classes14, classes15, classes16
  FROM spells_new;

-- Apply normalization: all 16 class columns → single min level
UPDATE spells_new s
JOIN (
  SELECT id,
    LEAST(
      IF(classes1  < 255, classes1,  999),
      IF(classes2  < 255, classes2,  999),
      IF(classes3  < 255, classes3,  999),
      IF(classes4  < 255, classes4,  999),
      IF(classes5  < 255, classes5,  999),
      IF(classes6  < 255, classes6,  999),
      IF(classes7  < 255, classes7,  999),
      IF(classes8  < 255, classes8,  999),
      IF(classes9  < 255, classes9,  999),
      IF(classes10 < 255, classes10, 999),
      IF(classes11 < 255, classes11, 999),
      IF(classes12 < 255, classes12, 999),
      IF(classes13 < 255, classes13, 999),
      IF(classes14 < 255, classes14, 999),
      IF(classes15 < 255, classes15, 999),
      IF(classes16 < 255, classes16, 999)
    ) AS min_level
  FROM spells_new
  WHERE NOT (
    classes1 = 255 AND classes2  = 255 AND classes3  = 255 AND classes4  = 255 AND
    classes5 = 255 AND classes6  = 255 AND classes7  = 255 AND classes8  = 255 AND
    classes9 = 255 AND classes10 = 255 AND classes11 = 255 AND classes12 = 255 AND
    classes13= 255 AND classes14 = 255 AND classes15 = 255 AND classes16 = 255
  )
) AS ml ON s.id = ml.id
SET
  s.classes1  = ml.min_level,
  s.classes2  = ml.min_level,
  s.classes3  = ml.min_level,
  s.classes4  = ml.min_level,
  s.classes5  = ml.min_level,
  s.classes6  = ml.min_level,
  s.classes7  = ml.min_level,
  s.classes8  = ml.min_level,
  s.classes9  = ml.min_level,
  s.classes10 = ml.min_level,
  s.classes11 = ml.min_level,
  s.classes12 = ml.min_level,
  s.classes13 = ml.min_level,
  s.classes14 = ml.min_level,
  s.classes15 = ml.min_level,
  s.classes16 = ml.min_level;

-- Verify: confirm no spells with mixed class values remain (except all-255)
SELECT COUNT(*) AS spells_with_inconsistent_classes
FROM spells_new
WHERE NOT (
  classes1 = classes2  AND classes2 = classes3  AND classes3 = classes4  AND
  classes4 = classes5  AND classes5 = classes6  AND classes6 = classes7  AND
  classes7 = classes8  AND classes8 = classes9  AND classes9 = classes10 AND
  classes10= classes11 AND classes11= classes12 AND classes12= classes13 AND
  classes13= classes14 AND classes14= classes15 AND classes15= classes16
);
