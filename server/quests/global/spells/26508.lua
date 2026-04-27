-- Marked Passage AA (spell 26508)
-- First use: marks current zone and position
-- Second use: teleports to the marked position and clears it
function event_spell_effect(e)
    local client = eq.get_entity_list():GetClientByID(e.caster_id)
    if not client or not client.valid then return end

    local stored_zone = client:GetGlobal("mp_zone")

    if stored_zone == "" then
        client:SetGlobal("mp_zone", tostring(client:GetZoneID()), 5, "F")
        client:SetGlobal("mp_x",    tostring(client:GetX()),       5, "F")
        client:SetGlobal("mp_y",    tostring(client:GetY()),       5, "F")
        client:SetGlobal("mp_z",    tostring(client:GetZ()),       5, "F")
        client:SetGlobal("mp_h",    tostring(client:GetHeading()), 5, "F")
        client:Message(15, "Your location has been marked. Use Marked Passage again to return here.")
    else
        local zone_id = tonumber(stored_zone)
        local x       = tonumber(client:GetGlobal("mp_x"))
        local y       = tonumber(client:GetGlobal("mp_y"))
        local z       = tonumber(client:GetGlobal("mp_z"))
        local heading = tonumber(client:GetGlobal("mp_h"))

        client:DeleteGlobal("mp_zone")
        client:DeleteGlobal("mp_x")
        client:DeleteGlobal("mp_y")
        client:DeleteGlobal("mp_z")
        client:DeleteGlobal("mp_h")

        client:Message(15, "You are transported to your marked location.")
        client:MovePC(zone_id, x, y, z, heading)
    end
end
