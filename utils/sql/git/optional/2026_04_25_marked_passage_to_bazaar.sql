-- Repoint the Marked Passage AA spell to the same safe coordinates used by
-- #zone bazaar (Bazaar version 0 via GetZoneVersionWithFallback).
-- AA: Marked Passage (aa_ability.id = 30196)
-- Rank: 31000
-- Spell: 26508

UPDATE spells_new
SET teleport_zone = 'bazaar',
	effectid1 = 83,
	effect_base_value1 = -821,
	effectid2 = 254,
	effect_base_value2 = 140,
	effect_base_value3 = 5,
	effect_base_value4 = 0,
	targettype = 6,
	zonetype = -1
WHERE id = 26508
	AND name = 'Marked Passage';

SELECT a.id AS aa_id,
	LEFT(a.name, 80) AS aa_name,
	r.id AS rank_id,
	r.spell AS spell_id,
	s.name AS spell_name,
	s.teleport_zone,
	s.effectid1,
	s.effect_base_value1,
	s.targettype,
	s.zonetype
FROM aa_ability AS a
JOIN aa_ranks AS r ON r.id = a.first_rank_id
JOIN spells_new AS s ON s.id = r.spell
WHERE a.id = 30196;
