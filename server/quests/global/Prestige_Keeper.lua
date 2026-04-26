local PRESTIGE_TOKEN_ITEM_ID = 600001
local LEGACY_TOKEN_ITEM_ID = 13073
local AA_PER_TOKEN = 10
local PRESTIGE_TOKENS_PER_RESET = 10
local PRESTIGE_REQUIRED_LEVEL = 60
local item_lib = require('items')

local function perform_prestige(client)
    local current_level = tonumber(client:GetLevel()) or 1
    local required_level = PRESTIGE_REQUIRED_LEVEL

    if current_level < required_level then
        client:Message(MT.Red, string.format('You must be level %d to begin Prestige.', required_level))
        return
    end

    client:Message(MT.Yellow, 'You accept the burden of rebirth. Your path begins anew.')
    client:UnscribeSpellAll(true)
    client:SetLevel(1)
    client:SummonItem(PRESTIGE_TOKEN_ITEM_ID, PRESTIGE_TOKENS_PER_RESET)

    client:Message(MT.Yellow, string.format('You are reborn at level 1 and receive %d Prestige Tokens.', PRESTIGE_TOKENS_PER_RESET))
end

function event_say(e)
    if e.message:findi('hail') then
        e.self:Say('I am the Prestige Keeper, steward of rebirth. If you have reached your maximum potential, speak the word [rebirth] and I will begin your Prestige. Ask me about [prestige] or [tokens] if you need details.')
    elseif e.message:findi('prestige') then
        e.self:Say('Prestige is a vow of sacrifice. At max level, speaking [rebirth] to me will reset you to level 1 and strip your spellbook, while preserving your earned AA progress. You will be granted ten Prestige Tokens.')
    elseif e.message:findi('tokens') then
        e.self:Say('Each Prestige Token is potent. Hand me any amount of them, and for every token I will grant you ten unspent AA points.')
    elseif e.message:findi('rebirth') then
        e.self:Say('So be it. Stand firm while I unmake what you were, so you may become more than you were.')
        perform_prestige(e.other)
    end
end

function event_trade(e)
    local token_count = 0
    local non_token_present = false
    local handin = {}
    local handin_slot = 1

    for i = 1, 4 do
        local inst = e.trade['item' .. i]
        if inst and inst.valid then
            local item_id = inst:GetID()
            if item_id == PRESTIGE_TOKEN_ITEM_ID or item_id == LEGACY_TOKEN_ITEM_ID then
                token_count = token_count + 1
                handin['item' .. handin_slot] = item_id
                handin_slot = handin_slot + 1
            else
                non_token_present = true
            end
        end
    end

    if token_count == 0 or non_token_present then
        e.self:Say('I only accept Prestige Tokens, and they must be handed in by themselves.')
        item_lib.return_items(e.self, e.other, e.trade)
        return
    end

    -- Mark accepted items as consumed so they are not auto-returned.
    if not item_lib.check_turn_in(e.trade, handin) then
        item_lib.return_items(e.self, e.other, e.trade)
        return
    end

    local aa_gain = token_count * AA_PER_TOKEN
    e.other:AddAAPoints(aa_gain)
    e.other:Message(MT.Yellow, string.format('The Prestige Keeper channels the tokens into your spirit. You gain %d unspent AA point(s).', aa_gain))
    e.self:Say(string.format('Your offering of %d token(s) has been accepted. Rise stronger from your rebirth.', token_count))
end
