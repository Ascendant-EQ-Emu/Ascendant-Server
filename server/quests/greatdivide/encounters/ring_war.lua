-- 10th Ring War
-- Great Divide
-- 118167 Zrelik the Scout
--
-- When Event Starts:
-- - Zone Depops
-- - Extra Dwarf Defenders spawn to guard TODO: make these dwarves 
--   Player controalable.
-- - 13 waves of mobs will spawn in succession; each wave will have 
--   a wave master (Captain, General, Warlord) when the wave master 
--   dies; it will start a timer (5min) before the next wave spawns
-- - 14th wave is just Narandi.
-- - There are three locations in which the giants will spawn and
--   start pathing twards Thurgadin.
--
-- Fail Conditions:
-- - Any Giant reaches the final waypoint of their pathing (which is 
--   near Thurgain).
-- - Seneschal Aldikan dies
--
-- items: 1741, 1746, 1745, 1744, 1743, 1742, 18511

local current_wave_number;
local war_complete = false;
local event_failed = false;

-- This variable controls the time between waves; currently 5min.
local wave_cooldown_time = 1.5 * 60 * 1000;

local function inst()
  return eq.get_zone_instance_id();
end

function Stop_Event()
  eq.stop_timer('wave_cooldown');

  -- Depop all war mobs
  eq.depop_all(118160); -- Kromrif_Recruit
  eq.depop_all(118130); -- Kromrif_Captain
  eq.depop_all(118150); -- Kromrif_Warrior
  eq.depop_all(118209); -- Kromrif_Priest
  eq.depop_all(118120); -- Kromrif_General
  eq.depop_all(118156); -- Kromrif_Veteran
  eq.depop_all(118210); -- Kromrif_High_Priest
  eq.depop_all(118158); -- Kromrif_Warlord
  eq.depop_all(118145); -- Narandi

  -- Condition 1 is the general mobs in the zone
  local i = inst();
  eq.spawn_condition("greatdivide", i, 1, 1);
  eq.spawn_condition("greatdivide", i, 2, 0);
  eq.spawn_condition("greatdivide", i, 3, 0);
  eq.spawn_condition("greatdivide", i, 4, 0);
  eq.spawn_condition("greatdivide", i, 5, 0);
  eq.spawn_condition("greatdivide", i, 6, 0);
  eq.spawn_condition("greatdivide", i, 7, 0);
  eq.spawn_condition("greatdivide", i, 8, 0);
  eq.spawn_condition("greatdivide", i, 9, 0);
  eq.spawn_condition("greatdivide", i, 10, 0);
  eq.spawn_condition("greatdivide", i, 11, 0);
  eq.spawn_condition("greatdivide", i, 12, 0);
  eq.spawn_condition("greatdivide", i, 13, 0);
  eq.spawn_condition("greatdivide", i, 14, 0);
  eq.spawn_condition("greatdivide", i, 15, 0);
  eq.spawn_condition("greatdivide", i, 16, 0);
  eq.spawn_condition("greatdivide", i, 17, 0);
  eq.spawn_condition("greatdivide", i, 18, 0);
  eq.spawn_condition("greatdivide", i, 19, 0);
  eq.spawn_condition("greatdivide", i, 20, 0);
  eq.spawn_condition("greatdivide", i, 21, 0);
end

function Master_Spawn(e)
  -- The first spawn condition to work with is 3; so 
  -- if we reset the event; we need to reset this to 3
  current_spawn_condition = 3;

  -- Reset all the spawn conditions to a clean state.
  Stop_Event();

end

function Start_Event()
  local i = inst();
  eq.spawn_condition("greatdivide", i, 1, 0);
  eq.spawn_condition("greatdivide", i, 2, 1);

  -- Signal the ringtemmaster to spawn the first wave...
  eq.signal(118173, 1); -- NPC: ringtenmaster

  -- Spawn the Dwarf Generals with spawn commands 
  -- so they aren't depopped when Narandi is killed
  -- and the zone is reset to normal mode.
  eq.spawn2(118169, 0, 0, -44, -792, 51, 230); -- NPC: Churn_the_Axeman
  eq.spawn2(118172, 0, 0, -37, -788, 51, 230); -- NPC: Kargin_the_Archer
  eq.spawn2(118171, 0, 0, -27, -788, 51, 230); -- NPC: Corbin_Blackwell
  eq.spawn2(118170, 0, 0, -17, -788, 51, 230); -- NPC: Dobbin_Crossaxe
  eq.spawn2(118168, 0, 0, -7,  -788, 51, 230); -- NPC: Garadain_Glacierbane
end

function Zrelik_Say(e)
  if (e.other:Admin() >= 80) then
    if (e.message:findi('end')) then
      e.self:Say("By the Dain's order, the war is called off! Stand down!");
      event_failed = true;
      Stop_Event();

      eq.depop_all(118169);
      eq.depop_all(118171);
      eq.depop_all(118172);
      eq.depop_all(118170);
      eq.depop_all(118168);
    elseif (e.message:findi('start')) then
      e.self:Say("Sound the horns! The war begins!");
      event_failed = false;
      Start_Event();

    end
  end
end

function Master_Signal(e)

  if (e.signal == 1) then
    eq.spawn_condition("greatdivide", inst(), 3, 1);

  elseif (e.signal == 2) then 
    if (event_failed) then return; end
    -- Stop wave timer (if its running)
    eq.stop_timer('wave_cooldown');
    eq.set_timer('wave_cooldown', wave_cooldown_time);

  end

end

function Master_Timer(e)
  if (e.timer == 'wave_cooldown') then
    eq.stop_timer(e.timer);

    if (event_failed) then return; end

    current_spawn_condition = current_spawn_condition + 1;

    eq.spawn_condition("greatdivide", inst(), current_spawn_condition, 1);
  end
end

function Seneschal_Spawn(e)
  e.self:Shout(" 'Good citizens of Thurgadin, hear me! Our city, our people, our very lives are in danger this day. The Kromrif are at this very moment marching towards us in an offensive they hope will bring about our demise...' ");

  e.self:Shout(" 'I hereby command, by authority of Dain Frostreaver the Fourth, that all able bodied Coldain fight to the death in defense of our land. Children, disabled citzens, and unseasoned travellers are advised to evacuate immediately!' ");

  e.self:Shout(" 'My fellow soldiers, take heart! For we are not alone in this endeavor. One among us, an outlander, has earned the title Hero of the Dain for valiant service to our people. This newcomer has brought with him allies that will fight alongside you to help bring about our victory.' ");

  e.self:Shout(" 'My friends... Brell did not place us here so many centuries ago to be slaughtered by these heathens. Nor did our forefather, Colin Dain, sacrifice himself simply to have us fail here now. Through these events we were brought to this day to test our strength and our faith.' ");

  e.self:Shout(" 'Will we be shackled together to slave away in Kromrif mines or will we stand united and feed these beasts Coldain blades? By Brell, I promise you, it is better to die on our feet than to live on our knees!' ");

  e.self:Shout(" 'TROOPS, TAKE YOUR POSITIONS!!' ");

end

function Seneschal_Death(e)
  -- Event Fail
  event_failed = true;
  Stop_Event();
  eq.zone_emote(MT.Red, "The forces defending the Grand Citadel of Thurgadin have failed, the Kromrif have overrun the first and oldest race.  The age of the dwarf has come to an end...");

  -- Depop the Dwarf Generals if they are still alive.
  eq.depop_all(118169);
  eq.depop_all(118171);
  eq.depop_all(118172);
  eq.depop_all(118170);
  eq.depop_all(118168);
end

function WaveMaster_Death(e)
  -- Send a signal to the ringtenmaster that one of the WaveMasters has 
  -- died; start a 5min timer before the next wave is spawned.
  eq.signal(118173, 2); -- NPC: ringtenmaster
end

function Narandi_Spawn(e)
  e.self:Shout("So you have defeated my foot soldiers, now come and face me you vile, filthy dwarven rabble...");
end

function Narandi_Death(e)
  war_complete = true;
  eq.zone_emote(MT.Red, 'No surprise the Age of the Dwarf continues with a Glorious victory of the Kromrif.');

  Stop_Event();
end

-- Hand in.: Shorn Head of Narandi (1741)
-- Get back: Crown of Narandi (1746)
-- Get back: Shorn Head of Narandi (1741)
function Churn_Trade(e)
  local item_lib = require("items");
  if (item_lib.check_turn_in(e.trade, {item1 = 1741})) then 
    e.other:SummonItem(1741); -- Item: Shorn Head of Narandi
    e.other:SummonItem(1746); -- Item: Crown of Narandi

    e.self:Emote("pries a crown from the head of Narandi, 'The halls of Thurgadin will echo with praises to you for as long as we grace the face of this land. May this crown serve you well. Honor through battle!' ");

    e.self:Depop();
  end

  item_lib.return_items(e.self, e.other, e.trade);
end

-- Hand in.: Shorn Head of Narandi (1741)
-- Get back: Eye of Narandi (1745)
-- Get back: Shorn Head of Narandi (1741)
function Kargin_Trade(e)
  local item_lib = require("items");
  if (item_lib.check_turn_in(e.trade, {item1 = 1741})) then 
    e.other:SummonItem(1741); -- Item: Shorn Head of Narandi
    e.other:SummonItem(1745); -- Item: Eye of Narandi

    e.self:Emote("picks up a stick and hits the back of the dismembered head with all his might, knocking one of its eyes out of the socket, 'Bastard killed my brother! Hope his ghost felt that one!' ");

    e.self:Depop();
  end

  item_lib.return_items(e.self, e.other, e.trade);
end

-- Hand in.: Shorn Head of Narandi (1741)
-- Get back: Earring of the Frozen Skull (1744)
-- Get back: Shorn Head of Narandi (1741)
function Corbin_Trade(e)
  local item_lib = require("items");
  if (item_lib.check_turn_in(e.trade, {item1 = 1741})) then 
    e.other:SummonItem(1741); -- Item: Shorn Head of Narandi
    e.other:SummonItem(1744); -- Item: Earring of the Frozen Skull

    e.self:Emote("unhooks a glowing earring from Narandi's shorn head, 'Hmm, this looks like something special. Take it, " .. e.other:GetName() .. ", you've earned it! Be well.' ");

    e.self:Depop();
  end

  item_lib.return_items(e.self, e.other, e.trade);
end

-- Hand in.: Shorn Head of Narandi (1741)
-- Get back: Faceguard of Bentos the Hero (1743)
-- Get back: Shorn Head of Narandi (1741)
function Dobbin_Trade(e)
  local item_lib = require("items");
  if (item_lib.check_turn_in(e.trade, {item1 = 1741})) then 
    e.other:SummonItem(1741); -- Item: Shorn Head of Narandi
    e.other:SummonItem(1743); -- Item: Faceguard of Bentos the Hero

    e.self:Emote("gives a gentle, warm smile and slight nod of his head in warm welcoming, 'Good day to you, " .. e.other:GetName() .. ", and welcome to the district of Selia. We are children of the light -- beings who valiantly uphold the ways of honor, valor, and merits of goodly faith and virtue. Rather, we are crusaders of these things, collectively comprising the beacon of these traits within the universe in our position in New Tanaan. We are quite pleased to have you approach us with such confidence -- perhaps the inner light has brought you to us, seeking a way to unlock the purity of these merits that you faintly mirror now. If you are seeking council in the ways of enchantments, then I would be more than pleased and honored to aid you where I can, my friend.'");

    e.self:Depop();
  end

  item_lib.return_items(e.self, e.other, e.trade);
end

-- Hand in.: Shorn Head of Narandi (1741)
-- Get back: Choker of the Wretched (1742)
-- Get back: Shorn Head of Narandi (1741)
function Garadain_Trade(e)
  local item_lib = require("items");
  if (item_lib.check_turn_in(e.trade, {item1 = 1741})) then 
    e.other:SummonItem(1741); -- Item: Shorn Head of Narandi
    e.other:SummonItem(1742); -- Item: Choker of the Wretched

    e.self:Emote("removes a choker from the severed head and returns both items to you, 'Congratulations on your victory, " .. e.other:GetName() .. ". I couldn't have done a better job myself. May Brell protect and watch over you and your friends. Farewell.'");

    e.self:Depop();
  end

  item_lib.return_items(e.self, e.other, e.trade);
end

function Zrelik_Trade(e)
  local item_lib = require("items");
  if (item_lib.check_turn_in(e.trade, {item1 = 18511})) then
    Start_Event();
  end
  item_lib.return_items(e.self, e.other, e.trade);
end

-- Sentry Badain accepts Declaration of War (1567) + Ring #9 (30369)
-- Then paths to the dwarf camp and depops
function Badain_Trade(e)
  local item_lib = require("items");
  if (item_lib.check_turn_in(e.trade, {item1 = 1567, item2 = 30369})) then
    e.self:Say("The Dain has spoken! I will rally the troops at once. Follow me, hero!");
    e.other:SummonItem(30369);  -- Return Ring #9 (needed for Seneschal Aldikar)
    e.self:MoveTo(-44, -800, 51, 230, true);
    eq.set_timer('badain_depop', 60000);
  end
  item_lib.return_items(e.self, e.other, e.trade);
end

function Badain_Timer(e)
  if (e.timer == 'badain_depop') then
    eq.stop_timer('badain_depop');
    -- Spawn Seneschal Aldikar and Zrelik directly at the camp
    -- (Do NOT use spawn condition 2 here; that spawns the entire war force)
    eq.spawn2(118166, 0, 0, -111, 1, 99, 230);  -- Seneschal Aldikar
    eq.spawn2(118167, 0, 0, -105, 1, 99, 230);  -- Zrelik the Scout
    e.self:Depop();
  end
end

-- Seneschal Aldikar trade handler
-- Pre-war: Accept Ring #9 (30369) -> return Ring #9 + Orders of Engagement (18511)
-- Post-war: Accept Ring #9 (30369) + Narandi's Head (1739) -> Shorn Head (1741) + 10th Ring (730385)
function Seneschal_Trade(e)
  local item_lib = require("items");

  -- Post-war: Ring #9 + Narandi's Head
  if (war_complete and item_lib.check_turn_in(e.trade, {item1 = 30369, item2 = 1739})) then
    e.self:Say("You have done it, " .. e.other:GetName() .. "! The Kromrif invasion has been crushed. On behalf of the Dain and all the Coldain people, I present to you the Ring of Dain Frostreaver IV. May it serve as an eternal symbol of your heroism!");
    e.other:SummonItem(1741);    -- Shorn Head of Narandi
    e.other:SummonItem(730385);  -- Ring of Dain Frostreaver IV
    e.other:AddEXP(5000000);
    eq.depop_all(118169);
    eq.depop_all(118171);
    eq.depop_all(118172);
    eq.depop_all(118170);
    eq.depop_all(118168);

  -- Pre-war: Ring #9 only
  elseif (not war_complete and item_lib.check_turn_in(e.trade, {item1 = 30369})) then
    e.self:Say("Hero of the Dain, you honor us with your presence. Take these orders to Zrelik the Scout. He will coordinate our forces. Brell be with you!");
    e.other:SummonItem(30369);  -- Return Ring #9
    e.other:SummonItem(18511);  -- Orders of Engagement
  end

  item_lib.return_items(e.self, e.other, e.trade);
end

function event_encounter_load(e)
  eq.register_npc_event('ring_war', Event.spawn,          118173, Master_Spawn);
  eq.register_npc_event('ring_war', Event.signal,         118173, Master_Signal);
  eq.register_npc_event('ring_war', Event.timer,          118173, Master_Timer);

  eq.register_npc_event('ring_war', Event.say,            118167, Zrelik_Say);
  eq.register_npc_event('ring_war', Event.trade,          118167, Zrelik_Trade);

  eq.register_npc_event('ring_war', Event.spawn,          118166, Seneschal_Spawn);
  eq.register_npc_event('ring_war', Event.death_complete, 118166, Seneschal_Death);

  -- Kromrif Captain's Death
  eq.register_npc_event('ring_war', Event.death_complete, 118130, WaveMaster_Death);
  -- Kromrif General's Death
  eq.register_npc_event('ring_war', Event.death_complete, 118120, WaveMaster_Death);
  -- Kromrif Warlord's Death
  eq.register_npc_event('ring_war', Event.death_complete, 118158, WaveMaster_Death);

  -- Narandi's Death
  eq.register_npc_event('ring_war', Event.death_complete, 118145, Narandi_Death);
  eq.register_npc_event('ring_war', Event.spawn,          118145, Narandi_Spawn);

  -- Sentry Badain
  eq.register_npc_event('ring_war', Event.trade,          118067, Badain_Trade);
  eq.register_npc_event('ring_war', Event.timer,          118067, Badain_Timer);

  -- Seneschal Aldikar Trade (pre-war and post-war)
  eq.register_npc_event('ring_war', Event.trade,          118166, Seneschal_Trade);

  -- Loot Mobs
  eq.register_npc_event('ring_war', Event.trade,          118169, Churn_Trade);
  eq.register_npc_event('ring_war', Event.trade,          118172, Kargin_Trade);
  eq.register_npc_event('ring_war', Event.trade,          118171, Corbin_Trade);
  eq.register_npc_event('ring_war', Event.trade,          118170, Dobbin_Trade);
  eq.register_npc_event('ring_war', Event.trade,          118168, Garadain_Trade);
end

function event_encounter_unload(e)
  Stop_Event();
end
