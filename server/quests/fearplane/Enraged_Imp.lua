function event_spawn(e)
	eq.set_timer("despawn", 3600 * 1000) -- 1 hour
end

function event_timer(e)
	if e.timer == "despawn" then
		eq.depop()
	end
end

function event_death_complete(e)
	eq.spawn2(72069,0,0,e.self:GetX(),e.self:GetY(),e.self:GetZ(),0); -- NPC: Ireblind_Imp
end
-------------------------------------------------------------------------------------------------
-- Converted to .lua using MATLAB converter written by Stryd
-- Find/replace data for .pl --> .lua conversions provided by Speedz, Stryd, Sorvani and Robregen
-------------------------------------------------------------------------------------------------
