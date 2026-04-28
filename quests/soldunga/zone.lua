-- =============================================================================
-- Tower of Infinity classic objective controller
-- Used in classic objective phase zones (51-75): soldunga, crushbone,
-- blackburrow, befallen, najena.
-- =============================================================================

local TOWER_PREFIX = "Tower of Infinity - L"
local PROGRESSION_BUCKET = "toi_highest_completed"

local AUGMENT_BASE_ID = 610100
local AUGMENT_MAX_TIER = 50
local OBJECTIVE_TASK_IDS = {
    [17029] = 990075,
    [17050] = 990076,
    [17049] = 990077,
    [17048] = 990078,
    [17051] = 990079,
}
local current_objective_task_id = nil

local OBJECTIVE_BOSS_POOL = {
    { id = 17029, label = "Lord Elgnub" },
    { id = 17050, label = "Mannan of the Sabertooth" },
    { id = 17049, label = "Master Brewer" },
    { id = 17048, label = "Socho Darkpaw" },
    { id = 17051, label = "Tranixx Darkpaw" }
}

local RETURN_ZONE = "bazaar"
local RETURN_X, RETURN_Y, RETURN_Z, RETURN_H = -48, -776, 4.25, 256

local difficulty = 1
local hp_multiplier = 1.0
local damage_multiplier = 1.0

local mode = "kill_count"
local kills_needed = 40
local kill_count = 0

local objectives_needed = 1
local objectives_killed = 0
local objectives_spawned = false
local required_objective_ids = {}

local instance_initialized = false
local instance_complete = false

local function format_required_objectives()
    local labels = {}
    for _, entry in ipairs(OBJECTIVE_BOSS_POOL) do
        if required_objective_ids[entry.id] then
            table.insert(labels, entry.label)
        end
    end

    if #labels == 0 then
        return "unknown objectives"
    end

    return table.concat(labels, ", ")
end

local function zone_announce(message, color)
    local list = eq.get_entity_list()
    if not list then return end

    local clients = list:GetClientList()
    if not clients then return end

    for c in clients.entries do
        if c and c.valid then
            c:Message(color or 15, message)
        end
    end
end

local function parse_tower_level(expedition_name)
    local level = tonumber(string.match(expedition_name or "", "Tower of Infinity %- L(%d+)")) or 1
    if level < 1 then
        level = 1
    end
    return level
end

local function compute_scaling_profile(client, requested_difficulty)
    local difficulty_value = math.max(1, tonumber(requested_difficulty) or 1)
    local player_level = 1
    local highest_cleared = 0

    if client and client.valid and client:IsClient() then
        player_level = math.max(1, tonumber(client:GetLevel() or 1) or 1)
        highest_cleared = math.max(0, tonumber(client:GetBucket(PROGRESSION_BUCKET) or "") or 0)
    end

    local progression_anchor = math.min(highest_cleared, difficulty_value)
    local mastery_gap = math.max(highest_cleared - difficulty_value, 0)
    local level_pressure = math.max(player_level - 10, 0)

    local hp_mult = 1.0
        + (0.010 * (difficulty_value ^ 1.30))
        + (0.006 * (progression_anchor ^ 1.20))
        + (0.003 * (level_pressure ^ 1.12))
        - (0.0025 * (mastery_gap ^ 1.10))

    local dmg_mult = 1.0
        + (0.006 * (difficulty_value ^ 1.22))
        + (0.0035 * (progression_anchor ^ 1.15))
        + (0.0020 * (level_pressure ^ 1.08))
        - (0.0015 * (mastery_gap ^ 1.08))

    if hp_mult < 1.0 then hp_mult = 1.0 end
    if dmg_mult < 1.0 then dmg_mult = 1.0 end

    return hp_mult, dmg_mult
end

local function is_tower_expedition(client)
    if not client or not client.valid or not client:IsClient() then
        return false
    end

    local dz = client:GetExpedition()
    if not dz or not dz.valid then
        return false
    end

    local name = tostring(dz:GetName() or "")
    return string.sub(name, 1, #TOWER_PREFIX) == TOWER_PREFIX, name
end

local function popup_tower_clients(title, text)
    local list = eq.get_entity_list()
    if not list then
        return
    end

    local clients = list:GetClientList()
    if not clients then
        return
    end

    for c in clients.entries do
        if c and c.valid and c:IsClient() then
            local in_tower = is_tower_expedition(c)
            if in_tower then
                c:Popup(title, text)
            end
        end
    end
end

local function assign_objective_task_to_clients()
    local list = eq.get_entity_list()
    if not list then
        return
    end

    local clients = list:GetClientList()
    if not clients then
        return
    end

    for c in clients.entries do
        if c and c.valid and c:IsClient() then
            local in_tower = is_tower_expedition(c)
            if in_tower then
                if current_objective_task_id and c:IsTaskActive(current_objective_task_id) then
                    c:FailTask(current_objective_task_id)
                end

                if current_objective_task_id then
                    c:AssignTask(current_objective_task_id)
                end
            end
        end
    end
end

local function update_objective_task_progress(progress_count)
    local list = eq.get_entity_list()
    if not list then
        return
    end

    local clients = list:GetClientList()
    if not clients then
        return
    end

    for c in clients.entries do
        if c and c.valid and c:IsClient() then
            local in_tower = is_tower_expedition(c)
            if in_tower and current_objective_task_id and c:IsTaskActive(current_objective_task_id) then
                c:UpdateTaskActivity(current_objective_task_id, 0, progress_count)
            end
        end
    end
end

local function get_credit_client(mob)
    if not mob or not mob.valid then
        return nil
    end

    if mob:IsClient() then
        return mob
    end

    local owner = mob:GetOwner()
    if owner and owner.valid and owner:IsClient() then
        return owner
    end

    return nil
end

local function get_aug_bonus_for_level(level)
    local bonus = math.floor((math.max(level, 1) - 1) / 10) + 1
    if bonus > AUGMENT_MAX_TIER then
        bonus = AUGMENT_MAX_TIER
    end
    return bonus
end

local function remove_existing_tower_augments(client)
    for offset = 0, AUGMENT_MAX_TIER - 1 do
        local item_id = AUGMENT_BASE_ID + offset
        local count = tonumber(client:CountItem(item_id) or 0)
        if count > 0 then
            client:RemoveItem(item_id, count)
        end
    end
end

local function reward_and_advance_clients()
    local list = eq.get_entity_list()
    if not list then return end

    local clients = list:GetClientList()
    if not clients then return end

    for c in clients.entries do
        if c and c.valid and c:IsClient() then
            local in_tower = is_tower_expedition(c)
            if in_tower then
                local highest = tonumber(c:GetBucket(PROGRESSION_BUCKET) or "") or 0
                if difficulty > highest then
                    highest = difficulty
                    c:SetBucket(PROGRESSION_BUCKET, tostring(highest))
                end

                local next_level = highest + 1
                local bonus = get_aug_bonus_for_level(highest)
                local augment_id = AUGMENT_BASE_ID + bonus - 1

                remove_existing_tower_augments(c)
                c:SummonItem(augment_id, 1)

                c:Message(15,
                    string.format(
                        "Tower complete. Highest difficulty recorded: %d. Recommended next difficulty: %d.",
                        highest,
                        next_level
                    ))

                c:Message(15,
                    string.format(
                        "You receive an Epic augmentation at tier +%d to all stats.",
                        bonus
                    ))
            end
        end
    end
end

local function complete_instance()
    if instance_complete then
        return
    end

    instance_complete = true
    reward_and_advance_clients()

    zone_announce(
        "[TOWER] The floor shatters behind you as the trial is conquered. You will be returned to the Bazaar in 60 seconds.",
        15
    )

    eq.start_zone_timer("tower_return", 60000)
end

local function apply_scaled_damage_and_hp(npc)
    local floor_hp = 5000 + (difficulty * 4000)
    local floor_min_hit = 20 + (difficulty * 15)
    local floor_max_hit = 40 + (difficulty * 25)

    local base_max_hp = tonumber(npc:GetMaxHP() or 0)
    local scaled_hp = math.max(1, math.floor(base_max_hp * hp_multiplier), floor_hp)
    npc:ModifyNPCStat("max_hp", tostring(scaled_hp))
    npc:SetHP(scaled_hp)

    local base_min_hit = tonumber(npc:GetMinDMG() or 0)
    local base_max_hit = tonumber(npc:GetMaxDMG() or 0)
    local scaled_min_hit = math.max(1, math.floor(base_min_hit * damage_multiplier), floor_min_hit)
    local scaled_max_hit = math.max(1, math.floor(base_max_hit * damage_multiplier), floor_max_hit)

    npc:ModifyNPCStat("min_hit", tostring(scaled_min_hit))
    npc:ModifyNPCStat("max_hit", tostring(scaled_max_hit))
    npc:ModifyNPCStat("level", tostring(difficulty))
end

local function apply_scaling_to_spawned_npc(npc)
    if not npc or not npc.valid then
        return
    end

    if mode == "objective" then
        npc:ModifyNPCStat("loottable_id", "0")

        if required_objective_ids[npc:GetNPCTypeID()] then
            npc:SetNPCFactionID(0)
        end
    end

    apply_scaled_damage_and_hp(npc)
end

local function apply_scaling_to_existing_npcs()
    local list = eq.get_entity_list()
    if not list then
        return
    end

    local npcs = list:GetNPCList()
    if not npcs then
        return
    end

    for npc in npcs.entries do
        apply_scaling_to_spawned_npc(npc)
    end
end

local function spawn_objective_bosses(anchor_client)
    if objectives_spawned then
        return
    end

    -- Build set of boss IDs so we don't pick them as hosts
    local boss_ids = {}
    for _, entry in ipairs(OBJECTIVE_BOSS_POOL) do
        boss_ids[entry.id] = true
    end

    -- Collect all living native NPCs as candidate spawn slots
    local candidates = {}
    local elist = eq.get_entity_list()
    if elist then
        local npcs = elist:GetNPCList()
        if npcs then
            for npc in npcs.entries do
                if npc and npc.valid and not boss_ids[npc:GetNPCTypeID()] then
                    table.insert(candidates, npc)
                end
            end
        end
    end

    local shuffled = {}
    for i = 1, #OBJECTIVE_BOSS_POOL do
        shuffled[i] = OBJECTIVE_BOSS_POOL[i]
    end

    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    required_objective_ids = {}

    for i = 1, objectives_needed do
        local objective = shuffled[i]
        required_objective_ids[objective.id] = true
        current_objective_task_id = OBJECTIVE_TASK_IDS[objective.id]

        local ox, oy, oz, oh
        if #candidates > 0 then
            local ci = math.random(1, #candidates)
            local host = candidates[ci]
            table.remove(candidates, ci)
            ox = host:GetX()
            oy = host:GetY()
            oz = host:GetZ()
            oh = host:GetHeading()
            host:Depop(false)
        elseif anchor_client and anchor_client.valid then
            ox = anchor_client:GetX()
            oy = anchor_client:GetY()
            oz = anchor_client:GetZ()
            oh = math.random(0, 511)
        else
            ox, oy, oz, oh = 0, 0, 0, 0
        end

        eq.spawn2(objective.id, 0, 0, ox, oy, oz, oh)
    end

    objectives_spawned = true

    local objective_text = format_required_objectives()

    zone_announce(
        string.format(
            "[TOWER] Objective phase: destroy %d random tower targets. Mission targets this run: %s.",
            objectives_needed,
            objective_text
        ),
        15
    )

    assign_objective_task_to_clients()
    update_objective_task_progress(objectives_killed)
end

local function configure_instance_from_client(client)
    local _, expedition_name = is_tower_expedition(client)
    difficulty = parse_tower_level(expedition_name)

    hp_multiplier, damage_multiplier = compute_scaling_profile(client, difficulty)

    mode = "kill_count"
    if difficulty > 50 then
        mode = "objective"
    end

    kills_needed = 40 + (math.min(difficulty, 50) * 5)
    kill_count = 0

    objectives_needed = 1
    objectives_killed = 0
    objectives_spawned = false
    required_objective_ids = {}

    instance_initialized = true
    instance_complete = false

    if mode == "kill_count" then
        zone_announce(
            string.format(
                "[TOWER] Difficulty %d active. HP x%.2f, Damage x%.2f. Defeat %d foes.",
                difficulty,
                hp_multiplier,
                damage_multiplier,
                kills_needed
            ),
            15
        )
    else
        zone_announce(
            string.format(
                "[TOWER] Difficulty %d active. HP x%.2f, Damage x%.2f. Objective floor engaged.",
                difficulty,
                hp_multiplier,
                damage_multiplier
            ),
            15
        )
        zone_announce(
            string.format(
                "[TOWER] Objective stat floors: HP >= %d, Hit >= %d-%d.",
                5000 + (difficulty * 4000),
                20 + (difficulty * 15),
                40 + (difficulty * 25)
            ),
            15
        )
        spawn_objective_bosses(client)
    end

    apply_scaling_to_existing_npcs()
end

local function try_initialize_from_zone_client()
    if instance_initialized then
        return true
    end

    local list = eq.get_entity_list()
    if not list then
        return false
    end

    local clients = list:GetClientList()
    if not clients then
        return false
    end

    for c in clients.entries do
        if c and c.valid and c:IsClient() then
            local in_tower = is_tower_expedition(c)
            if in_tower then
                configure_instance_from_client(c)
                return instance_initialized
            end
        end
    end

    return false
end

function event_zone_init(e)
    difficulty = 1
    hp_multiplier = 1.0
    damage_multiplier = 1.0

    mode = "kill_count"
    kills_needed = 40
    kill_count = 0

    objectives_needed = 1
    objectives_killed = 0
    objectives_spawned = false
    required_objective_ids = {}

    instance_initialized = false
    instance_complete = false
    current_objective_task_id = nil
end

function event_enter_zone(e)
    if not e.other or not e.other.valid or not e.other:IsClient() then
        return
    end

    local in_tower = is_tower_expedition(e.other)
    if not in_tower then
        return
    end

    if not instance_initialized then
        configure_instance_from_client(e.other)
    elseif mode == "objective" and not objectives_spawned then
        spawn_objective_bosses(e.other)
    end
end

function event_spawn_zone(e)
    if not instance_initialized then
        try_initialize_from_zone_client()
    end

    if not instance_initialized or instance_complete or not e.other or not e.other.valid then
        return
    end

    apply_scaling_to_spawned_npc(e.other)
end

function event_npc_death(e)
    if not instance_initialized then
        try_initialize_from_zone_client()
    end

    if not instance_initialized or instance_complete or not e.killed then
        return
    end

    local credit_client = get_credit_client(e.other)
    if not credit_client then
        return
    end

    local in_tower = is_tower_expedition(credit_client)
    if not in_tower then
        return
    end

    if mode == "objective" then
        if not required_objective_ids[e.killed:GetNPCTypeID()] then
            return
        end

        objectives_killed = objectives_killed + 1

        zone_announce(
            string.format("[TOWER] Objective progress: %d / %d named targets defeated.", objectives_killed, objectives_needed),
            15
        )

        update_objective_task_progress(objectives_killed)

        if objectives_killed >= objectives_needed then
            complete_instance()
        end

        return
    end

    kill_count = kill_count + 1

    if (kill_count % 10) == 0 then
        zone_announce(
            string.format("[TOWER] Progress: %d / %d foes defeated.", kill_count, kills_needed),
            15
        )
    end

    if kill_count >= kills_needed then
        complete_instance()
    end
end

function event_zone_timer(e)
    if e.timer == "tower_return" then
        local list = eq.get_entity_list()
        if list then
            local clients = list:GetClientList()
            if clients then
                for c in clients.entries do
                    local in_tower = is_tower_expedition(c)
                    if in_tower then
                        c:MoveZone(RETURN_ZONE, 0, RETURN_X, RETURN_Y, RETURN_Z, RETURN_H)
                    end
                end
            end
        end
    end
end
