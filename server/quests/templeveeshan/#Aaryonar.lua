-- #Aaryonar NPCID: 124010
function event_killed_merit(e)
	local account_id = e.other:AccountID();
	local char_name = e.other:GetCleanName();

	eq.set_data("velious_aaryonar_" .. account_id, char_name);

	local first_key = "first_kill_aaryonar";
	if (eq.get_data(first_key) == "") then
		eq.set_data(first_key, char_name);
		eq.world_emote(15, "SERVER FIRST! " .. char_name .. " and their group have slain Aaryonar for the first time on this server!");
	end
end

function event_combat(e)
	if (e.joined) then
		-- grab the entity list
		local entity_list = eq.get_entity_list();
		-- also aggro Kal`Vunar (124016) and Nir`Tan (124012) if they are up
		local npc_table = {124012,124016};
		for k,v in pairs(npc_table) do
			local npc = entity_list:GetMobByNpcTypeID(v);
			if (npc.valid) then
				npc:AddToHateList(e.other,1);
			end
		end
	end
end