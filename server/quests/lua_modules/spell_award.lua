-- ============================================================
-- spell_award.lua
-- Custom Spell Unlock System for Ascendant EQEmu Server
--
-- Flow:
--   1. Character levels up → info popup + 3 chat saylinks
--   2. Player reads popup (all 3 spells visible at once), closes it
--   3. Player clicks a saylink in chat → event_say → spell scribed
--
-- Popup ID:
--   SA_INFO (1000) = OK-only dismiss, no spell action
-- ============================================================

local M = {}

local SA_INFO = 1000

local _pool = nil
local function get_pool()
    if not _pool then
        local ok, mod = pcall(require, "spell_pool")
        if not ok or not mod or not mod.pool then return nil end
        _pool = mod.pool
    end
    return _pool
end

-- ---- Expansion display ------------------------------------------

local EXPAC_NAMES  = { [0]="Classic", [1]="Kunark", [2]="Velious", [3]="Luclin+" }
local EXPAC_COLORS = { [0]="#999999", [1]="#66BB44", [2]="#4499CC", [3]="#AA55CC" }

-- ---- Type color based on description ----------------------------

local function type_color(desc)
    if not desc then return "#AAAAAA" end
    if desc:find("DD") or desc:find("Damage") then return "#FF6633" end
    if desc:find("Heal") or desc:find("Regen")  then return "#44EE44" end
    if desc:find("Haste") or desc:find("Buff") or desc:find("AC")
        or desc:find("STR") or desc:find("STA") or desc:find("Speed")
        or desc:find("Rune") or desc:find("Invis") then return "#CCFF33" end
    if desc:find("Snare") or desc:find("Root") or desc:find("Fear")
        or desc:find("Stun") or desc:find("Calm") then return "#FF44FF" end
    if desc:find("Mana") then return "#44AAFF" end
    return "#AAAAAA"
end

-- ---- Expansion unlock -------------------------------------------

local function get_max_expac(char_id)
    local k = tostring(char_id)
    if eq.get_data("velious_awarded_" .. k) ~= "" then return 3 end
    if eq.get_data("kunark_awarded_"  .. k) ~= "" then return 2 end
    if eq.get_data("classic_awarded_" .. k) ~= "" then return 1 end
    return 0
end

-- ---- Data bucket helpers ----------------------------------------

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

-- ---- Random pick (Fisher-Yates partial) -------------------------

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

-- ---- Award spell ------------------------------------------------

local function award_spell(client, spell_id)
    local pool  = get_pool()
    local entry = pool and pool[spell_id]
    if not entry then return false end
    local slot = client:GetNextAvailableSpellBookSlot()
    if slot < 0 then
        client:Message(4, "Your spellbook is full! Free a slot and contact a GM.")
        return false
    end
    client:ScribeSpell(spell_id, slot, true)
    client:Message(13, string.format("'%s' has been inscribed into your spellbook.", entry.name))
    return true
end

-- ---- Popup / chat helpers ---------------------------------------

-- Strip chars that trigger special processing in DialogueWindow
local function dw_safe(s)
    if not s then return "" end
    return s:gsub("[~%+=%[%]%{%}]", "")
end

-- One spell block for the popup body
local function spell_block(pool, spell_id, num)
    local e = pool[spell_id]
    if not e then return "" end
    local ec = EXPAC_COLORS[e.expac] or "#999999"
    local en = EXPAC_NAMES[e.expac]  or "Classic"
    local tc = type_color(e.desc)
    local nm = dw_safe(e.name)
    local ds = dw_safe(e.desc or "")
    local mn = (e.mana and e.mana > 0) and ("  Mana:" .. e.mana) or ""
    local ct = (e.cast_ms and e.cast_ms > 0)
        and string.format("  Cast:%.1fs", e.cast_ms / 1000)
        or  ""
    return string.format(
        '<c "#FFCC44">-- %d -----------------------------------------------</c><br>'
        .. '<c "%s">* </c><c "#FFFFFF">%s</c>   <c "%s">%s</c><br>'
        .. '<c "#888888">%s%s%s</c><br>',
        num,
        tc, nm,
        ec, en,
        ds, mn, ct
    )
end

-- Show all choices in a single info popup (OK-only, no spell action)
local function send_info_popup(client, choices, pool, level)
    local body = ""
    for i = 1, #choices do
        body = body .. spell_block(pool, choices[i], i)
    end
    body = body .. '<c "#F07F00">Click your choice in the chat window below.</c>'
    client:DialogueWindow(string.format(
        "{title:Spell Award - Level %d}popupid:%d hiddenresponse noquotes%s",
        level, SA_INFO, body
    ))
end

-- Send chat saylinks — item icon (from scroll) where available, then saylink
local function send_choice_chat(client, choices, pool)
    client:Message(MT.LightBlue, "===== SPELL AWARD  -  Click to Choose =====")
    for i, spell_id in ipairs(choices) do
        local e = pool[spell_id]
        if not e then goto continue end
        local link = eq.say_link(
            tostring(i), false,
            string.format("  [%d: %s]  ", i, e.name)
        )
        local icon = (e.scroll_id and e.scroll_id > 0)
            and (eq.item_link(e.scroll_id) .. "  ")
            or  ""
        client:Message(MT.White, icon .. link)
        ::continue::
    end
    local pass_link = eq.say_link("pass", false, "  [Pass - No Spell This Level]  ")
    client:Message(MT.Gray, pass_link)
    client:Message(MT.LightBlue, "===========================================")
end

-- ---- Public: level-up -------------------------------------------

function M.on_level_up(client)
    local char_id = client:CharacterID()
    local level   = client:GetLevel()

    if level_already_awarded(char_id, level) then return end

    -- Re-show any pending unanswered offer
    local stale_ids, stale_level = parse_pending(char_id)
    if stale_ids then
        local pool = get_pool()
        if pool then
            send_info_popup(client, stale_ids, pool, stale_level)
            send_choice_chat(client, stale_ids, pool)
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

    send_info_popup(client, choices, pool, level)
    send_choice_chat(client, choices, pool)
end

-- ---- Public: popup response -------------------------------------

function M.on_popup_response(client, popup_id)
    if popup_id == SA_INFO then return true end  -- dismiss only
    return false
end

-- ---- Public: say handler (saylink clicks) -----------------------

function M.on_say(client, message)
    local char_id = client:CharacterID()

    if message == "pass" then
        local _, level_num = parse_pending(char_id)
        if level_num then mark_level_awarded(char_id, level_num) end
        eq.delete_data(bucket_pending(char_id))
        client:Message(MT.Gray, "You pass on this level's spell award.")
        return true
    end

    local choice = message:match("^%s*([123])%s*$")
    if not choice then return false end

    local ids, level_num = parse_pending(char_id)
    if not ids then return false end

    local spell_id = ids[tonumber(choice)]
    if not spell_id then
        client:Message(4, "Invalid spell choice. Please contact a GM.")
        return true
    end

    if award_spell(client, spell_id) then
        mark_level_awarded(char_id, level_num)
        eq.delete_data(bucket_pending(char_id))
        client:Message(15, "Spell award complete. Congratulations!")
    else
        client:Message(4, "Something went wrong. Please try again or contact a GM.")
    end
    return true
end

return M
