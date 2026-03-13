-- Part of SK Epic 1.0
function event_spawn(e)
	--e.self:Say("Alas, I cannot be the one to carry the sword back to my people as proof in fear they will kill me to possess it for their own. I think a simple trade is in order, perhaps you have a symbol or token of Lhranc's that I could take back to the others to ease their worries?");
	eq.set_timer("depop",4800000);
end

function event_say(e)
	if(e.message:findi("hail")) then--True Spirit
	    if(e.other:GetModCharacterFactionLevel(e.self:GetPrimaryFaction()) > 82) then
		    e.self:Say("Alas, I cannot be the one to carry the sword back to my people as proof in fear they will kill me to possess it for their own. I think a simple trade is in order. Perhaps you have a symbol or token of Lhanrc's that I could take back to the others to ease their worries?");
	    end
    end
end

function event_trade(e)
	local item_lib = require("items");
	
	if(e.other:GetModCharacterFactionLevel(e.self:GetPrimaryFaction()) > 82 and item_lib.check_turn_in(e.trade, {item1 = 14384})) then
			e.self:Say("Very good, I will go deliver this right away.");
			e.other:Faction(404, -53) --True Spirit
					e.other:SummonItem(714383);

		local inv = e.other:GetInventory();
		local item_inst = inv:GetItem(Slot.Cursor);
		local item_link = item_inst and item_inst:GetItemLink() or "their Shadow Knight epic";
		eq.world_emote(15, e.other:GetName() .. " has obtained " .. item_link .. "! Congratulations, " .. e.other:GetName() .. "!");

		local first_key = "first_epic_class_" .. e.other:GetClass();
		if eq.get_data(first_key) == "" then
			eq.set_data(first_key, e.other:GetName());
			eq.enable_title(406);
			eq.world_emote(15, "A historic moment! " .. e.other:GetName() .. " is the FIRST " .. e.other:Class() .. " to obtain their class epic on this server! A title of legend has been bestowed!");
		end
			eq.depop();
	end
	item_lib.return_items(e.self, e.other, e.trade)
end

function event_timer(e)
	eq.stop_timer("depop");
	eq.depop();
end


--fiddlemetimbers
