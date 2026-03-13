-- items: 20481, 20487
function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Say("Didn't think I was gone for good, did you? We're that much closer to finishing this trial of our strength, thanks to you.");
	end
end

function event_trade(e)
	local item_lib = require("items");
	if(item_lib.check_turn_in(e.trade, {item1 = 20481})) then
		e.self:Emote("smiles at you, then closes her eyes as she sets the gem 'Nature's Balance' into the crossguard and begins to channel her spirit into the sword. The ground rumbles loudly as she casts. She collapses in exhaustion after a short time. 'Take the blade, and perhaps you can finish this. You must strike at the heart of Innoruuk's lair. Bring a shattered gem and the mithril blade to Xanuusus. Only by weakening Innoruuk's grip over his realm can the balance of the land once again be restored. If we do not meet again, " .. e.other:GetName() .. ", remember you always have my eternal thanks.'");
		e.other:Ding();
				e.other:SummonItem(720487); -- Item: Swiftwind

		local inv = e.other:GetInventory();
		local item_inst = inv:GetItem(Slot.Cursor);
		local item_link = item_inst and item_inst:GetItemLink() or "their Ranger epic";
		eq.world_emote(15, e.other:GetName() .. " has obtained " .. item_link .. "! Congratulations, " .. e.other:GetName() .. "!");

		local first_key = "first_epic_class_" .. e.other:GetClass();
		if eq.get_data(first_key) == "" then
			eq.set_data(first_key, e.other:GetName());
			eq.enable_title(406);
			eq.world_emote(15, "A historic moment! " .. e.other:GetName() .. " is the FIRST " .. e.other:Class() .. " to obtain their class epic on this server! A title of legend has been bestowed!");
		end
		e.other:AddEXP(1000000);
		eq.depop();
	end
	item_lib.return_items(e.self, e.other, e.trade)
end

-------------------------------------------------------------------------------------------------
-- Converted to .lua using MATLAB converter written by Stryd
-- Find/replace data for .pl --> .lua conversions provided by Speedz, Stryd, Sorvani and Robregen
-------------------------------------------------------------------------------------------------
