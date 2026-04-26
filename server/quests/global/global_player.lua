
-- Final Prestige AA override with dynamic max-level rule lookup
local PRESTIGE_AA_ID = 60000
local PRESTIGE_TOKEN_ITEM_ID = 600001
local PRESTIGE_TOKENS_PER_RESET = 10

local function get_prestige_required_level()
    local result = eq.query("SELECT rule_value FROM rule_values WHERE rule_name = 'Character:MaxLevel' LIMIT 1")

    if result and result.rows and result.rows[1] and result.rows[1].rule_value then
        local parsed = tonumber(result.rows[1].rule_value)
        if parsed and parsed > 0 then
            return parsed
        end
    end

    return 60
end

function event_aa_buy(e)
    if not e or not e.self or not e.aa_id then
        return
    end

    if tonumber(e.aa_id) ~= PRESTIGE_AA_ID then
        return
    end

    local client = e.self
    local current_level = tonumber(client:GetLevel()) or 1
    local aa_cost = tonumber(e.aa_cost) or 0
    local char_id = tonumber(client:CharacterID()) or 0
    local prestige_required_level = get_prestige_required_level()

    if current_level < prestige_required_level then
        if aa_cost > 0 then
            client:AddAAPoints(aa_cost)
        end
        client:Message(MT.Red, 'The Prestige Keeper whispers: only those at max level may walk the path of rebirth.')
        client:Message(MT.White, string.format('You must be level %d to Prestige.', prestige_required_level))
        return
    end

    if aa_cost > 0 then
        client:AddAAPoints(aa_cost)
    end

    client:Message(MT.Yellow, 'You invoke Prestige. Your mortal progress is surrendered, but your true mastery remains.')
    client:UnscribeSpellAll(true)
    client:SetLevel(1)
    client:SummonItem(PRESTIGE_TOKEN_ITEM_ID, PRESTIGE_TOKENS_PER_RESET)

    if char_id > 0 then
        eq.query(string.format(
            'INSERT INTO character_prestige (char_id, prestige_count, last_prestige_unix, last_level_before_reset, last_aa_cost_refunded) ' ..
            'VALUES (%d, 1, UNIX_TIMESTAMP(), %d, %d) ' ..
            'ON DUPLICATE KEY UPDATE prestige_count = prestige_count + 1, last_prestige_unix = UNIX_TIMESTAMP(), last_level_before_reset = VALUES(last_level_before_reset), last_aa_cost_refunded = VALUES(last_aa_cost_refunded)',
            char_id,
            current_level,
            aa_cost
        ))
    end

    client:Message(MT.Yellow, 'You are reborn at level 1 and receive 10 Prestige Tokens. Return them to the Prestige Keeper for power.')
end
