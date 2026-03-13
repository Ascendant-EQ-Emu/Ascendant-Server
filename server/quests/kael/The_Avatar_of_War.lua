function event_killed_merit(e)
	local account_id = e.other:AccountID();
	local char_name = e.other:GetCleanName();

	eq.set_data("velious_avatarofwar_" .. account_id, char_name);

	local first_key = "first_kill_avatarofwar";
	if (eq.get_data(first_key) == "") then
		eq.set_data(first_key, char_name);
		eq.world_emote(15, "SERVER FIRST! " .. char_name .. " and their group have slain The Avatar of War for the first time on this server!");
	end
end

function event_spawn(e)
	eq.set_timer("depop",3600000);
end

function event_timer(e)
	if(e.timer == "depop") then
		eq.depop();
	end
end

function event_combat(e)
	if(e.joined) then
		if(not eq.is_paused_timer("depop")) then
			eq.pause_timer("depop");
		end
	else
		eq.resume_timer("depop");
	end
end
