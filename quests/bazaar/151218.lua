local SAFE_RETURN = { zone = "bazaar", x = -71, y = -250, z = 33, h = 128 }
local COMPASS = { zone = "bazaar", x = -23, y = 82, z = -2 }

local RAID_EXPEDITIONS = {
  -- Classic (0)
  hateplane = {
    req = 0,
    expedition = { name = "Plane of Hate", min_players = 1, max_players = 54 },
    instance = { zone = "hateplane", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = -353.08, y = -374.8, z = 3.75, h = 0 }
  },
  fearplane = {
    req = 0,
    expedition = { name = "Plane of Fear", min_players = 1, max_players = 54 },
    instance = { zone = "fearplane", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = 1282, y = -1139, z = 5, h = 0 }
  },
  airplane = {
    req = 0,
    expedition = { name = "Plane of Sky", min_players = 1, max_players = 54 },
    instance = { zone = "airplane", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = 614, y = 1415, z = -650, h = 0 }
  },
  soldungb = {
    req = 0,
    expedition = { name = "Nagafen's Lair", min_players = 1, max_players = 54 },
    instance = { zone = "soldungb", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = -263, y = -424, z = -108, h = 128 }
  },
  permafrost = {
    req = 0,
    expedition = { name = "Permafrost Keep", min_players = 1, max_players = 54 },
    instance = { zone = "permafrost", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = 61, y = -121, z = 2, h = 256 }
  },
  hole = {
    req = 0,
    expedition = { name = "The Hole", min_players = 1, max_players = 54 },
    instance = { zone = "hole", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = -1050, y = 640, z = -80, h = 0 }
  },

  -- Kunark (1)
  trakanon = {
    req = 1,
    expedition = { name = "Trakanon's Teeth", min_players = 1, max_players = 54 },
    instance = { zone = "trakanon", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = 1486, y = 3868, z = -336, h = 0 }
  },
  sebilis = {
    req = 1,
    expedition = { name = "Old Sebilis", min_players = 1, max_players = 54 },
    instance = { zone = "sebilis", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = 0, y = 250, z = 44, h = 0 }
  },
  veeshan = {
    req = 1,
    expedition = { name = "Veeshan's Peak", min_players = 1, max_players = 54 },
    instance = { zone = "veeshan", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = 1783, y = -5, z = 15, h = 0 }
  },
  chardok = {
    req = 1,
    expedition = { name = "Chardok", min_players = 1, max_players = 54 },
    instance = { zone = "chardok", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = 859, y = 119, z = 106, h = 0 }
  },

  -- Velious (2)
  templeveeshan = {
    req = 2,
    expedition = { name = "Temple of Veeshan", min_players = 1, max_players = 54 },
    instance = { zone = "templeveeshan", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = -499, y = -2086, z = -36, h = 0 }
  },
  sleeper = {
    req = 2,
    expedition = { name = "Sleeper's Tomb", min_players = 1, max_players = 54 },
    instance = { zone = "sleeper", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = 0, y = 0, z = 5, h = 0 }
  },
  kael = {
    req = 2,
    expedition = { name = "Kael Drakkel", min_players = 1, max_players = 54 },
    instance = { zone = "kael", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = -633, y = -47, z = 128, h = 0 }
  },
  skyshrine = {
    req = 2,
    expedition = { name = "Skyshrine", min_players = 1, max_players = 54 },
    instance = { zone = "skyshrine", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = -730, y = -210, z = 0, h = 0 }
  },
  westwastes = {
    req = 2,
    expedition = { name = "Western Wastes", min_players = 1, max_players = 54 },
    instance = { zone = "westwastes", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = -3499, y = -4099, z = -18, h = 0 }
  },
  growthplane = {
    req = 2,
    expedition = { name = "Plane of Growth", min_players = 1, max_players = 54 },
    instance = { zone = "growthplane", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = 3016, y = -2522, z = -19, h = 0 }
  },
  mischiefplane = {
    req = 2,
    expedition = { name = "Plane of Mischief", min_players = 1, max_players = 54 },
    instance = { zone = "mischiefplane", version = 0, duration = eq.seconds("6h") },
    compass = COMPASS,
    safereturn = SAFE_RETURN,
    zonein = { x = -395, y = -1410, z = 115, h = 0 }
  }
}

local RAID_ORDER = {
  "hateplane",
  "fearplane",
  "airplane",
  "soldungb",
  "permafrost",
  "hole",
  "trakanon",
  "sebilis",
  "veeshan",
  "chardok",
  "templeveeshan",
  "sleeper",
  "kael",
  "skyshrine",
  "westwastes",
  "growthplane",
  "mischiefplane"
}

local function get_current_expansion()
  local expansion = tonumber(eq.get_rule("Expansion:CurrentExpansion"))
  if expansion == nil then
    return 0
  end
  return expansion
end

local function show_menu(client)
  local expansion = get_current_expansion()
  client:Message(MT.NPCQuestSay, "I can create raid expeditions and send you into one you already own.")
  client:Message(MT.Say, string.format("Current expansion level: %d", expansion))
  for _, key in ipairs(RAID_ORDER) do
    local exp = RAID_EXPEDITIONS[key]
    if exp and exp.req <= expansion then
      local start_link = eq.say_link("start_" .. key, false, "[Start]")
      local enter_link = eq.say_link("enter_" .. key, false, "[Enter]")
      client:Message(MT.Say, string.format("%s %s %s", start_link, enter_link, exp.expedition.name))
    end
  end
end

local function start_expedition(client, key)
  local expansion = get_current_expansion()
  local exp = RAID_EXPEDITIONS[key]
  if not exp then
    client:Message(MT.NPCQuestSay, "That expedition is unavailable.")
    return
  end

  if exp.req > expansion then
    client:Message(MT.NPCQuestSay, "That raid expedition is not unlocked at the current expansion.")
    return
  end

  local dz = client:CreateExpedition(exp)
  if dz.valid then
    client:Message(MT.NPCQuestSay, string.format("Created expedition: %s", exp.expedition.name))
  else
    client:Message(MT.NPCQuestSay, "I could not create that expedition. You may already have one, or a lockout/group requirement blocked it.")
  end
end

local function enter_expedition(client, key)
  local expansion = get_current_expansion()
  local exp = RAID_EXPEDITIONS[key]
  if not exp then
    client:Message(MT.NPCQuestSay, "That expedition is unavailable.")
    return
  end

  if exp.req > expansion then
    client:Message(MT.NPCQuestSay, "That raid expedition is not unlocked at the current expansion.")
    return
  end

  local dz = client:GetExpedition()
  if not dz.valid then
    client:Message(MT.NPCQuestSay, "You are not currently in an expedition. Start one first.")
    return
  end

  if dz:GetZoneName() ~= exp.instance.zone then
    client:Message(MT.NPCQuestSay, string.format("Your active expedition is not %s.", exp.expedition.name))
    return
  end

  client:MovePCDynamicZone(exp.instance.zone, exp.instance.version, false)
end

function event_say(e)
  local msg = e.message:lower()

  if msg:find("hail") then
    show_menu(e.other)
    return
  end

  local start_key = msg:match("start_(%S+)")
  if start_key then
    start_expedition(e.other, start_key)
    return
  end

  local enter_key = msg:match("enter_(%S+)")
  if enter_key then
    enter_expedition(e.other, enter_key)
    return
  end
end

function event_trade(e)
  local item_lib = require("items")
  item_lib.return_items(e.self, e.other, e.trade)
end
