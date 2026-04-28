-- =============================================================================
-- Tower of Infinity instance controller
-- Zone script used by Tower expedition instances to provide progression logic.
-- =============================================================================

local TOWER_PREFIX = "Tower of Infinity - L"
local PROGRESSION_BUCKET = "toi_highest_completed"

local AUGMENT_BASE_ID = 610100
local AUGMENT_MAX_TIER = 50
local KILL_COUNT_TASK_BASE_ID = 990100
local KILL_COUNT_TASK_MAX_LEVEL = 50

local RETURN_ZONE = "bazaar"
local RETURN_X, RETURN_Y, RETURN_Z, RETURN_H = -48, -776, 4.25, 256

local difficulty = 1
local hp_multiplier = 1.0
local damage_multiplier = 1.0
local kills_needed = 40
local kill_count = 0
local current_kill_task_id = nil
local instance_initialized = false
local instance_complete = false

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

local function clear_all_kill_tasks(client)
    if not client or not client.valid then
        return
    end

    for level = 1, KILL_COUNT_TASK_MAX_LEVEL do
        local task_id = KILL_COUNT_TASK_BASE_ID + (level - 1)
        if client:IsTaskActive(task_id) then
            client:FailTask(task_id)
        end
    end
end

local function assign_kill_task_to_clients()
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
                clear_all_kill_tasks(c)
                if current_kill_task_id then
                    c:AssignTask(current_kill_task_id)
                end
            end
        end
    end
end

local function update_kill_task_progress(progress_count)
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
            if in_tower and current_kill_task_id and c:IsTaskActive(current_kill_task_id) then
                c:UpdateTaskActivity(current_kill_task_id, 0, progress_count)
            end
        end
    end
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

local function configure_instance_from_client(client)
    local _, expedition_name = is_tower_expedition(client)
    difficulty = parse_tower_level(expedition_name)

    hp_multiplier, damage_multiplier = compute_scaling_profile(client, difficulty)
    kills_needed = 40 + (difficulty * 5)
    kill_count = 0
    current_kill_task_id = nil
    if difficulty >= 1 and difficulty <= KILL_COUNT_TASK_MAX_LEVEL then
        current_kill_task_id = KILL_COUNT_TASK_BASE_ID + (difficulty - 1)
    end

    instance_initialized = true
    instance_complete = false

    assign_kill_task_to_clients()
    update_kill_task_progress(0)

    zone_announce(
        string.format(
            "[TOWER] Difficulty %d active. HP x%.2f, Damage x%.2f. Defeat %d foes to conquer this floor.",
            difficulty,
            hp_multiplier,
            damage_multiplier,
            kills_needed
        ),
        15
    )
end

local function apply_spawn_scaling(npc)
    if not instance_initialized or instance_complete then
        return
    end

    if not npc or not npc.valid then
        return
    end

    local base_max_hp = tonumber(npc:GetMaxHP() or 0)
    if base_max_hp > 0 then
        local scaled_hp = math.max(1, math.floor(base_max_hp * hp_multiplier))
        npc:ModifyNPCStat("max_hp", tostring(scaled_hp))
        npc:SetHP(scaled_hp)
    end

    local base_min_hit = tonumber(npc:GetMinDMG() or 0)
    local base_max_hit = tonumber(npc:GetMaxDMG() or 0)

    if base_min_hit > 0 then
        npc:ModifyNPCStat("min_hit", tostring(math.max(1, math.floor(base_min_hit * damage_multiplier))))
    end

    if base_max_hit > 0 then
        npc:ModifyNPCStat("max_hit", tostring(math.max(1, math.floor(base_max_hit * damage_multiplier))))
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

function event_zone_init(e)
    difficulty = 1
    hp_multiplier = 1.0
    damage_multiplier = 1.0
    kills_needed = 40
    kill_count = 0
    current_kill_task_id = nil
    instance_initialized = false
    instance_complete = false
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
    else
        assign_kill_task_to_clients()
        update_kill_task_progress(kill_count)
    end
end

function event_spawn_zone(e)
    if not e.other or not e.other.valid then
        return
    end

    apply_spawn_scaling(e.other)
end

function event_npc_death(e)
    if not instance_initialized or instance_complete then
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

    kill_count = kill_count + 1
    update_kill_task_progress(kill_count)

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
