-- ============================================================
-- spell_award.lua
-- Custom Spell Unlock System for Ascendant EQEmu Server
--
-- Flow:
--   1. Character levels up → DialogueWindow popup opens
--   2. Popup buttons trigger event_popup_response (SA_PICK1/2/3)
--   3. Spell is scribed directly into spellbook (ScribeSpell)
--   4. Award is recorded per character+level (anti-exploit)
--
-- Popup IDs:
--   SA_PICK1 (1001) = choose spell 1 (YES on window 1)
--   SA_MORE  (1002) = see spells 2 & 3 (NO on window 1, 3-spell case)
--   SA_PICK2 (1003) = choose spell 2 (YES on window 2)
--   SA_PICK3 (1004) = choose spell 3 (NO on window 2)
--   SA_PASS  (1005) = pass / no choice (only offered for 1-spell case)
-- ============================================================

local M = {}

local SA_PICK1 = 1001
local SA_MORE  = 1002
local SA_PICK2 = 1003
local SA_PICK3 = 1004
local SA_PASS  = 1005

local _pool = nil
local function get_pool()
    if not _pool then
        local ok, mod = pcall(require, "spell_pool")
        if not ok or not mod or not mod.pool then return nil end
        _pool = mod.pool
    end
    return _pool
end

-- ---- Expansion unlock -----------------------------------------------

local function get_max_expac(char_id)
    local k = tostring(char_id)
    if eq.get_data("velious_awarded_" .. k) ~= "" then return 3 end
    if eq.get_data("kunark_awarded_"  .. k) ~= "" then return 2 end
    if eq.get_data("classic_awarded_" .. k) ~= "" then return 1 end
    return 0
end

local EXPAC_NAMES = { [0]="Classic", [1]="Kunark", [2]="Velious", [3]="Luclin+" }

-- ---- Data bucket helpers --------------------------------------------

local function bucket_done(char_id)    return "sa_done:"    .. char_id end
local function bucket_pending(char_id) return "sa_pending:" .. char_id end

local function level_already_awarded(char_id, level)
    local done = eq.get_data(bucket_done(char_id))
    if not done or done == "" then return false end
    for n in done:gmatch("%d+") do
        if tonumber(n) == level then return true end
    end
    return false
end

local function mark_level_awarded(char_id, level)
    local done = eq.get_data(bucket_done(char_id))
    local new  = (done ~= "") and (done .. "," .. level) or tostring(level)
    eq.set_data(bucket_done(char_id), new)
end

local function parse_pending(char_id)
    local raw = eq.get_data(bucket_pending(char_id))
    if not raw or raw == "" then return nil, nil end
    local spell_part, level_str = raw:match("^(.+):(%d+)$")
    if not spell_part then return nil, nil end
    local ids = {}
    for s in spell_part:gmatch("%d+") do ids[#ids+1] = tonumber(s) end
    return ids, tonumber(level_str)
end

-- ---- Random pick (Fisher-Yates partial) -----------------------------

local function pick_random(list, count)
    local result, n = {}, #list
    count = math.min(count, n)
    for i = 1, count do
        local j = math.random(i, n)
        list[i], list[j] = list[j], list[i]
        result[i] = list[i]
    end
    return result
end

-- ---- Popup window helpers -------------------------------------------

-- Returns a single formatted line: "{gold}Name~ (Level X)"
local function spell_line(pool, spell_id)
    local e = pool[spell_id]
    if not e then return "<i>Unknown</i>" end
    return string.format("{gold}%s~  (Level %d)", e.name, e.level)
end

-- Window 1: shows all available spells, YES = choose spell 1.
-- If 3 choices: NO = see window 2.  If 2 choices: NO = choose spell 2.
local function send_window1(client, choices, pool, level, expac_name)
    local n    = #choices
    local line1 = spell_line(pool, choices[1])
    local title = string.format("Spell Award - Level %d  %s", level, expac_name)

    if n == 1 then
        client:DialogueWindow(string.format(
            "{title:%s}wintype:1 popupid:%d secondresponseid:%d " ..
            "{button_one:Learn Spell}{button_two:Pass}noquotes" ..
            "%s",
            title, SA_PICK1, SA_PASS, line1
        ))
    elseif n == 2 then
        local line2 = spell_line(pool, choices[2])
        client:DialogueWindow(string.format(
            "{title:%s}wintype:1 popupid:%d secondresponseid:%d " ..
            "{button_one:Spell 1}{button_two:Spell 2}noquotes" ..
            "1)  %s<br>2)  %s",
            title, SA_PICK1, SA_PICK2, line1, line2
        ))
    else
        local line2 = spell_line(pool, choices[2])
        local line3 = spell_line(pool, choices[3])
        client:DialogueWindow(string.format(
            "{title:%s}wintype:1 popupid:%d secondresponseid:%d " ..
            "{button_one:Spell 1}{button_two:Spells 2 or 3}noquotes" ..
            "1)  %s<br>2)  %s<br>3)  %s",
            title, SA_PICK1, SA_MORE, line1, line2, line3
        ))
    end
end

-- Window 2: shown when player clicks "Spells 2 or 3" in window 1.
local function send_window2(client, choices, pool, level)
    local line2 = spell_line(pool, choices[2])
    local line3 = spell_line(pool, choices[3])
    client:DialogueWindow(string.format(
        "{title:Spell Award - Level %d  Options 2 and 3}" ..
        "wintype:1 popupid:%d secondresponseid:%d " ..
        "{button_one:Spell 2}{button_two:Spell 3}noquotes" ..
        "2)  %s<br>3)  %s",
        level, SA_PICK2, SA_PICK3, line2, line3
    ))
end

-- ---- Award spell to client ------------------------------------------

local function award_spell(client, spell_id)
    local pool  = get_pool()
    local entry = pool and pool[spell_id]
    if not entry then return false end

    local slot = client:GetNextAvailableSpellBookSlot()
    if slot < 0 then
        client:Message(4, "Your spellbook is full! Please free a slot and contact a GM.")
        return false
    end
    client:ScribeSpell(spell_id, slot, true)
    client:Message(13, string.format("'%s' has been inscribed into your spellbook.", entry.name))
    return true
end

-- ---- Public: level-up event -----------------------------------------

function M.on_level_up(client)
    local char_id = client:CharacterID()
    local level   = client:GetLevel()

    if level_already_awarded(char_id, level) then return end

    -- Re-show the pending window if they have an unanswered offer
    local stale_ids, stale_level = parse_pending(char_id)
    if stale_ids then
        local pool = get_pool()
        if pool then
            local expac = pool[stale_ids[1]] and pool[stale_ids[1]].expac or 0
            send_window1(client, stale_ids, pool, stale_level, EXPAC_NAMES[expac] or "Classic")
        end
        return
    end

    local pool = get_pool()
    if not pool then
        client:Message(4, "Spell award system unavailable. Please contact a GM.")
        return
    end

    local max_expac = get_max_expac(char_id)
    local eligible  = {}
    for spell_id, data in pairs(pool) do
        if data.level <= level and data.expac <= max_expac then
            if not client:HasSpellScribed(spell_id) then
                eligible[#eligible + 1] = spell_id
            end
        end
    end

    if #eligible == 0 then
        client:Message(15, "You have learned all available spells at this level.")
        mark_level_awarded(char_id, level)
        return
    end

    local choices = pick_random(eligible, 3)
    eq.set_data(bucket_pending(char_id), table.concat(choices, ",") .. ":" .. level)

    local expac_name = EXPAC_NAMES[max_expac] or "Classic"
    send_window1(client, choices, pool, level, expac_name)
end

-- ---- Public: popup response (button clicks) -------------------------

function M.on_popup_response(client, popup_id)
    local char_id = client:CharacterID()

    -- Player passed on their only option
    if popup_id == SA_PASS then
        local _, level_str = parse_pending(char_id)
        if level_str then mark_level_awarded(char_id, level_str) end
        eq.delete_data(bucket_pending(char_id))
        return true
    end

    -- Player wants to see spells 2 & 3
    if popup_id == SA_MORE then
        local ids, level_num = parse_pending(char_id)
        if ids and #ids >= 3 then
            local pool = get_pool()
            if pool then send_window2(client, ids, pool, level_num) end
        end
        return true
    end

    -- Spell choice
    local choice_index = ({ [SA_PICK1]=1, [SA_PICK2]=2, [SA_PICK3]=3 })[popup_id]
    if not choice_index then return false end

    local ids, level_num = parse_pending(char_id)
    if not ids then return false end

    local spell_id = ids[choice_index]
    if not spell_id then
        client:Message(4, "Invalid spell choice. Please contact a GM.")
        return true
    end

    if award_spell(client, spell_id) then
        mark_level_awarded(char_id, level_num)
        eq.delete_data(bucket_pending(char_id))
        client:Message(15, "Spell award recorded. Congratulations!")
    else
        client:Message(4, "Something went wrong. Please try again or contact a GM.")
    end
    return true
end

-- ---- Public: say fallback (kept for backwards compatibility) --------

function M.on_say(client, message)
    local char_id = client:CharacterID()
    local choice  = message:match("^%s*([123])%s*$")
    if not choice then return false end

    local ids, level_num = parse_pending(char_id)
    if not ids then return false end

    local spell_id = ids[tonumber(choice)]
    if not spell_id then
        client:Message(4, "Invalid choice.")
        return true
    end

    if award_spell(client, spell_id) then
        mark_level_awarded(char_id, level_num)
        eq.delete_data(bucket_pending(char_id))
        client:Message(15, "Spell award recorded. Congratulations!")
    else
        client:Message(4, "Something went wrong. Please try again or contact a GM.")
    end
    return true
end

return M
