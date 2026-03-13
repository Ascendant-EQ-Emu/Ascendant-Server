function event_say(e)
  local msg = e.message:lower()
  local class_id = e.other:GetClass()         -- int
  local class_name = e.other:GetClassName()   -- string

  if msg:find("hail") then
    e.self:Say("Greetings. " .. e.other:GetName() .. ".  Have you come here to test your dark powers of skill and spell casting?")
    -- debug (optional)
    -- e.self:Say("DEBUG: class_id=" .. class_id .. " class_name=" .. class_name)
    return
  end

  if msg:find("dark powers of skill") then
    e.self:Say("You will be tested by either Gragrot or Tynicon.  Choose one!")
    return
  end

  if msg:find("gragrot") then
    if class_id == 5 then -- Shadowknight
      e.self:Say("I will summon him for you then")
      eq.spawn2(71063, 0, 0, 563.3, 1351.9, -766.9, 126.8) -- Gragrot
      eq.depop_with_timer()
    else
      e.self:Say("Only Shadowknights may call upon Gragrot.")
    end
    return
  end

  if msg:find("tynicon") then
    if class_id == 5 then -- Shadowknight
      e.self:Say("I will summon him for you then")
      eq.spawn2(71098, 0, 0, 563.3, 1351.9, -766.9, 126.8) -- Tynicon_DLin
      eq.depop_with_timer()
    else
      e.self:Say("Only Shadowknights may call upon Tynicon.")
    end
    return
  end
end