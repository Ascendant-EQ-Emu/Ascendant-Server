-- ============================================================
-- spell_award.lua
-- Custom Spell Unlock System for Ascendant EQEmu Server
--
-- IMPORTANT: _init() runs at require() time (zone startup),
-- NOT during live events. This avoids compiling the 1.4MB
-- spell_pool.lua mid-event which crashes the zone.
-- ============================================================

local M = {}

local SA_INFO = 1000

-- ---- Rare item pool (manually curated) -------------------------
-- Add item IDs here to include them in the 15% rare offer.
local RARE_ITEMS = {
    [5401]  = { name = "Mithril Two-Handed Sword",        desc = "2H Sword"  },
    [13401] = { name = "Manastone",                       desc = "Legendary" },
    [711621]= { name = "Cloak of Flames (Ascendant)",     desc = "Back"      },
    [705667]= { name = "Earthshaker (Ascendant)",         desc = "2H Blunt"  },
    [711551]= { name = "Shield of the Immaculate (Ascendant)", desc = "Shield" },
    [711601]= { name = "Runed Bolster Belt (Ascendant)",  desc = "Waist"     },
}

-- ---- Module-level init (runs once at zone startup) -------------

local _pool  = nil   -- spell_pool.pool table
local _index = nil   -- _index[expac][level] = { spell_id, ... }

local function _init()
    local ok, mod = pcall(require, "spell_pool")
    if not ok or not mod or not mod.pool then return end
    _pool  = mod.pool
    _index = {}
    for spell_id, data in pairs(_pool) do
        local e = data.expac or 0
        local l = data.level or 1
        if not _index[e] then _index[e] = {} end
        if not _index[e][l] then _index[e][l] = {} end
        local b = _index[e][l]
        b[#b + 1] = spell_id
    end
end

_init()  -- heavy work happens here at zone load, not during events

-- ---- Scribed set (400 book-slot reads, single pass) ------------

local function get_scribed(client)
    local scribed = {}
    for slot = 0, 399 do
        local sid = client:GetSpellIDByBookSlot(slot)
        if sid and sid > 0 and sid < 60000 then
            scribed[sid] = true
        end
    end
    return scribed
end

-- ---- Eligible list from pre-built index ------------------------

local function is_excluded(data)
    -- effectid1=32 = SPA_SUMMON_ITEM: covers item summons (Summon Food, Summon Arrow,
    -- Enchant Silver, etc.) while leaving pet summons (33), undead pets (71),
    -- and summon corpse (91) untouched.
    if (data.effectid1 or 0) == 32 then return true end
    if (data.desc or ""):find("Illusion") then return true end
    return false
end

local function get_eligible(level, max_expac, scribed)
    if not _index then return {} end
    local eligible = {}
    for expac = 0, max_expac do
        local eb = _index[expac]
        if eb then
            for lv = 1, level + 5 do
                local lb = eb[lv]
                if lb then
                    for _, spell_id in ipairs(lb) do
                        local data = _pool[spell_id]
                        if data and not scribed[spell_id] and not is_excluded(data) then
                            eligible[#eligible + 1] = spell_id
                        end
                    end
                end
            end
        end
    end
    return eligible
end

-- ---- Expansion display -----------------------------------------

local EXPAC_NAMES  = { [0]="Classic", [1]="Kunark", [2]="Velious", [3]="Luclin+" }
local EXPAC_COLORS = { [0]="#999999", [1]="#66BB44", [2]="#4499CC", [3]="#AA55CC" }

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

-- ---- Expansion unlock ------------------------------------------

local function get_max_expac(char_id)
    local k = tostring(char_id)
    if eq.get_data("velious_awarded_" .. k) ~= "" then return 3 end
    if eq.get_data("kunark_awarded_"  .. k) ~= "" then return 2 end
    if eq.get_data("classic_awarded_" .. k) ~= "" then return 1 end
    return 0
end

-- ---- Data bucket helpers ---------------------------------------

local function bucket_done(char_id)    return "sa_done:"    .. char_id end
local function bucket_pending(char_id) return "sa_pending:" .. char_id end
local function bucket_rare(char_id)    return "sa_rare:"    .. char_id end

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
    for s in spell_part:gmatch("%d+") do ids[#ids + 1] = tonumber(s) end
    return ids, tonumber(level_str)
end

local function get_pending_rare(char_id)
    local raw = eq.get_data(bucket_rare(char_id))
    return (raw and raw ~= "") and tonumber(raw) or nil
end

local function clear_pending(char_id)
    eq.delete_data(bucket_pending(char_id))
    eq.delete_data(bucket_rare(char_id))
end

-- ---- Random pick (Fisher-Yates partial) ------------------------

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

-- ---- Award spell -----------------------------------------------

local function award_spell(client, spell_id)
    local entry = _pool and _pool[spell_id]
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

-- ---- Popup / chat helpers --------------------------------------

local function dw_safe(s)
    if not s then return "" end
    return s:gsub("[~%+=%[%]%{%}]", "")
end

local function spell_block(spell_id, num)
    local e = _pool and _pool[spell_id]
    if not e then return "" end
    local ec = EXPAC_COLORS[e.expac] or "#999999"
    local en = EXPAC_NAMES[e.expac]  or "Classic"
    local tc = type_color(e.desc)
    local nm = dw_safe(e.name)
    local ds = dw_safe(e.desc or "")
    local mn = (e.mana and e.mana > 0) and ("  Mana:" .. e.mana) or ""
    local ct = (e.cast_ms and e.cast_ms > 0)
        and string.format("  Cast:%.1fs", e.cast_ms / 1000) or ""
    return string.format(
        '<c "#FFCC44">-- %d ------------------------------------------</c><br>'
        .. '<c "%s">%s</c> - <c "#AAAAAA">Level %d</c> - <c "%s">%s</c><br>'
        .. '<c "#888888">%s%s%s</c><br>',
        num,
        tc, nm,
        e.level or 1,
        ec, en,
        ds, mn, ct
    )
end

local function send_info_popup(client, choices, rare_item_id, level)
    local body = ""
    for i = 1, #choices do
        body = body .. spell_block(choices[i], i)
    end
    if rare_item_id then
        local entry = RARE_ITEMS[rare_item_id]
        if entry then
            body = body .. string.format(
                '<c "#FFCC44">-- %d ------------------------------------------</c><br>'
                .. '<c "#FFD700">%s</c><br>'
                .. '<c "#888888">Rare Item</c><br>',
                #choices + 1,
                dw_safe(entry.name)
            )
        end
    end
    body = body .. '<c "#F07F00">Click your choice in the chat window below.</c>'
    client:DialogueWindow(string.format(
        "{title:Spell Award - Level %d}popupid:%d hiddenresponse noquotes%s",
        level, SA_INFO, body
    ))
end

local function send_choice_chat(client, choices, rare_item_id)
    client:Message(MT.LightBlue, "===== REWARD AVAILABLE  -  Click to Choose =====")
    for i, spell_id in ipairs(choices) do
        local e = _pool and _pool[spell_id]
        if e then
            local pick_link = eq.say_link(tostring(i), false,
                string.format("[%d: %s]", i, e.name))
            local scroll_link = (e.scroll_id and e.scroll_id > 0)
                and ("   " .. eq.item_link(e.scroll_id)) or ""
            client:Message(MT.White, pick_link .. scroll_link)
        end
    end
    if rare_item_id then
        local entry = RARE_ITEMS[rare_item_id]
        if entry then
            local slot = #choices + 1
            local pick_link = eq.say_link(tostring(slot), false,
                string.format("[%d: %s]", slot, entry.name))
            -- item_link lets the player right-click to inspect the item
            client:Message(MT.Yellow, pick_link .. "   " .. eq.item_link(rare_item_id))
        end
    end
    local pass_link = eq.say_link("pass", false, "[Pass - No Reward This Level]")
    client:Message(MT.Gray, pass_link)
    client:Message(MT.LightBlue, "================================================")
end

-- ---- Public: level-up ------------------------------------------

function M.on_level_up(client)
    if not _pool then
        client:Message(4, "Spell award system unavailable. Please contact a GM.")
        return
    end

    local char_id = client:CharacterID()
    local level   = client:GetLevel()

    if level_already_awarded(char_id, level) then return end

    local stale_ids, stale_level = parse_pending(char_id)
    if stale_ids then
        local stale_rare = get_pending_rare(char_id)
        send_info_popup(client, stale_ids, stale_rare, stale_level)
        send_choice_chat(client, stale_ids, stale_rare)
        return
    end

    local max_expac = get_max_expac(char_id)
    local scribed   = get_scribed(client)
    local eligible  = get_eligible(level, max_expac, scribed)

    if #eligible == 0 then
        client:Message(15, "You have learned all available spells at this level.")
        mark_level_awarded(char_id, level)
        return
    end

    local choices = pick_random(eligible, 3)
    eq.set_data(bucket_pending(char_id), table.concat(choices, ",") .. ":" .. level)

    local rare_item_id = nil
    local force_key = "sa_force_rare:" .. char_id
    local force_rare = eq.get_data(force_key) == "1"
    if force_rare then eq.delete_data(force_key) end

    math.randomseed(os.time() + tonumber(char_id) * 7 + level * 37)
    if force_rare or math.random(100) <= 15 then
        local rare_pool = {}
        for id, _ in pairs(RARE_ITEMS) do rare_pool[#rare_pool + 1] = id end
        if #rare_pool > 0 then
            rare_item_id = rare_pool[math.random(#rare_pool)]
            eq.set_data(bucket_rare(char_id), tostring(rare_item_id))
        end
    end

    send_info_popup(client, choices, rare_item_id, level)
    send_choice_chat(client, choices, rare_item_id)
end

-- ---- Public: popup response ------------------------------------

function M.on_popup_response(client, popup_id)
    if popup_id == SA_INFO then return true end
    return false
end

-- ---- Public: say handler ---------------------------------------

function M.on_say(client, message)
    local char_id = client:CharacterID()

    if message == "pass" then
        local _, level_num = parse_pending(char_id)
        if level_num then mark_level_awarded(char_id, level_num) end
        clear_pending(char_id)
        client:Message(MT.Gray, "You pass on this level's reward.")
        return true
    end

    local choice = tonumber(message:match("^%s*(%d)%s*$"))
    if not choice or choice < 1 then return false end

    local ids, level_num = parse_pending(char_id)
    if not ids then return false end

    -- Rare item slot
    if choice == #ids + 1 then
        local item_id = get_pending_rare(char_id)
        if item_id and RARE_ITEMS[item_id] then
            client:SummonItem(item_id, 1)
            client:Message(MT.Yellow, string.format(
                "'%s' has been placed in your inventory.", RARE_ITEMS[item_id].name))
            mark_level_awarded(char_id, level_num)
            clear_pending(char_id)
        else
            client:Message(4, "Invalid choice. Please contact a GM.")
        end
        return true
    end

    -- Spell slot
    if choice > #ids then
        client:Message(4, "Invalid choice. Please contact a GM.")
        return true
    end

    local spell_id = ids[choice]
    if award_spell(client, spell_id) then
        mark_level_awarded(char_id, level_num)
        clear_pending(char_id)
        client:Message(15, "Spell award complete. Congratulations!")
    else
        client:Message(4, "Something went wrong. Please try again or contact a GM.")
    end
    return true
end

return M
