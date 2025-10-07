--- GUARANTEED 0.00ms idle when all values are at defaults (1.0)
--- No loops run unless any value != default

---@class DensitySettings
---@field parked number Parked vehicle density (0.0 - 1.0)
---@field vehicle number Traffic density (0.0 - 1.0)
---@field randomvehicles number Random vehicle spawn density (0.0 - 1.0)
---@field peds number Pedestrian density (0.0 - 1.0)
---@field scenario number Scenario ped density (0.0 - 1.0)
---@field relationships? table List of NPC relationship groups

---@class DensityStatus
---@field isRunning boolean Whether control loop is active
---@field needsControl boolean Whether any value differs from default
---@field values DensitySettings Current density values

---@type DensitySettings
local density = lib.load('config.client')
local isRunning = false

local EPS = 0.0001
local DEFAULT = 1.0

--- One-time relationships (tune hostility as needed)
local function setupRelationships()
    local groups = density.relationships or {
        `AMBIENT_GANG_HILLBILLY`, `AMBIENT_GANG_BALLAS`, `AMBIENT_GANG_MEXICAN`,
        `AMBIENT_GANG_FAMILY`, `AMBIENT_GANG_MARABUNTE`, `AMBIENT_GANG_SALVA`,
        `AMBIENT_GANG_LOST`, `GANG_1`, `GANG_2`, `GANG_9`, `GANG_10`,
        `FIREMAN`, `MEDIC`, `COP`, `PRISONER`
    }

    for _, grp in ipairs(groups) do
        -- 1 = Respect, 0 = Neutral. Keep 1 if you want less random hostility.
        SetRelationshipBetweenGroups(1, grp, `PLAYER`)
    end
end

--- Parse value to float or return default
---@param val any Value to parse
---@param kind? string Kind of value (for error messages)
---@return number
local function parseFloatOrDefault(val, kind)
    if type(val) == "number" then return val end
    local n = tonumber(val)
    if n == nil then
        print(string.format("^3[DENSITY] Warning:^7 Failed to parse %s value '%s' -> using default %.2f", kind or "value", tostring(val), DEFAULT))
        return DEFAULT
    end
    return n
end

--- Check if value is default (1.0)
---@param v? number
---@return boolean
local function isDefault(v) return math.abs((v or DEFAULT) - DEFAULT) < EPS end

--- Check if active control loop is needed
---@return boolean
local function needsActiveControl()
    return not (isDefault(density.parked)
        and isDefault(density.vehicle)
        and isDefault(density.randomvehicles)
        and isDefault(density.peds)
        and isDefault(density.scenario))
end

local function applyBudgetsForDefault()
    ResetScenarioGroupsEnabled()
    SetPedPopulationBudget(3)
    SetVehiclePopulationBudget(3)
end

--- Frame loop only when needed
local function startDensityControl()
    if isRunning or not needsActiveControl() then return end
    isRunning = true
    CreateThread(function()
        while isRunning do
            SetParkedVehicleDensityMultiplierThisFrame(density.parked)
            SetVehicleDensityMultiplierThisFrame(density.vehicle)
            SetRandomVehicleDensityMultiplierThisFrame(density.randomvehicles)
            SetPedDensityMultiplierThisFrame(density.peds)
            SetScenarioPedDensityMultiplierThisFrame(density.scenario, density.scenario)
            Wait(0)
        end
        -- Dropped to 0.00ms
    end)
    print("^2[DENSITY] Control started (values differ from defaults)^7")
end

--- Stop the density control loop
local function stopDensityControl()
    if not isRunning then return end
    isRunning = false
    print("^2[DENSITY] Control stopped (0.00ms idle achieved)^7")
end

--- Clamp value between 0.0 and 1.0
---@param x number
---@return number
local function clamp01(x)
    if x < 0.0 then return 0.0 end
    if x > 1.0 then return 1.0 end
    return x
end

--- Save current settings to server
local function saveToServer()
    local settings = {
        parked = density.parked,
        vehicle = density.vehicle,
        randomvehicles = density.randomvehicles,
        peds = density.peds,
        scenario = density.scenario
    }
    TriggerServerEvent('qbx_density:saveSettings', settings)
end

--- Public setter for density values (automatically saved to server)
---@param kind string One of: "vehicle", "parked", "randomvehicles", "peds", "scenario"
---@param value number|string Density multiplier from 0.0 to 1.0
local function setDensity(kind, value)
    if density[kind] == nil then
        print("^1[DENSITY] Invalid type:^7", tostring(kind))
        return
    end
    value = clamp01(parseFloatOrDefault(value, kind))

    local old = density[kind]
    if math.abs(old - value) < EPS then
        -- No material change; avoid churn.
        return
    end

    density[kind] = value

    if needsActiveControl() then
        startDensityControl()
    else
        stopDensityControl()
        applyBudgetsForDefault()
    end

    print(string.format("^2[DENSITY] %s changed from %.2f to %.2f^7", kind, old, value))

    -- Save to server for persistence
    saveToServer()
end

--- Reset all density values to defaults (1.0) and save to server
local function resetToDefaults()
    density.parked = DEFAULT
    density.vehicle = DEFAULT
    density.randomvehicles = DEFAULT
    density.peds = DEFAULT
    density.scenario = DEFAULT

    stopDensityControl()
    applyBudgetsForDefault()

    print("^2[DENSITY] Reset to defaults - 0.00ms idle achieved^7")

    -- Save to server for persistence
    saveToServer()
end

--- Copy table values
---@param t table
---@return table
local function copyTable(t)
    local c = {}
    for k, v in pairs(t) do c[k] = v end
    return c
end

--- Get current density status
---@return DensityStatus
local function getStatus()
    return {
        isRunning = isRunning,
        needsControl = needsActiveControl(),
        values = copyTable(density) -- protect internals
    }
end

--- Load settings from server
---@param settings DensitySettings
RegisterNetEvent('qbx_density:loadSettings', function(settings)
    if not settings then return end

    -- Update density table with server settings
    for key, value in pairs(settings) do
        if density[key] ~= nil then
            density[key] = value
        end
    end

    -- Start or stop control based on loaded settings
    if needsActiveControl() then
        startDensityControl()
    else
        stopDensityControl()
        applyBudgetsForDefault()
    end

    print("^2[DENSITY] Settings loaded from server^7")
end)

--- Init on resource start
---@param res string Resource name
AddEventHandler('onClientResourceStart', function(res)
    if GetCurrentResourceName() ~= res then return end
    setupRelationships()

    -- Request saved settings from server
    local savedSettings = lib.callback.await('qbx_density:getSettings', false)
    if savedSettings then
        for key, value in pairs(savedSettings) do
            if density[key] ~= nil then
                density[key] = value
            end
        end
    end

    if needsActiveControl() then
        startDensityControl()
    else
        print("^2[DENSITY] All values at default (1.0) - Running at 0.00ms^7")
    end
end)

--- Cleanup on resource stop
---@param res string Resource name
AddEventHandler('onClientResourceStop', function(res)
    if GetCurrentResourceName() ~= res then return end
    stopDensityControl()
    -- Optional: revert budgets without printing/overwriting table values
    applyBudgetsForDefault()
end)

-- Exports
exports('SetDensity', setDensity)
exports('ResetToDefaults', resetToDefaults)
exports('GetStatus', getStatus)
exports('StartDensityControl', startDensityControl)
exports('StopDensityControl', stopDensityControl)
