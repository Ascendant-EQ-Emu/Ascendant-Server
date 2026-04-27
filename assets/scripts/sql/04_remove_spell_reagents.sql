-- Remove all spell reagent requirements so spells cast without components.
UPDATE spells_new
SET
    components1       = -1,
    components2       = -1,
    components3       = -1,
    components4       = -1,
    component_counts1 = 0,
    component_counts2 = 0,
    component_counts3 = 0,
    component_counts4 = 0
WHERE id > 0 AND id < 60000
  AND (
      components1 != -1 OR components2 != -1 OR
      components3 != -1 OR components4 != -1
  );
