local spell_award = require("spell_award")

local function command_sa_test(e)
    local client = e.self

    if e.args[1] ~= "test" then
        client:Message(MT.Yellow, "Usage: #sa test [rare]")
        client:Message(MT.Yellow, "  #sa test      - level up +1 and trigger spell award")
        client:Message(MT.Yellow, "  #sa test rare - same but guarantees the rare item 4th option")
        return
    end

    local char_id  = tostring(client:CharacterID())
    local level    = client:GetLevel()
    local new_level = level + 1

    -- Clear any stale pending so a fresh offer always appears
    eq.delete_data("sa_pending:" .. char_id)
    eq.delete_data("sa_rare:"    .. char_id)

    if e.args[2] == "rare" then
        eq.set_data("sa_force_rare:" .. char_id, "1")
    end

    client:SetLevel(new_level)
    client:Message(MT.Yellow, string.format("[SA Test] Leveled to %d.", new_level))
end

return command_sa_test
