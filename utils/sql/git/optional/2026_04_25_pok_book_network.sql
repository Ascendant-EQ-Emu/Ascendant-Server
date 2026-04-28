-- Plane of Knowledge Book-to-Book Travel Network Implementation
-- Date: 2026-04-25
-- Purpose: Convert hardcoded PoK book teleports to dynamic inter-book travel system
-- Author: Ascendant Server Development

-- Verify all eligible PoK outbound book portals
-- These are the 38 doors that will enable inter-book travel
SELECT 'VERIFICATION: PoK Outbound Book Portals (Non-PoK Destinations)' as note;
SELECT 
    id, 
    name, 
    dest_zone, 
    dest_x, 
    dest_y, 
    dest_z, 
    dest_heading
FROM doors
WHERE zone = 'poknowledge'
AND dest_zone NOT IN ('poknowledge', 'NONE', '')
ORDER BY dest_zone, id;

-- Count of eligible doors
SELECT 
    COUNT(*) as eligible_portal_count,
    COUNT(DISTINCT dest_zone) as unique_destination_zones
FROM doors
WHERE zone = 'poknowledge'
AND dest_zone NOT IN ('poknowledge', 'NONE', '');

-- List of destination zones available from PoK books
SELECT DISTINCT 
    dest_zone,
    COUNT(*) as portal_count
FROM doors
WHERE zone = 'poknowledge'
AND dest_zone NOT IN ('poknowledge', 'NONE', '')
GROUP BY dest_zone
ORDER BY dest_zone;

-- Show all book portal doors with their IDs (for script reference)
SELECT 
    id, 
    name, 
    dest_zone,
    opentype
FROM doors
WHERE zone = 'poknowledge'
AND dest_zone NOT IN ('poknowledge', 'NONE', '')
ORDER BY id;

-- Safety check: Verify all destination zones exist in zone table
SELECT 'SAFETY CHECK: Verifying all destination zones exist' as check_type;
SELECT DISTINCT d.dest_zone, z.zoneidnumber, z.short_name
FROM (
    SELECT DISTINCT dest_zone 
    FROM doors 
    WHERE zone = 'poknowledge' 
    AND dest_zone NOT IN ('poknowledge', 'NONE', '')
) d
LEFT JOIN zone z ON d.dest_zone = z.short_name
ORDER BY d.dest_zone;

-- Document the implementation
-- The following quest script (poknowledge.pl) implements the book-to-book travel:
-- - EVENT_CLICKDOOR intercepts book portal clicks
-- - Generates dynamic destination menu from the above door data
-- - Uses saylink menu format for client compatibility
-- - Teleports player to selected destination via MovePC()
-- 
-- No database schema changes required - this implementation uses existing door data structure
-- Installation: Place poknowledge.pl in the quests/poknowledge/ directory
