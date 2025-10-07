--- JSON-based persistence for density settings

local STORAGE_FILE = 'density_settings.json'

---@class DensitySettings
---@field parked number Parked vehicle density (0.0 - 1.0)
---@field vehicle number Traffic density (0.0 - 1.0)
---@field randomvehicles number Random vehicle spawn density (0.0 - 1.0)
---@field peds number Pedestrian density (0.0 - 1.0)
---@field scenario number Scenario ped density (0.0 - 1.0)

---@type DensitySettings
local defaultSettings = {
    parked = 1.0,
    vehicle = 1.0,
    randomvehicles = 1.0,
    peds = 1.0,
    scenario = 1.0
}

---@type DensitySettings
local currentSettings = {
    parked = 1.0,
    vehicle = 1.0,
    randomvehicles = 1.0,
    peds = 1.0,
    scenario = 1.0
}

--- Load settings from JSON file
---@return DensitySettings
local function loadSettings()
    local data = LoadResourceFile(GetCurrentResourceName(), STORAGE_FILE)

    if data then
        local success, decoded = pcall(json.decode, data)
        if success and decoded then
            print('^2[DENSITY] Loaded saved settings from ' .. STORAGE_FILE .. '^7')
            return decoded
        else
            print('^3[DENSITY] Failed to parse ' .. STORAGE_FILE .. ', using defaults^7')
        end
    else
        print('^3[DENSITY] No saved settings found, using defaults^7')
    end

    return defaultSettings
end

--- Save settings to JSON file
---@param settings DensitySettings
---@return boolean success
local function saveSettings(settings)
    local encoded = json.encode(settings, { indent = true })
    if SaveResourceFile(GetCurrentResourceName(), STORAGE_FILE, encoded, -1) then
        print('^2[DENSITY] Settings saved to ' .. STORAGE_FILE .. '^7')
        return true
    else
        print('^1[DENSITY] Failed to save settings to ' .. STORAGE_FILE .. '^7')
        return false
    end
end

--- Initialize on resource start
---@param resourceName string
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    currentSettings = loadSettings()

    -- Broadcast loaded settings to all clients
    TriggerClientEvent('qbx_density:loadSettings', -1, currentSettings)
end)

--- Handle setting updates from clients
---@param settings DensitySettings
RegisterNetEvent('qbx_density:saveSettings', function(settings)
    local src = source
    
    if not (IsPlayerAceAllowed(tostring(src), 'group.admin') or
            IsPlayerAceAllowed(tostring(src), 'group.mod') or
            IsPlayerAceAllowed(tostring(src), 'command.density')) then
        return
    end
        
    if not settings then return end

    -- Validate settings
    local valid = true
    for key, value in pairs(settings) do
        if type(value) ~= 'number' or value < 0.0 or value > 1.0 then
            valid = false
            break
        end
    end

    if valid then
        currentSettings = settings
        saveSettings(currentSettings)

        -- Sync to all clients
        TriggerClientEvent('qbx_density:loadSettings', -1, currentSettings)
    else
        print('^1[DENSITY] Invalid settings received, ignoring^7')
    end
end)

--- Callback for clients requesting current settings
---@param source number Player source ID
---@return DensitySettings
lib.callback.register('qbx_density:getSettings', function(source)
    return currentSettings
end)
