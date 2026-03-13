function event_killed_merit(e)
	local account_id = e.other:AccountID();
	local char_name = e.other:GetCleanName();

	eq.set_data("velious_statue_rallos_zek_" .. account_id, char_name);

	local first_key = "first_kill_statue_rallos_zek";
	if (eq.get_data(first_key) == "") then
		eq.set_data(first_key, char_name);
		eq.world_emote(15, "SERVER FIRST! " .. char_name .. " and their group have slain The Statue of Rallos Zek for the first time on this server!");
	end
end

function event_death_complete(e)
	e.self:Shout("Protect the Idol of Zek!");
	eq.unique_spawn(113341,0,0,1289,1300,-90,259); -- NPC: #The_Idol_of_Rallos_Zek
end

function event_combat(e)
	if (e.joined) then
		eq.signal(113131, 1); -- NPC: Armor_of_Zek
	end
end
