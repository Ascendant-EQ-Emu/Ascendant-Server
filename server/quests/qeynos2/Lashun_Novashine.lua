-- items: 13073
local item_lib = require("items")

local MAX_BONECHIPS_PER_TRADE = 20   -- max chips consumed/rewarded per trade
local MAX_ACCEPT_CP = 10 * 1000      -- max coin accepted (10pp) in copper units
local CP_PER_UNIT = 200              -- 2g per “unit” (200cp)

function event_say(e)
	if e.message:findi("hail") then
		e.self:Say(string.format(
			"Well met, %s. My name is Lashun Novashine and I am a humble priest of Rodcet Nife, the Prime Healer. I wish to spread His word to every corner of Norrath. My job gets more difficult each day with so many so willing to take lives rather than preserve them.",
			e.other:GetName()
		))
	end
end

function event_waypoint_arrive(e)
	if e.wp == 13 or e.wp == 14 or e.wp == 15 then
		e.self:Shout("Cease this endless conflict and seek salvation in the Temple of Life! The glory of Rodcet Nife awaits you!")
	elseif e.wp == 57 then
		e.self:Say("Greetings, people of Qeynos! Are you lost? Has the chaotic life of an adventurer left you empty and alone? Seek redemption in the glorious light of the Prime Healer. Only through Rodcet Nife and the Temple of Life will you find true health and salvation.")
	end
end

function event_trade(e)
	local units = 0
	local chips_units = 0
	local coin_units = 0

	-- 1) Bone chips (stack-safe) capped at 20: consume/reward up to MAX_BONECHIPS_PER_TRADE
	while (chips_units < MAX_BONECHIPS_PER_TRADE and eq.handin({ [13073] = 1 })) do
		units = units + 1
		chips_units = chips_units + 1
	end

	-- 2) Coin: accept up to 10pp worth, convert to units (2g per unit), return rest

	-- Offered coin in copper units
	local offered_cp =
		(tonumber(e.trade.platinum) or 0) * 1000 +
		(tonumber(e.trade.gold) or 0) * 100 +
		(tonumber(e.trade.silver) or 0) * 10 +
		(tonumber(e.trade.copper) or 0)

	-- Cap at 10pp
	local accept_cp = offered_cp
	if accept_cp > MAX_ACCEPT_CP then
		accept_cp = MAX_ACCEPT_CP
	end

	-- Only full 2g units count
	local accept_units = math.floor(accept_cp / CP_PER_UNIT)
	local consume_cp = accept_units * CP_PER_UNIT

	-- Consume exactly that much coin
	if consume_cp > 0 then
		local pp = math.floor(consume_cp / 1000); consume_cp = consume_cp - (pp * 1000)
		local gp = math.floor(consume_cp / 100);  consume_cp = consume_cp - (gp * 100)
		local sp = math.floor(consume_cp / 10);   consume_cp = consume_cp - (sp * 10)
		local cp = consume_cp

		if eq.handin({ platinum = pp, gold = gp, silver = sp, copper = cp }) then
			units = units + accept_units
			coin_units = coin_units + accept_units
		end
	end

	-- Rewards
	if units > 0 then
		e.self:CastSpell(17, e.other:GetID()) -- Light Healing (once)

		if coin_units > 0 and chips_units > 0 then
			e.self:Say(string.format("Your offering is received. (%d blessings in coin, %d in bone)", coin_units, chips_units))
		elseif coin_units > 0 then
			e.self:Say(string.format("Thank you for your donation to the Temple of Life. (%d blessings)", coin_units))
			if offered_cp > MAX_ACCEPT_CP then
				e.self:Say("I can only accept so much charity at once. Any excess is returned to you.")
			end
		else
			-- If they handed in MORE than 20 chips, those extras get returned by return_items()
			if (offered_cp == 0 and chips_units == MAX_BONECHIPS_PER_TRADE) then
				e.self:Say(string.format("I can only tend to %d offerings at a time. Any excess is returned to you.", MAX_BONECHIPS_PER_TRADE))
			else
				e.self:Say("Very well, young one. May the light of the Prime Healer wash away your scars.")
			end
		end

		for _ = 1, units do
			e.other:Ding()
			e.other:Faction(341,  2, 0) -- Priests of Life
			e.other:Faction(280,  2, 0) -- Knights of Thunder
			e.other:Faction(262,  2, 0) -- Guards of Qeynos
			e.other:Faction(221, -2, 0) -- Bloodsabers
			e.other:Faction(219,  2, 0) -- Antonius Bayle
			e.other:AddEXP(12)
		end
	end

	-- Return anything not consumed: extra chips beyond 20, extra coin beyond 10pp, odd leftovers
	item_lib.return_items(e.self, e.other, e.trade)
end