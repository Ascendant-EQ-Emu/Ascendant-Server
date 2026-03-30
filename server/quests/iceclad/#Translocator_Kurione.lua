function event_say(e)
    if e.message:findi("hail") then
        e.self:Say("Hello there. There seems to be some strange problems with the boats in this area. The Academy of Arcane Sciences has sent a small team of us to investigate them. If you need to ["
            .. eq.say_link("travel to North Ro")
            .. "] in the meantime, I can transport you to my companion there. We also just recently discovered that Joshel has been stranded over in the middle of the ocean since the problems with the boats started. If you'd be willing to go see if he's ok, I may be able to ["
            .. eq.say_link("teleport you near there")
            .. "]. Keep in mind though that it will be a one way trip. There is no one on the island able to send you back.")
    elseif e.message:findi("travel to North Ro") then
        e.self:Say("Beaming you up!")
        e.other:MovePC(34, -836, 781, 0.9, 392.5)
    elseif e.message:findi("teleport you near there") then
        e.self:Say("Hold on tight!")
        e.other:MovePC(eq.get_zone_id(), -20290, 3911, -8.4, 0)
    end
end
