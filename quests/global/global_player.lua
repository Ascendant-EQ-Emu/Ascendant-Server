-- items: 67704, 72091, 62621, 62622, 62844, 62827, 62828, 62836, 62883, 62876, 47100, 62878, 62879

local don = require("dragons_of_norrath")

function event_enter_zone(e)
	mysterious_voice(e)

	if eq.is_lost_dungeons_of_norrath_enabled() and eq.get_zone_short_name() == "lavastorm" and e.self:GetGMStatus() >= 80 then 
		e.self:Message(MT.DimGray, "There are GM commands available for Dragons of Norrath, use " .. eq.say_link("#don") .. " to get started")
	end
end

function mysterious_voice(e)
	if not eq.is_lost_dungeons_of_norrath_enabled() then
		return
	end
	local qglobals = eq.get_qglobals(e.self);
	if e.self:GetLevel() < 15 then
		return
	end
	if qglobals.Wayfarer ~= nil then
		return
	end
	local zone_id = eq.get_zone_id();

	local voice_zones = {
		Zone.qeynos,
		Zone.qeynos2,
		Zone.qrg,
		Zone.freportn,
		Zone.freportw,
		Zone.freporte,
		Zone.rivervale,
		Zone.ecommons,
		Zone.erudnint,
		Zone.erudnext,
		Zone.halas,
		Zone.everfrost,
		Zone.nro,
		Zone.sro,
		Zone.neriaka,
		Zone.neriakb,
		Zone.neriakc,
		Zone.qcat,
		Zone.oggok,
		Zone.grobb,
		Zone.gfaydark,
		Zone.akanon,
		Zone.kaladima,
		Zone.felwithea,
		Zone.felwitheb,
		Zone.kaladimb,
		Zone.butcher,
		Zone.paineel,
		Zone.cabwest,
		Zone.cabeast,
		Zone.sharvahl,
		Zone.poknowledge,
		Zone.freeporteast,
		Zone.freeportwest,
		Zone.northro,
		Zone.southro,
		Zone.commonlands
	};

	for _, zone in pairs(voice_zones) do
		if zone == zone_id then
			e.self:Message(MT.Yellow,
			"A mysterious voice whispers to you, \'If you can feel me in your thoughts, know this -- "
			.. "something is changing in the world and I reckon you should be a part of it. I do not know much, but I do know "
			.. "that in every home city and the wilds there are agents of an organization called the Wayfarers Brotherhood. They "
			.. "are looking for recruits . . . If you can hear this message, you are one of the chosen. Rush to your home city, or "
			.. "search the West Karanas and Rathe Mountains for a contact if you have been exiled from your home for your deeds, "
			.. "and find out more. Adventure awaits you, my friend.\'");
			return
		end
	end
end

function event_combine_validate(e)
	-- e.validate_type values = { "check_zone", "check_tradeskill" }
	-- criteria exports:
	--	["check_zone"].         = e.zone_id
	--	["check_tradeskill"]    = e.tradeskill_id (not active)
	if (e.recipe_id == 10344) then
		if (e.validate_type:find("check_zone")) then
			if (e.zone_id ~= Zone.tipt and e.zone_id ~= Zone.vxed) then
				return 1;
			end
		end
	end

	return 0;
end

function event_combine_success(e)
	if (e.recipe_id == 10904 or e.recipe_id == 10905 or e.recipe_id == 10906 or e.recipe_id == 10907) then
		e.self:Message(MT.Default,
		"The gem resonates with power as the shards placed within glow unlocking some of the stone's power. "
		.. "You were successful in assembling most of the stone but there are four slots left to fill, "
		.. "where could those four pieces be?"
		);
	elseif(e.recipe_id == 10903 or e.recipe_id == 10346 or e.recipe_id == 10334) then
		local reward = { };
		reward["melee"] =  { ["10903"] = 67665, ["10346"] = 67660, ["10334"] = 67653 };
		reward["hybrid"] = { ["10903"] = 67666, ["10346"] = 67661, ["10334"] = 67654 };
		reward["priest"] = { ["10903"] = 67667, ["10346"] = 67662, ["10334"] = 67655 };
		reward["caster"] = { ["10903"] = 67668, ["10346"] = 67663, ["10334"] = 67656 };

		local ctype = eq.ClassType(e.self:GetClass());
		e.self:SummonItem(reward[ctype][tostring(e.recipe_id)]);
		e.self:SummonItem(67704); -- Item: Vaifan's Clockwork Gemcutter Tools
		e.self:Message(MT.Default, "Success");
	--cleric 1.5
	elseif(e.recipe_id == 19460) then
		e.self:AddEXP(25000);
		e.self:AddAAPoints(5);
		e.self:Ding();
		e.self:Message(MT.Yellow,'You have gained 5 ability points!');
		eq.set_global("cleric_epic","7",5,"F");
	--rogue 1.5
	elseif(e.recipe_id == 13402 or e.recipe_id == 13403 or e.recipe_id == 13404 or e.recipe_id == 13405) then
		e.self:Message(MT.Yellow,"The piece of the metal orb fuses together with the blue diamonds under the intense heat of the forge. As it does, a flurry of images flash through your mind... A ranger and his bear side by side, stoic and unafraid, in a war-torn forest. A bitter tattooed woman with bluish skin wallowing in misery in a waterfront tavern. An endless barrage of crashing thunder and lightning illuminating a crimson brick ampitheater. Two halflings locked in a battle of wits using a checkered board. The images then fade from your mind");
	--ranger 1.5 tree
	elseif(e.recipe_id ==13412) then
		eq.set_global("ranger_epic","3",5,"F");
		if(eq.get_zone_short_name()=="jaggedpine") then
			e.self:Message(MT.Yellow,"The seed grows rapidly the moment you push it beneath the soil. It appears at first as a mere shoot, but within moments grows into a stout sapling and then into a gigantic tree. The tree is one you've never seen before. It is the coloration and thick bark of a redwood with the thick bole indicative of the species. The tree is, however, far too short and has spindly branches sprouting from it with beautiful flowers that you would expect on a dogwood. You take all of this in at a glance. It takes you a moment longer to realize that the tree is moving.");			
			eq.spawn2(181222, 0, 0, e.self:GetX()+3,e.self:GetY()+3,e.self:GetZ(),0); -- NPC: Red_Dogwood_Treant
		else
			e.self:Message(MT.Yellow,"The soil conditions prohibit the seed from taking hold");
			e.self:SummonItem(72091); -- Item: Fertile Earth
			e.self:SummonItem(62621); -- Item: Senvial's Blessing
			e.self:SummonItem(62622); -- Item: Grinbik's Blessing
			e.self:SummonItem(62844); -- Item: Red Dogwood Seed
		end
	--ranger 1.5 final
	elseif(e.recipe_id ==13413) then
		e.self:AddEXP(25000);
		e.self:AddAAPoints(5);
		e.self:Ding();
		e.self:Message(MT.Yellow,'You have gained 5 ability points!');
		eq.set_global("ranger_epic","5",5,"F");
	--ranger 2.0
	elseif(e.recipe_id ==19914 or e.recipe_id==19915) then
		e.self:Message(MT.Yellow,'Very Good. Now we must attune the cage to the specific element we wish to free. You will need two items, one must protect from the element and the other must be able to absorb an incredible amount of that element. This is not a simple task. You must first discover the nature of the spirit that you wish to free and then find such items that will allow you to redirect its power. You must know that each spirit represents a specific area within their element and that is what you must focus on, not their element specifically. For example, Grinbik was an earth spirit, but his area of power was fertility. Senvial was a spirit of Water, but his power was in mist and fog.');
		eq.set_global("ranger_epic","8",5,"F");
	elseif(e.recipe_id ==19916) then
		e.self:Message(MT.Yellow,"The Red Dogwood Treant speaks to you from within your sword. 'Well done. This should allow me to free a spirit with power over cold and ice. Now you need to find the power that binds the spirit and unleash it where that spirit is bound.'");	
	elseif(e.recipe_id ==19917) then
		if(eq.get_zone_short_name()=="anguish") then
			eq.spawn2(317113, 0, 0, e.self:GetX(),e.self:GetY(),e.self:GetZ(),0); -- NPC: #Oshimai_Spirit_of_the_High_Air
		end
	-- paladin 1.5 final
	elseif(e.recipe_id ==19880) then
		e.self:AddEXP(25000);
		e.self:AddAAPoints(5);
		e.self:Ding();
		e.self:Message(MT.Yellow,'You have gained 5 ability points!');	
		eq.set_global("paladin_epic","8",5,"F");
		e.self:Message(MT.Gray,"As the four soulstones come together, a soft blue light eminates around the dark sword. The soulstones find themselves at home within the sword. A flash occurs and four voices in unison speak in your mind, 'Thank you for saving us and giving us a purpose again. You are truly our savior and our redeemer, and we shall serve you from now on. Thank you, noble knight!")
	--bard 1.5 final	
	elseif(e.recipe_id == 19882) then
		e.self:AddEXP(25000);
		e.self:AddAAPoints(5);
		e.self:Ding();
		e.self:Message(MT.Yellow,'You have gained 5 ability points!');	
		eq.set_global("bard15","6",5,"F");
	--druid 1.5 feerrott
	elseif(e.recipe_id == 19888) then
		if(eq.get_zone_short_name()=="feerrott") then
			eq.spawn2(47209, 0, 0, e.self:GetX()+10,e.self:GetY()+10,e.self:GetZ(),0); -- NPC: corrupted_spirit
			e.self:Message(MT.White,"compelled spirit screams as his essences is forced back into the world of the living. 'What is this? Where am I? Who are you? What do you want from me?");
		else
			e.self:SummonItem(62827); -- Item: Mangled Head
			e.self:SummonItem(62828); -- Item: Animating Heads
			e.self:SummonItem(62836); -- Item: Soul Stone
		end
	-- druid 1.5 final
	elseif(e.recipe_id ==19892) then
		e.self:AddAAPoints(5);
		e.self:Ding();
		e.self:Message(MT.Yellow,'You have gained 5 ability points!');	
		eq.set_global("druid_epic","8",5,"F");	
		e.self:SendMarqueeMessage(MT.Yellow, 510, 1, 100, 10000, "You plant the Mind Crystal and the Seed of Living Brambles in the pot. The pot grows warm and immediately you see a vine sprouting from the soil. The vine continues to grow at a tremendous rate. Brambles grow into the heart of the crystal where the core impurity is and split it. They continue to grow at an astounding speed and soon burst the pot and form the Staff of Living Brambles");
	--druid 2.0 sub final
	elseif(e.recipe_id ==19908) then
		if(eq.get_zone_short_name()=="anguish") then
			eq.spawn2(317115, 0, 0, e.self:GetX()+3,e.self:GetY()+3,e.self:GetZ(),0); -- NPC: #Yuisaha
			e.self:SummonItem(62883); -- Item: Essence of Rainfall
			e.self:SummonItem(62876); -- Item: Insulated Container
		else
			e.self:Message(MT.Yellow,"The rain spirit cannot be reached here");
			e.self:SummonItem(47100); -- Item: Globe of Discordant Energy
			e.self:SummonItem(62876); -- Item: Insulated Container
			e.self:SummonItem(62878); -- Item: Frozen Rain Spirit
			e.self:SummonItem(62879); -- Item: Everburning Jagged Tree Limb
		end
	--druid 2.0 final
	elseif(e.recipe_id ==19909) then	
		e.self:AddEXP(50000);
		e.self:AddAAPoints(10);
		e.self:Ding();
		e.self:Message(MT.Yellow,'You have gained 10 ability points!');	
		eq.set_global("druid_epic","13",5,"F");	
		--e.self:SendMarqueeMessage(MT.Yellow, 510, 1, 100, 10000, "You plant the Mind Crystal and the Seed of Living Brambles in the pot. The pot grows warm and immediately you see a vine sprouting from the soil. The vine continues to grow at a tremendous rate. Brambles grow into the heart of the crystal where the core impurity is and split it. They continue to grow at an astounding speed and soon burst the pot and form the Staff of Living Brambles");
	--warrior 2.0
	elseif(e.recipe_id ==19902) then	
		e.self:AddEXP(50000);
		e.self:AddAAPoints(10);
		e.self:Ding();
		e.self:Message(MT.Yellow,'You have gained 10 ability points!');	
		eq.set_global("warrior_epic","21",5,"F");		
	-- CLR 2.0
	elseif (e.recipe_id == 19893) then
		e.self:Message(MT.Red, "Omat should probably see this.");
	--ench 2.0
	elseif (e.recipe_id == 19919) then
		eq.set_global("ench_epic","9",5,"F");
		e.self:Message(MT.Yellow,"Your Oculus of Persuasion gleams with a blinding light for a moment, dimming quickly to its previous understated beauty. The light has left an image burned into your mind, a strangely tattooed woman chanting by a waterfall.");
	--ench 2.0 final
	elseif (e.recipe_id == 19920) then
		e.self:Message(MT.Yellow,"The discordant energy shoots through the staff, sending a shower of sparks through the air. The crystal shatters before you, and as the sparks fade away you notice the changes in your staff.");
		e.self:AddEXP(50000);
		e.self:AddAAPoints(10);
		e.self:Ding();
		e.self:Message(MT.Yellow,'You have gained 10 ability points!');
		eq.set_global("ench_epic","10",5,"F");
	--pal 2.0 final
	elseif (e.recipe_id == 19925) then
		e.self:Message(MT.Yellow,"As you combine all six tokens in the scabbard with Redemption, you feel a tugging at your soul. An energy flows through you as you feel the virtues of your inner self being tugged and tempered into the weapon. For a second you feel drained, but now that feeling has subsided. A final flash of light occurs and a new sword is tempered; Nightbane, Sword of the Valiant");
		e.self:AddEXP(50000);
		e.self:AddAAPoints(10);
		e.self:Ding();
		e.self:Message(MT.Yellow,'You have gained 10 ability points!');
		eq.set_global("paladin_epic","11",5,"F");
		eq.delete_global("paladin_epic_mmcc");
		eq.delete_global("paladin_epic_hollowc");
	elseif (e.recipe_id == 2182) then -- Pumpkin Pie
		if (eq.is_task_activity_active(8013, 0)) then -- The Hungry Halfling
			eq.update_task_activity(8013, 0, 1);
		end
	elseif (e.recipe_id == 2181) then -- Pumpkin Bread
		if (eq.is_task_activity_active(8013, 1)) then -- The Hungry Halfling
			eq.update_task_activity(8013, 1, 1);
		end
	elseif (e.recipe_id == 7811) then -- Spiced Pumpkin Cider
		if (eq.is_task_activity_active(8013, 2)) then -- The Hungry Halfling
			eq.update_task_activity(8013, 2, 1);
		end
	elseif (e.recipe_id == 2183) then -- Pumpkin Shake
		if (eq.is_task_activity_active(8013, 3)) then -- The Hungry Halfling
			eq.update_task_activity(8013, 3, 1);
		end
	end
end

function event_command(e)
	return eq.DispatchCommands(e);
end

--[[ the main key is the ID of the AA
--   the first set is the age required in seconds
--   the second is if to ignore the age and grant anyways live test server style
--   the third is enabled
--]]
vet_aa = {
    [481]  = { 31536000, true, true}, -- Lesson of the Devote 1 yr
    [482]  = { 63072000, true, true}, -- Infusion of the Faithful 2 yr
    [483]  = { 94608000, true, true}, -- Chaotic Jester 3 yr
    [484]  = {126144000, true, true}, -- Expedient Recovery 4 yr
    [485]  = {157680000, true, true}, -- Steadfast Servant 5 yr
    [486]  = {189216000, true, true}, -- Staunch Recovery 6 yr
    [487]  = {220752000, true, true}, -- Intensity of the Resolute 7 yr
    [511]  = {252288000, true, true}, -- Throne of Heroes 8 yr
    [2000] = {283824000, true, true}, -- Armor of Experience 9 yr
    [8081] = {315360000, true, true}, -- Summon Resupply Agent 10 yr
    [8130] = {346896000, true, true}, -- Summon Clockwork Banker 11 yr
    [453]  = {378432000, true, true}, -- Summon Permutation Peddler 12 yr
    [182]  = {409968000, true, true}, -- Summon Personal Tribute Master 13 yr
    [600]  = {441504000, true, true}, -- Blessing of the Devoted 14 yr
}


function event_connect(e)
	grant_veteran_aa(e)
	don.fix_invalid_faction_state(e.self)
end

function grant_veteran_aa(e)
	if not eq.is_dragons_of_norrath_enabled() then
		return
	end

    local age = e.self:GetAccountAge();
    for aa, v in pairs(vet_aa) do
        if v[3] and (v[2] or age >= v[1]) then
            e.self:GrantAlternateAdvancementAbility(aa, 1)
        end
    end
end

--[[
0  /*13855*/ Skill1HBlunt = 0,
1  /*13856*/ Skill1HSlashing,
2  /*13857*/ Skill2HBlunt,
3  /*13858*/ Skill2HSlashing,
4  /*13859*/ SkillAbjuration,
5  /*13861*/ SkillAlteration,
6  /*13862*/ SkillApplyPoison, X
7  /*13863*/ SkillArchery, X
8  /*13864*/ SkillBackstab,
9  /*13866*/ SkillBindWound,
10 /*13867*/ SkillBash,
11 /*13871*/ SkillBlock,
12 /*13872*/ SkillBrassInstruments,
13 /*13874*/ SkillChanneling,
14 /*13875*/ SkillConjuration,
15 /*13876*/ SkillDefense,
16 /*13877*/ SkillDisarm,
17 /*13878*/ SkillDisarmTraps, 
18 /*13879*/ SkillDivination,
19 /*13880*/ SkillDodge,
20 /*13881*/ SkillDoubleAttack,
21 /*13882*/ SkillDragonPunch,
21 /*13924*/ SkillTailRake = SkillDragonPunch, // Iksar Monk equivilent
22 /*13883*/ SkillDualWield,
23 /*13884*/ SkillEagleStrike,
24 /*13885*/ SkillEvocation,
25 /*13886*/ SkillFeignDeath,
26 /*13888*/ SkillFlyingKick,
27 /*13889*/ SkillForage, X
28 /*13890*/ SkillHandtoHand,
29 /*13891*/ SkillHide,
30 /*13893*/ SkillKick,
31 /*13894*/ SkillMeditate,
32 /*13895*/ SkillMend,
33 /*13896*/ SkillOffense,
34 /*13897*/ SkillParry,
35 /*13899*/ SkillPickLock, X
36 /*13900*/ Skill1HPiercing,        // Changed in RoF2(05-10-2013)
37 /*13903*/ SkillRiposte,
38 /*13904*/ SkillRoundKick,
39 /*13905*/ SkillSafeFall, 
40 /*13906*/ SkillSenseHeading, X
41 /*13908*/ SkillSinging,
42 /*13909*/ SkillSneak,
43 /*13910*/ SkillSpecializeAbjure,      // No idea why they truncated this one..especially when there are longer ones...
44 /*13911*/ SkillSpecializeAlteration,
45 /*13912*/ SkillSpecializeConjuration,
46 /*13913*/ SkillSpecializeDivination,
47 /*13914*/ SkillSpecializeEvocation,
48 /*13915*/ SkillPickPockets, X
49 /*13916*/ SkillStringedInstruments,
50 /*13917*/ SkillSwimming, X
51 /*13919*/ SkillThrowing,
52 /*13920*/ SkillTigerClaw,
53 /*13921*/ SkillTracking, X
54 /*13923*/ SkillWindInstruments,
55 /*13854*/ SkillFishing, X
56 /*13853*/ SkillMakePoison, X
57 /*13852*/ SkillTinkering, X
58 /*13851*/ SkillResearch, X
59 /*13850*/ SkillAlchemy, X
60 /*13865*/ SkillBaking, X
61 /*13918*/ SkillTailoring, X
62 /*13907*/ SkillSenseTraps, X
63 /*13870*/ SkillBlacksmithing, X
64 /*13887*/ SkillFletching, X
65 /*13873*/ SkillBrewing, X
66 /*13860*/ SkillAlcoholTolerance, X
67 /*13868*/ SkillBegging, 
68 /*13892*/ SkillJewelryMaking, X
69 /*13901*/ SkillPottery, X
70 /*13898*/ SkillPercussionInstruments,
71 /*13922*/ SkillIntimidation,
72 /*13869*/ SkillBerserking,
73 /*13902*/ SkillTaunt,
74 /*05837*/ SkillFrenzy,
75 /*03670*/  SkillRemoveTraps,  X
76 /*13049*/  SkillTripleAttack,
]]--

function event_level_up(e)
  local free_skills =  {0,1,2,3,4,5,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,28,29,30,31,32,33,34,36,37,38,39,41,42,43,44,45,46,47,49,51,52,54,67,70,71,72,73,74,76};

  for k,v in ipairs(free_skills) do
    if ( e.self:MaxSkill(v) > 0 and e.self:GetRawSkill(v) < 1 and e.self:CanHaveSkill(v) ) then
      e.self:SetSkill(v, 1);
    end
  end

  if e.self:GetLevel() == 5 then
    eq.popup("", "<c \"#F0F000\">Welcome to level 5.</c><br><br>You have just been granted a new ability called '<c \"#F0F000\">Origin</c>' which allows you to teleport back to your starting city.<br><br>Open the Alternate Advancement window by pressing the '<c \"#F0F000\">V</c>' key, look in the '<c \"#F0F000\">General' tab</c>, and find the '<c \"#F0F000\">Origin</c>' ability and select it.<br><br>Now press the '<c \"#F0F000\">Hotkey</c>' button to create a hotkey you can place on your hot bar.");
  end

  if e.self:GetLevel() == 10 and eq.is_dragons_of_norrath_enabled() then
    eq.popup("", "<c \"#F0F000\">Welcome to level 10.</c><br><br>You are now able to begin the new player armor and weapon quests.  Speak with Castlen and Barrenzin or V`Lynn Renloe in the <c \"#66CCFF\">Plane of Knowledge</c> to begin.  One additional quest will become available to you at each level past level 10, so be sure to check back with these NPCs as you continue to gain experience.");
  end
end

test_items = {
    [Class.WARRIOR]			= {38000, 38020}, -- Warrior
    [Class.CLERIC]			= {38168, 38188}, -- Cleric
    [Class.PALADIN]			= {38084, 38104}, -- Paladin
    [Class.RANGER]			= {38105, 38125}, -- Ranger
    [Class.SHADOWKNIGHT]	= {38063, 38083}, -- Shadowknight
    [Class.DRUID]			= {38189, 38209}, -- Druid
    [Class.MONK]			= {38021, 38041}, -- Monk
    [Class.BARD]			= {38147, 38167}, -- Bard
    [Class.ROGUE]			= {38042, 38062}, -- Rogue
    [Class.SHAMAN]			= {38210, 38230}, -- Shaman
    [Class.NECROMANCER]		= {38294, 38314}, -- Necromancer
    [Class.WIZARD]			= {38231, 38251}, -- Wizard
    [Class.MAGICIAN]		= {38252, 38272}, -- Magician
    [Class.ENCHANTER]		= {38273, 38293}, -- Enchanter
    [Class.BEASTLORD]		= {38126, 38146}, -- Beastlord
    [Class.BERSERKER]		= {38315, 38332}, -- Berserker
}
 
function event_test_buff(e)
    if (e.self:GetLevel() < 25) then
        e.self:SetLevel(25)
        eq.scribe_spells(25,1)
        eq.train_discs(25,1)
        for class_id, v in pairs(test_items) do
            if e.self:GetClass() == class_id then
                for item_id = v[1], v[2] do
                    e.self:SummonItem(item_id);
                end
            end
        end
    end
end

function event_task_complete(e)
  don.on_task_complete(e.self, e.task_id)
end

-- Prestige system
local PRESTIGE_AA_ID = 60000
local PRESTIGE_TOKEN_ITEM_ID = 600001
local PRESTIGE_TOKENS_PER_RESET = 10
local PRESTIGE_REQUIRED_LEVEL = 60

function event_aa_buy(e)
    if not e or not e.self or not e.aa_id then
        return
    end

    if tonumber(e.aa_id) ~= PRESTIGE_AA_ID then
        return
    end

    local client = e.self
    local current_level = tonumber(client:GetLevel()) or 1
    local aa_cost = tonumber(e.aa_cost) or 0
    local char_id = tonumber(client:CharacterID()) or 0

    if current_level < PRESTIGE_REQUIRED_LEVEL then
        if aa_cost > 0 then
            client:AddAAPoints(aa_cost)
        end
        client:Message(MT.Red, 'Prestige requires level ' .. tostring(PRESTIGE_REQUIRED_LEVEL) .. '.')
        return
    end

    -- Refund the cost so earned AA is preserved
    if aa_cost > 0 then
        client:AddAAPoints(aa_cost)
    end

    client:UnscribeSpellAll(true)
    client:SetLevel(1)
    client:SummonItem(PRESTIGE_TOKEN_ITEM_ID, PRESTIGE_TOKENS_PER_RESET)

    if char_id > 0 then
        eq.query(string.format(
            'INSERT INTO character_prestige (char_id, prestige_count, last_prestige_unix, last_level_before_reset, last_aa_cost_refunded) ' ..
            'VALUES (%d, 1, UNIX_TIMESTAMP(), %d, %d) ' ..
            'ON DUPLICATE KEY UPDATE prestige_count = prestige_count + 1, last_prestige_unix = UNIX_TIMESTAMP(), last_level_before_reset = VALUES(last_level_before_reset), last_aa_cost_refunded = VALUES(last_aa_cost_refunded)',
            char_id,
            current_level,
            aa_cost
        ))
    end

    client:Message(MT.Yellow, 'You have prestiged. Level reset to 1, spells removed, and 10 Prestige Tokens granted.')
end

-- Prestige AA override (interactive text + max-level gate)
local PRESTIGE_AA_ID = 60000
local PRESTIGE_TOKEN_ITEM_ID = 600001
local PRESTIGE_TOKENS_PER_RESET = 10
local PRESTIGE_REQUIRED_LEVEL = 60

function event_aa_buy(e)
    if not e or not e.self or not e.aa_id then
        return
    end

    if tonumber(e.aa_id) ~= PRESTIGE_AA_ID then
        return
    end

    local client = e.self
    local current_level = tonumber(client:GetLevel()) or 1
    local aa_cost = tonumber(e.aa_cost) or 0
    local char_id = tonumber(client:CharacterID()) or 0

    if current_level < PRESTIGE_REQUIRED_LEVEL then
        if aa_cost > 0 then
            client:AddAAPoints(aa_cost)
        end
        client:Message(MT.Red, 'The Prestige Keeper whispers: only those at max level may walk the path of rebirth.')
        client:Message(MT.White, string.format('You must be level %d to Prestige.', PRESTIGE_REQUIRED_LEVEL))
        return
    end

    if aa_cost > 0 then
        client:AddAAPoints(aa_cost)
    end

    client:Message(MT.Yellow, 'You invoke Prestige. Your mortal progress is surrendered, but your true mastery remains.')
    client:UnscribeSpellAll(true)
    client:SetLevel(1)
    client:SummonItem(PRESTIGE_TOKEN_ITEM_ID, PRESTIGE_TOKENS_PER_RESET)

    if char_id > 0 then
        eq.query(string.format(
            'INSERT INTO character_prestige (char_id, prestige_count, last_prestige_unix, last_level_before_reset, last_aa_cost_refunded) ' ..
            'VALUES (%d, 1, UNIX_TIMESTAMP(), %d, %d) ' ..
            'ON DUPLICATE KEY UPDATE prestige_count = prestige_count + 1, last_prestige_unix = UNIX_TIMESTAMP(), last_level_before_reset = VALUES(last_level_before_reset), last_aa_cost_refunded = VALUES(last_aa_cost_refunded)',
            char_id,
            current_level,
            aa_cost
        ))
    end

    client:Message(MT.Yellow, 'You are reborn at level 1 and receive 10 Prestige Tokens. Return them to the Prestige Keeper for power.')
end

local BOOK_NETWORK = {
	qeynos2       = { id = 2,   x = 487,      y = 219,   z = 2,       h = 267, req = 0,  label = "North Qeynos" },
	bazaar        = { id = 151, x = -425,     y = 0,     z = -25,     h = 127, req = 0,  label = "Bazaar" },
	freportw      = { id = 9,   x = 77.31,    y = -660.57, z = -30.24, h = 0,   req = 0,  label = "Freeport West" },
	gfaydark      = { id = 54,  x = -734,     y = -188,  z = -3,      h = 0,   req = 0,  label = "Greater Faydark" },
	misty         = { id = 33,  x = -1262.71, y = -546,  z = 8,       h = 2,   req = 0,  label = "Misty Thicket" },
	everfrost     = { id = 30,  x = -31,      y = 2835,  z = -62,     h = 0,   req = 0,  label = "Everfrost" },
	butcher       = { id = 68,  x = -523,     y = 1726,  z = -1,      h = 45,  req = 0,  label = "Butcherblock" },
	rathemtn      = { id = 50,  x = 309.5,    y = -1166, z = -0.5,    h = 34,  req = 0,  label = "Rathe Mountains" },
	feerrott      = { id = 47,  x = -163,     y = 908,   z = -9,      h = 248, req = 0,  label = "Feerrott" },
	nektulos      = { id = 25,  x = -840,     y = -809,  z = 9,       h = 0,   req = 0,  label = "Nektulos" },
	innothule     = { id = 46,  x = -34,      y = -721,  z = -27,     h = 221.21, req = 0, label = "Innothule Swamp" },
	tox           = { id = 38,  x = 296,      y = -2330, z = -45.4,   h = 127, req = 0,  label = "Toxxulia Forest" },
	steamfont     = { id = 56,  x = 933.79,   y = -1358, z = -109,    h = 0,   req = 0,  label = "Steamfont Mountains" },
	fieldofbone   = { id = 78,  x = 1845,     y = -2980, z = 11,      h = 259, req = 1,  label = "Field of Bone" },
	firiona       = { id = 84,  x = 4673,     y = -455,  z = 9,       h = 128, req = 1,  label = "Firiona Vie" },
	overthere     = { id = 93,  x = 1888,     y = 3133,  z = -51,     h = 128, req = 1,  label = "Overthere" },
	greatdivide   = { id = 118, x = -1813.22, y = 0,     z = 393.44,  h = 0,   req = 2,  label = "Great Divide" },
	nexus         = { id = 152, x = 442,      y = 48,    z = -29,     h = 388, req = 3,  label = "Nexus" },
	shadeweaver   = { id = 165, x = -2433,    y = -2970, z = -215,    h = 236, req = 3,  label = "Shadeweaver" },
	potranquility = { id = 203, x = -1463,    y = 774,   z = -878,    h = 131, req = 4,  label = "Plane of Tranquility" },
	gunthak       = { id = 224, x = -1030,    y = 1780,  z = 60,      h = 0,   req = 5,  label = "Gunthak" },
	arena         = { id = 77,  x = 147.04,   y = -1014.25, z = 48,    h = 256, req = 0,  label = "Arena" },
	crescent      = { id = 394, x = -2635,    y = -1240, z = -150.6,  h = 149, req = 12, label = "Crescent Reach" }
}

local BOOK_NETWORK_ORDER = {
	"qeynos2", "bazaar", "freportw", "gfaydark", "misty", "everfrost", "butcher", "steamfont", "rathemtn",
	"feerrott", "innothule", "tox", "nektulos", "fieldofbone", "firiona", "overthere",
	"greatdivide", "nexus", "shadeweaver", "potranquility", "gunthak",
	"arena", "crescent"
}

local function should_handle_book_click(e)
	if not e or not e.door then
		return false
	end

	if not e.door:HasDestinationZone() then
		return false
	end

	local dz = string.lower(e.door:GetDestinationZoneName() or "")
	if dz == "poknowledge" then
		return true
	end

	return BOOK_NETWORK[dz] ~= nil
end

local function get_book_network_expansion(e)
	if eq and eq.get_rule then
		local parsed = tonumber(eq.get_rule("Expansion:CurrentExpansion"))
		if parsed and parsed >= 0 then
			return parsed
		end
	end

	if e and e.expansion then
		local parsed_event = tonumber(e.expansion)
		if parsed_event and parsed_event >= 0 then
			return parsed_event
		end
	end

	return 0
end

local function show_book_menu(e)
	e.self:Message(MT.White, "Select a destination below:")

	local expansion = get_book_network_expansion(e)
	local shown = 0

	for _, key in ipairs(BOOK_NETWORK_ORDER) do
		local d = BOOK_NETWORK[key]
		if d then
			if d.req <= expansion then
				e.self:Message(MT.White, eq.say_link("bookgo_" .. key, false, d.label))
				shown = shown + 1
			end
		end
	end

	if shown == 0 then
		e.self:Message(MT.Red, "No book network destinations are available at your current expansion level.")
	end
end

function event_click_door(e)
	if should_handle_book_click(e) then
		show_book_menu(e)
		return 1
	end

	return 0
end

function event_say(e)
	local msg = string.lower(e.message or "")
	local key = string.match(msg, "^bookgo_(%w+)$")
	if not key then
		return 0
	end

	local d = BOOK_NETWORK[key]
	if not d then
		e.self:Message(MT.Red, "Unknown destination.")
		return 1
	end

	local expansion = get_book_network_expansion(e)
	if d.req > 0 and expansion < d.req then
		e.self:Message(MT.Red, "That destination is expansion locked on this server.")
		return 1
	end

	e.self:MovePC(d.id, d.x, d.y, d.z, d.h)
	return 1
end

-- Final Prestige AA override with dynamic max-level rule lookup
local PRESTIGE_AA_ID = 60000
local PRESTIGE_TOKEN_ITEM_ID = 600001
local PRESTIGE_TOKENS_PER_RESET = 10

local function get_prestige_required_level()
    local result = eq.query("SELECT rule_value FROM rule_values WHERE rule_name = 'Character:MaxLevel' LIMIT 1")

    if result and result.rows and result.rows[1] and result.rows[1].rule_value then
        local parsed = tonumber(result.rows[1].rule_value)
        if parsed and parsed > 0 then
            return parsed
        end
    end

    return 60
end

function event_aa_buy(e)
    if not e or not e.self or not e.aa_id then
        return
    end

    if tonumber(e.aa_id) ~= PRESTIGE_AA_ID then
        return
    end

    local client = e.self
    local current_level = tonumber(client:GetLevel()) or 1
    local aa_cost = tonumber(e.aa_cost) or 0
    local char_id = tonumber(client:CharacterID()) or 0
    local prestige_required_level = get_prestige_required_level()

    if current_level < prestige_required_level then
        if aa_cost > 0 then
            client:AddAAPoints(aa_cost)
        end
        client:Message(MT.Red, 'The Prestige Keeper whispers: only those at max level may walk the path of rebirth.')
        client:Message(MT.White, string.format('You must be level %d to Prestige.', prestige_required_level))
        return
    end

    if aa_cost > 0 then
        client:AddAAPoints(aa_cost)
    end

    client:Message(MT.Yellow, 'You invoke Prestige. Your mortal progress is surrendered, but your true mastery remains.')
    client:UnscribeSpellAll(true)
    client:SetLevel(1)
    client:SummonItem(PRESTIGE_TOKEN_ITEM_ID, PRESTIGE_TOKENS_PER_RESET)

    if char_id > 0 then
        eq.query(string.format(
            'INSERT INTO character_prestige (char_id, prestige_count, last_prestige_unix, last_level_before_reset, last_aa_cost_refunded) ' ..
            'VALUES (%d, 1, UNIX_TIMESTAMP(), %d, %d) ' ..
            'ON DUPLICATE KEY UPDATE prestige_count = prestige_count + 1, last_prestige_unix = UNIX_TIMESTAMP(), last_level_before_reset = VALUES(last_level_before_reset), last_aa_cost_refunded = VALUES(last_aa_cost_refunded)',
            char_id,
            current_level,
            aa_cost
        ))
    end

    client:Message(MT.Yellow, 'You are reborn at level 1 and receive 10 Prestige Tokens. Return them to the Prestige Keeper for power.')
end
