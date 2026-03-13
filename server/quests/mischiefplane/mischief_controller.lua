-- control 2.0 swap


-- function event_spawn(e)
-- 	eq.spawn_condition("mischiefplane",0,1,0);
-- 	eq.spawn_condition("mischiefplane",0,2,1);
-- end


-- control 1.0 swap

function event_spawn(e)
    eq.spawn_condition("mischiefplane", 0, 1, 1)
    eq.spawn_condition("mischiefplane", 0, 2, 0)
end