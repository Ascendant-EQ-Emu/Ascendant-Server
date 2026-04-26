
-- Final Prestige AA override with dynamic max-level rule lookup
local PRESTIGE_AA_ID = 60000
local PRESTIGE_TOKEN_ITEM_ID = 600001
local PRESTIGE_TOKENS_PER_RESET = 10

local spell_award = require("spell_award")

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

function event_say(e)
    spell_award.on_say(e.self, e.message)
end

function event_popup_response(e)
    spell_award.on_popup_response(e.self, e.popup_id)
end

function event_level_up(e)
    spell_award.on_level_up(e.self)

    local free_skills = {0,1,2,3,4,5,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,28,29,30,31,32,33,34,36,37,38,39,41,42,43,44,45,46,47,49,51,52,54,67,70,71,72,73,74,76}

    for k, v in ipairs(free_skills) do
        if e.self:MaxSkill(v) > 0 and e.self:GetRawSkill(v) < 1 and e.self:CanHaveSkill(v) then
            e.self:SetSkill(v, 1)
        end
    end

    if e.self:GetLevel() == 5 then
        eq.popup("", "<c \"#F0F000\">Welcome to level 5.</c><br><br>You have just been granted a new ability called '<c \"#F0F000\">Origin</c>' which allows you to teleport back to your starting city.<br><br>Open the Alternate Advancement window by pressing the '<c \"#F0F000\">V</c>' key, look in the '<c \"#F0F000\">General' tab</c>, and find the '<c \"#F0F000\">Origin</c>' ability and select it.<br><br>Now press the '<c \"#F0F000\">Hotkey</c>' button to create a hotkey you can place on your hot bar.")
    end
end
