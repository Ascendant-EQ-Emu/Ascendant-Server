function event_killed_merit(e)
	local account_id = e.other:AccountID();
	local char_name = e.other:GetCleanName();

	eq.set_data("velious_derakor_" .. account_id, char_name);

	local first_key = "first_kill_derakor";
	if (eq.get_data(first_key) == "") then
		eq.set_data(first_key, char_name);
		eq.world_emote(15, "SERVER FIRST! " .. char_name .. " and their group have slain Derakor the Vindicator for the first time on this server!");
	end
end

function event_death_complete(e)
	e.self:Shout("Your kind will not defile the temple of Rallos Zek!");
end

function event_combat(e)

	if (e.joined) then
		eq.signal(113120, 1); -- NPC: a_temple_guardian
	end
end
