-- =============================================================================
-- 990230.lua - Archivist Kaelis, Tower of Infinity agent (Bazaar)
--
-- Features:
--   * Recommends the next Tower difficulty from character progression bucket.
--   * Creates a random Lost Dungeons of Norrath style expedition instance.
--   * Sends group/raid members into the created dynamic zone.
-- =============================================================================

local TOWER_PREFIX = "Tower of Infinity"
local PROGRESSION_BUCKET = "toi_highest_completed"
local TOWER_MAX_LEVEL = 75
local EXPEDITION_MIN = 1
local EXPEDITION_MAX = 72
local EXPEDITION_DURATION = eq.seconds("6h")
local EXPEDITION_REPLAY = eq.seconds("2h")

local LDON_POOL = {
    { zone = "guka", label = "Deepest Guk: Cauldron of Lost Souls", versions = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 } },
    { zone = "ruja", label = "The Rujarkian Hills: Bloodied Quarries", versions = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 } },
    { zone = "taka", label = "Takish-Hiz: Sunken Library", versions = { 2, 3, 4, 5, 6, 7, 8, 9, 10 } },
    { zone = "mira", label = "Miragul's Menagerie: Silent Gallery", versions = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 } },
    { zone = "mmca", label = "Mistmoore's Catacombs: Forlorn Caverns", versions = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 } }
}

local CLASSIC_OBJECTIVE_POOL = {
    { zone = "soldunga", label = "Solusek's Eye (SolA)" },
    { zone = "crushbone", label = "Crushbone" },
    { zone = "blackburrow", label = "Blackburrow" },
    { zone = "befallen", label = "Befallen" },
    { zone = "najena", label = "Najena" }
}

local ENTRY_COORDS = {
    guka = { x = 101, y = -841, z = 1, h = 0 },
    ruja = { x = 805, y = -123, z = -95, h = 0 },
    taka = { x = -77, y = 493, z = 3, h = 0 },
    mira = { x = 649, y = 564, z = -89, h = 0 },
    mmca = { x = -594, y = -365, z = 6, h = 0 },
    soldunga = { x = -486, y = -476, z = 73, h = 0 },
    crushbone = { x = 158, y = -644, z = 4, h = 0 },
    blackburrow = { x = 39, y = -159, z = 3, h = 0 },
    befallen = { x = 35, y = -82, z = 3, h = 0 },
    najena = { x = 858, y = -76, z = 4, h = 0 }
}

local function send_tell(client, text)
    local tell_type = (MT and MT.Tell) or (MT and MT.NPCQuestSay) or 15
    client:Message(tell_type, "Archivist Kaelis tells you, '" .. text .. "'")
end

local function tower_name_for_level(level)
    return string.format("%s - L%d", TOWER_PREFIX, level)
end

local function is_tower_expedition_name(name)
    return string.sub(name or "", 1, #TOWER_PREFIX) == TOWER_PREFIX
end

local function get_highest_completed(client)
    local value = tonumber(client:GetBucket(PROGRESSION_BUCKET) or "") or 0
    if value < 0 then
        value = 0
    end
    return value
end

local function get_recommended_level(client)
    return get_highest_completed(client) + 1
end

local function get_max_queue_level(client)
    local max_unlocked = get_highest_completed(client) + 1
    if max_unlocked < 1 then
        max_unlocked = 1
    end

    if max_unlocked > TOWER_MAX_LEVEL then
        max_unlocked = TOWER_MAX_LEVEL
    end

    return max_unlocked
end

local function get_run_mode(level)
    if level <= 50 then
        return "kill_count"
    end

    return "objective"
end

local function get_zone_pool(level)
    if level <= 50 then
        return LDON_POOL
    end

    return CLASSIC_OBJECTIVE_POOL
end

local function say_intro(client)
    local highest = get_highest_completed(client)
    local recommended = get_recommended_level(client)
    local max_unlocked = get_max_queue_level(client)

    send_tell(client,
        "Hail, " .. client:GetName() .. ". I am Archivist Kaelis, keeper of the Tower of Infinity records. "
        .. "Within that endless tower, each ascent bends space into a different Lost Dungeon and tests your last known limit.")

    if highest == 0 then
        send_tell(client,
            "You have no completed tower records yet. I recommend beginning at "
            .. eq.say_link("tower queue", false, "difficulty 1") .. ".")
    elseif highest >= TOWER_MAX_LEVEL then
        send_tell(client,
            string.format(
                "Your highest completed Tower difficulty is %d. You have reached the current maximum tier.",
                highest
            ))
    else
        send_tell(client,
            string.format(
                "Your highest completed Tower difficulty is %d. I recommend %s next.",
                highest,
                eq.say_link("tower queue", false, "difficulty " .. recommended)
            ))
    end

    send_tell(client,
        "Say " .. eq.say_link("tower status", false, "tower status")
        .. " to review your progression, or "
        .. eq.say_link("tower queue", false, "tower queue") .. " to begin.")

    send_tell(client,
        string.format(
            "You may queue any tower difficulty from 1 through %d. Say 'tower queue 10' to request a specific lower floor.",
            max_unlocked
        ))
end

local function say_status(client)
    local highest = get_highest_completed(client)
    local recommended = get_recommended_level(client)
    local max_unlocked = get_max_queue_level(client)
    local aug_bonus = math.floor((math.max(highest, 1) - 1) / 10) + 1
    local mode = get_run_mode(recommended)

    local mode_text = "Kill-count growth (LDoN floors)."
    if mode == "objective" then
        mode_text = "Objective or boss kill growth (classic dungeon floors)."
    end

    if highest >= TOWER_MAX_LEVEL then
        send_tell(client,
            string.format(
                "Tower record: highest completed difficulty %d. You are at the current maximum unlocked tier.",
                highest
            ))
    else
        send_tell(client,
            string.format(
                "Tower record: highest completed difficulty %d. Recommended next run: difficulty %d.",
                highest,
                recommended
            ))
    end

    send_tell(client,
        string.format(
            "Queue access: you may request any difficulty from 1 to %d.",
            max_unlocked
        ))

    send_tell(client,
        string.format(
            "Your current Epic augmentation tier target is +%d to all stats (rises by +1 every 10 completed levels).",
            aug_bonus
        ))

    send_tell(client, "Recommended mode: " .. mode_text)
end

local function say_queue_ranges(client)
    local max_unlocked = get_max_queue_level(client)
    local range_defs = {
        { 1, 10 },
        { 11, 20 },
        { 21, 30 },
        { 31, 40 },
        { 41, 50 },
        { 51, 60 },
        { 61, 70 },
        { 71, 75 }
    }

    local links = {}
    for _, range_def in ipairs(range_defs) do
        local start_level = range_def[1]
        local end_level = math.min(range_def[2], max_unlocked)

        if start_level <= max_unlocked then
            local token = string.format("tower menu %d %d", start_level, end_level)
            local label = string.format("%d-%d", start_level, end_level)
            table.insert(links, eq.say_link(token, false, label))
        end
    end

    if #links == 0 then
        send_tell(client, "No queue ranges are unlocked yet.")
        return
    end

    send_tell(client, "Choose a Tower difficulty range: " .. table.concat(links, "  "))
end

local function say_queue_levels(client, start_level, end_level)
    local max_unlocked = get_max_queue_level(client)

    if start_level < 1 then
        start_level = 1
    end

    if end_level > max_unlocked then
        end_level = max_unlocked
    end

    if start_level > end_level then
        send_tell(client, "That range is not currently unlocked.")
        return
    end

    local links = {}
    for level = start_level, end_level do
        table.insert(links, eq.say_link("tower queue " .. level, false, tostring(level)))
    end

    send_tell(client,
        string.format(
            "Choose a specific difficulty in %d-%d: %s",
            start_level,
            end_level,
            table.concat(links, " ")
        ))
end

local function collect_members(client)
    local members = {}
    local seen = {}

    local function push_member(member)
        if member and member.valid and member:IsClient() then
            local id = member:GetID()
            if not seen[id] then
                seen[id] = true
                table.insert(members, member)
            end
        end
    end

    local raid = client:GetRaid()
    if raid then
        for i = 0, raid:RaidCount() - 1 do
            push_member(raid:GetMember(i))
        end
    else
        local group = client:GetGroup()
        if group then
            for i = 0, group:GroupCount() - 1 do
                push_member(group:GetMember(i))
            end
        else
            push_member(client)
        end
    end

    if #members == 0 then
        push_member(client)
    end

    return members
end

local function try_create_random_tower_expedition(client, level)
    local pool = get_zone_pool(level)
    local start = math.random(1, #pool)

    for offset = 0, #pool - 1 do
        local idx = ((start + offset - 1) % #pool) + 1
        local choice = pool[idx]
        local version = 0
        if choice.versions and #choice.versions > 0 then
            version = choice.versions[math.random(1, #choice.versions)]
        end

        local expedition_def = {
            expedition = { name = tower_name_for_level(level), min_players = EXPEDITION_MIN, max_players = EXPEDITION_MAX },
            instance = { zone = choice.zone, version = version, duration = EXPEDITION_DURATION }
        }

        local dz = client:CreateExpedition(expedition_def)
        if dz and dz.valid then
            pcall(function() dz:AddReplayLockout(EXPEDITION_REPLAY) end)
            return dz, choice
        end
    end

    return nil, nil
end

local function queue_tower_run(client, requested_difficulty)
    if not eq.is_lost_dungeons_of_norrath_enabled() then
        send_tell(client, "The Wayfarers report that Lost Dungeons are currently unavailable.")
        return
    end

    local existing_dz = client:GetExpedition()
    if existing_dz and existing_dz.valid then
        local existing_name = tostring(existing_dz:GetName() or "")
        if is_tower_expedition_name(existing_name) then
            send_tell(client, "You already have an active Tower of Infinity expedition. Sending you back in now.")
            client:MoveZoneInstance(existing_dz:GetInstanceID())
            return
        end

        send_tell(client,
            "You are already bound to a different expedition: " .. existing_name
            .. ". Leave it before requesting a Tower run.")
        return
    end

    local max_unlocked = get_max_queue_level(client)
    local difficulty = get_recommended_level(client)

    if difficulty > max_unlocked then
        difficulty = max_unlocked
    end

    if requested_difficulty then
        if requested_difficulty < 1 or requested_difficulty > max_unlocked then
            send_tell(client,
                string.format(
                    "You may only queue difficulties from 1 to %d based on your progression.",
                    max_unlocked
                ))
            return
        end

        difficulty = requested_difficulty
    end

    local mode = get_run_mode(difficulty)
    local dz, choice = try_create_random_tower_expedition(client, difficulty)
    if not dz then
        send_tell(client,
            "I could not establish a Tower instance at this moment. Lockouts or adventure availability may be blocking creation.")
        return
    end

    local entry = ENTRY_COORDS[choice.zone] or { x = 0, y = 0, z = 0, h = 0 }
    local members = collect_members(client)

    for _, member in ipairs(members) do
        pcall(function() dz:AddMember(member) end)
    end

    for _, member in ipairs(members) do
        member:MoveZoneInstance(dz:GetInstanceID(), entry.x, entry.y, entry.z, entry.h)
    end

    if mode == "kill_count" then
        send_tell(client,
            string.format(
                "The tower aligns to %s at difficulty %d. This floor advances through kill-count pressure.",
                choice.label,
                difficulty
            ))
    else
        send_tell(client,
            string.format(
                "The tower aligns to %s at difficulty %d. This floor advances through objective and boss kills.",
                choice.label,
                difficulty
            ))
        send_tell(client,
            "Objective floors use custom tower targets, so factioned zone mobs are optional and not required for completion.")
    end
end

function event_say(e)
    local msg = e.message:lower()
    local requested_difficulty = tonumber(msg:match("^tower queue%s+(%d+)$"))
        or tonumber(msg:match("^queue%s+(%d+)$"))
        or tonumber(msg:match("^difficulty%s+(%d+)$"))
    local range_start, range_end = msg:match("^tower menu%s+(%d+)%s+(%d+)$")

    if msg:find("tower status") or msg:find("status") then
        say_status(e.other)
        return
    end

    if range_start and range_end then
        say_queue_levels(e.other, tonumber(range_start), tonumber(range_end))
        return
    end

    if requested_difficulty then
        queue_tower_run(e.other, requested_difficulty)
        return
    end

    if msg:match("^tower queue$") or msg:match("^queue$") then
        say_queue_ranges(e.other)
        return
    end

    if msg:find("begin") or msg:find("start") then
        queue_tower_run(e.other, nil)
        return
    end

    if msg:find("hail") or msg:find("kaelis") then
        say_intro(e.other)
        return
    end
end

function event_trade(e)
    local item_lib = require("items")
    item_lib.return_items(e.self, e.other, e.trade)
end
