Config = Config or {}
Config.relationships = {
    -- default groups included in upstream
    "AMBIENT_GANG_HILLBILLY",
    "AMBIENT_GANG_BALLAS",
    "AMBIENT_GANG_MEXICAN",
    "AMBIENT_GANG_FAMILY",
    "AMBIENT_GANG_MARABUNTE",
    "AMBIENT_GANG_SALVA",
    "AMBIENT_GANG_LOST",
    "GANG_1", "GANG_2", "GANG_9", "GANG_10",
    "FIREMAN", "MEDIC", "COP", "PRISONER"
}

return {
    -- IMPORTANT: Keep these at 1.0 for 0.00ms idle!
    -- The script will ONLY run loops when these values are changed from 1.0
    -- At 1.0, the game uses its default spawning with ZERO overhead from this script

    -- Density values (0.0 to 1.0)
    -- 1.0 = GTA Online default rates (NO LOOP RUNS AT THIS VALUE)
    -- 0.0 = Completely disabled
    parked = 1.0,         -- ✅ Default: No loop needed
    vehicle = 1.0,        -- ✅ Default: No loop needed
    randomvehicles = 1.0, -- ✅ Default: No loop needed
    peds = 1.0,           -- ✅ Default: No loop needed
    scenario = 1.0,       -- ✅ Default: No loop needed

    -- If you want to reduce density, change values at runtime:
    -- exports.qbx_density:SetDensity('vehicle', 0.5)
    -- This will activate the loop only when needed

    -- To return to 0.00ms idle:
    -- exports.qbx_density:ResetToDefaults()
}