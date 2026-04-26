-- ============================================================
-- Remove Spell Scrolls from All Vendors
-- Purpose: Make level-up awards the sole source of spells.
-- ItemType = 20 = Spell Scroll in EQEmu items table.
-- Safe to re-run (DELETE of already-deleted rows is a no-op).
-- ============================================================

-- Preview before deleting (comment out DELETE below to dry-run)
SELECT COUNT(*) AS scroll_vendor_entries_to_remove
FROM merchantlist ml
JOIN items i ON ml.item = i.id
WHERE i.ItemType = 20;

-- Remove all spell scrolls from every merchant list
DELETE ml
FROM merchantlist ml
JOIN items i ON ml.item = i.id
WHERE i.ItemType = 20;

-- Confirm
SELECT COUNT(*) AS remaining_scroll_vendor_entries
FROM merchantlist ml
JOIN items i ON ml.item = i.id
WHERE i.ItemType = 20;
