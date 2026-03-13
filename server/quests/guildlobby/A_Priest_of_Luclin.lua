function event_say(e)
    -- Build saylink once
    local summon_link = eq.say_link("summon corpse", false, "summon corpse")

    if e.message:findi("hail") then
        e.self:Emote(
            "continues to chant toward the altar as you approach. " ..
            "'If you are in need of our aid, I can " .. summon_link .. " for you. " ..
            "Speak the words, and the remnants of your former self shall return.'"
        )
        return
    end

    if e.message:findi("summon corpse") then
        local corpse_count = e.other:GetCorpseCount()

        if corpse_count == 0 then
            e.self:Say("I sense no lost remnants of your former self.")
            return
        end

        summon_corpse(e)
        return
    end
end

function summon_corpse(e)
    local x, y, z, h = e.self:GetX(), e.self:GetY(), e.self:GetZ(), e.self:GetHeading()
    local char_id = e.other:CharacterID()

    eq.summon_all_player_corpses(char_id, x, y, z, h)

    e.self:Emote(
        "raises his hands toward the altar as shadows spill across the chamber. " ..
        "A familiar presence gathers before you, and with a burst of light, " ..
        "all that remains of your former life is drawn back to your side."
    )
end
