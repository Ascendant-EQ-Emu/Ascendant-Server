local helper = require("translocators")

function event_say(e)
    -- GM override (status + currently flagged GM)
    local is_gm = (e.other and e.other:Admin() > 80 and e.other:GetGM()) -- :contentReference[oaicite:0]{index=0}

    if eq.is_the_ruins_of_kunark_enabled() or is_gm then
        helper.hail_text(e, "Timorous Deep", { zone = 96, x = 3481, y = 6016.38, z = 2.06, heading = 195.75 })
    end
end