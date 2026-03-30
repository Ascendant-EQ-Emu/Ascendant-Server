-- Set to 1 to enable Iceclad translocation for players, 0 to disable
local ICECLAD_PORT_ENABLED = 0

function event_say(e)
    local is_gm = (e.other and e.other:Admin() > 80 and e.other:GetGM())

    if e.message:findi("hail") then
        if is_gm or ICECLAD_PORT_ENABLED == 1 then
            e.self:Say("Hello there. There seems to be some strange problems with the boats in this area. The Academy of Arcane Sciences has sent a small team of us to investigate them. If you need to ["
                .. eq.say_link("travel to Iceclad")
                .. "] in the meantime, I can transport you to my companion there.")
        else
            e.self:Say("Get on the boat ya lazy bum! The Academy hasn't approved translocation services to Iceclad yet. Now quit botherin' me, I've got research to do!")
        end
    elseif e.message:findi("travel to Iceclad") then
        if is_gm or ICECLAD_PORT_ENABLED == 1 then
            e.self:Say("Beaming you up!")
            e.other:MovePC(110, 389, 5324, -16.25, 383.75)
        end
    end
end
