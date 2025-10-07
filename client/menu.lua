local isAdmin = false
local checkingPermission = false

--- Wait for player to actually be logged in (QBox sets this statebag)
local function waitForLogin()
    local timeout = GetGameTimer() + 15000
    while not LocalPlayer.state.isLoggedIn do
        if GetGameTimer() > timeout then
            -- notify user that login timed out
            if lib and lib.notify then
                lib.notify({
                    title = "Density Control",
                    description = "Login check timed out (15s). Menu may not be available yet.",
                    type = "info"
                })
            else
                print("^3[DENSITY] waitForLogin: login timed out after 15s^7")
            end
            break
        end
        Wait(200)
    end
end

--- Check if player has admin/mod permission
---@return boolean
local function checkPermission()
    if checkingPermission then return isAdmin end
    checkingPermission = true
    local ok = lib.callback.await('qbx_density:checkAdmin', false)
    -- single assignment point, safe and visible
    if ok ~= isAdmin then
        isAdmin = ok
    end
    checkingPermission = false
    return ok
end

CreateThread(function()
    waitForLogin()
    checkPermission()
end)

--- Check if player currently has permission cached
---@return boolean
local function hasPermission()
    return isAdmin
end

--- Format density value for display
---@param value number
---@return string
local function formatValue(value)
    if value == 1.0 then
        return string.format('%.1f ^2(Default - No Loop)^7', value)
    else
        return string.format('%.1f ^3(Modified - Loop Active)^7', value)
    end
end

--- Open the main density control menu
local function openDensityMenu()
    if not hasPermission() then
        -- re-check in case statebags/callback were late
        if not checkPermission() then
            lib.notify({
                title = 'Density Control',
                description = "You don't have permission to access this menu",
                type = 'error'
            })
            return
        end
    end

    local status = exports.qbx_density:GetStatus()
    local loopStatus = status.isRunning and '🔴 Active' or '🟢 Inactive (0.00ms)'

    lib.registerContext({
        id = 'density_main_menu',
        title = '🎛️ Density Control Panel',
        options = {
            {
                title = 'Loop Status: ' .. loopStatus,
                description = status.isRunning
                    and 'Loop is running because values differ from defaults'
                    or  'All values at default - 0.00ms resource usage',
                metadata = {
                    { label = 'Resource Usage', value = status.isRunning and '~0.03ms' or '0.00ms' }
                }
            },
            {
                title = '🚗 Vehicle Density',
                description = 'Current: ' .. formatValue(status.values.vehicle),
                arrow = true,
                event = 'density:changeValue',
                args = { type = 'vehicle', current = status.values.vehicle }
            },
            {
                title = '🚙 Parked Vehicle Density',
                description = 'Current: ' .. formatValue(status.values.parked),
                arrow = true,
                event = 'density:changeValue',
                args = { type = 'parked', current = status.values.parked }
            },
            {
                title = '🎲 Random Vehicle Density',
                description = 'Current: ' .. formatValue(status.values.randomvehicles),
                arrow = true,
                event = 'density:changeValue',
                args = { type = 'randomvehicles', current = status.values.randomvehicles }
            },
            {
                title = '👥 Ped Density',
                description = 'Current: ' .. formatValue(status.values.peds),
                arrow = true,
                event = 'density:changeValue',
                args = { type = 'peds', current = status.values.peds }
            },
            {
                title = '🎭 Scenario Ped Density',
                description = 'Current: ' .. formatValue(status.values.scenario),
                arrow = true,
                event = 'density:changeValue',
                args = { type = 'scenario', current = status.values.scenario }
            },
            { title = '', description = '' },
            {
                title = '⚡ Quick Presets',
                description = 'Apply common density configurations',
                arrow = true,
                event = 'density:openPresets'
            },
            {
                title = '🔄 Reset to Defaults',
                description = 'Set all values to 1.0 (stops loop, 0.00ms)',
                event = 'density:resetAll'
            },
            {
                title = '📊 Performance Test',
                description = 'Run a performance benchmark',
                event = 'density:perfTest'
            }
        }
    })

    lib.showContext('density_main_menu')
end

--- Value editor event handler
---@param data table { type: string, current: number }
RegisterNetEvent('density:changeValue', function(data)
    local input = lib.inputDialog('Adjust ' .. data.type .. ' Density', {
        {
            type = 'slider',
            label = 'Density Value',
            description = '0.0 = None | 1.0 = Default (no loop)',
            default = data.current,
            min = 0,
            max = 1,
            step = 0.1
        },
        {
            type = 'select',
            label = 'Quick Select',
            description = 'Or choose a preset value',
            options = {
                { label = 'Off (0.0)', value = '0' },
                { label = 'Very Low (0.2)', value = '0.2' },
                { label = 'Low (0.4)', value = '0.4' },
                { label = 'Medium (0.6)', value = '0.6' },
                { label = 'High (0.8)', value = '0.8' },
                { label = 'Default (1.0) - No Loop', value = '1' },
            }
        }
    })

    if not input then
        openDensityMenu()
        return
    end

    local value = input[2] ~= nil and tonumber(input[2]) or input[1]
    exports.qbx_density:SetDensity(data.type, value)

    lib.notify({
        title = 'Density Control',
        description = ('%s set to %.1f'):format(data.type, value),
        type = 'success'
    })

    Wait(100)
    openDensityMenu()
end)

--- Open presets menu
RegisterNetEvent('density:openPresets', function()
    lib.registerContext({
        id = 'density_presets',
        title = '⚡ Density Presets',
        menu = 'density_main_menu',
        options = {
            {
                title = '🏙️ City Life',
                description = 'Normal city traffic and pedestrians',
                metadata = {
                    { label = 'Vehicles', value = '0.8' },
                    { label = 'Peds', value = '0.8' },
                    { label = 'Parked', value = '0.8' }
                },
                event = 'density:applyPreset',
                args = { vehicle = 0.8, peds = 0.8, parked = 0.8, randomvehicles = 0.8, scenario = 0.8 }
            },
            {
                title = '🎮 Event Mode',
                description = 'Reduced density for events',
                metadata = {
                    { label = 'Vehicles', value = '0.3' },
                    { label = 'Peds', value = '0.2' },
                    { label = 'Parked', value = '0.5' }
                },
                event = 'density:applyPreset',
                args = { vehicle = 0.3, peds = 0.2, parked = 0.5, randomvehicles = 0.3, scenario = 0.2 }
            },
            {
                title = '🏁 Racing Mode',
                description = 'Minimal traffic for racing',
                metadata = {
                    { label = 'Vehicles', value = '0.1' },
                    { label = 'Peds', value = '0.1' },
                    { label = 'Parked', value = '0.3' }
                },
                event = 'density:applyPreset',
                args = { vehicle = 0.1, peds = 0.1, parked = 0.3, randomvehicles = 0.1, scenario = 0.1 }
            },
            {
                title = '👻 Ghost Town',
                description = 'Empty streets',
                metadata = { { label = 'All', value = '0.0' } },
                event = 'density:applyPreset',
                args = { vehicle = 0.0, peds = 0.0, parked = 0.0, randomvehicles = 0.0, scenario = 0.0 }
            },
            {
                title = '🌆 Rush Hour',
                description = 'Heavy traffic',
                metadata = { { label = 'Vehicles', value = '1.0' }, { label = 'Peds', value = '1.0' } },
                event = 'density:applyPreset',
                args = { vehicle = 1.0, peds = 1.0, parked = 1.0, randomvehicles = 1.0, scenario = 1.0 }
            },
            {
                title = '🚓 RP Server',
                description = 'Balanced for roleplay',
                metadata = {
                    { label = 'Vehicles', value = '0.6' },
                    { label = 'Peds', value = '0.5' },
                    { label = 'Parked', value = '0.7' }
                },
                event = 'density:applyPreset',
                args = { vehicle = 0.6, peds = 0.5, parked = 0.7, randomvehicles = 0.6, scenario = 0.5 }
            }
        }
    })

    lib.showContext('density_presets')
end)

--- Apply a preset configuration
---@param preset table Density preset values
RegisterNetEvent('density:applyPreset', function(preset)
    local progress = lib.progressCircle({
        duration = 2000,
        label = 'Applying preset...',
        useWhileDead = false,
        canCancel = false,
        disable = { car = false, move = false }
    })

    if progress then
        for t, v in pairs(preset) do
            exports.qbx_density:SetDensity(t, v)
        end

        lib.notify({
            title = 'Density Control',
            description = 'Preset applied successfully',
            type = 'success'
        })
    end

    Wait(100)
    openDensityMenu()
end)

--- Reset all density values to defaults
RegisterNetEvent('density:resetAll', function()
    local alert = lib.alertDialog({
        header = 'Reset to Defaults?',
        content = 'This will set all density values to 1.0 and stop the control loop (0.00ms idle)',
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        exports.qbx_density:ResetToDefaults()
        lib.notify({
            title = 'Density Control',
            description = 'All values reset - Loop stopped (0.00ms)',
            type = 'success'
        })
        Wait(100)
        openDensityMenu()
    end
end)

--- Run performance test
RegisterNetEvent('density:perfTest', function()
    lib.notify({ title = 'Density Control', description = 'Starting 10-second performance test...', type = 'info' })

    CreateThread(function()
        exports.qbx_density:ResetToDefaults()
        Wait(1000)
        lib.notify({ title = 'Density Control', description = 'Test 1/3: resmon should be 0.00ms', type = 'info' })
        Wait(3000)

        exports.qbx_density:SetDensity('vehicle', 0.5)
        exports.qbx_density:SetDensity('peds', 0.5)
        Wait(1000)
        lib.notify({ title = 'Density Control', description = 'Test 2/3: resmon ~0.03ms', type = 'info' })
        Wait(3000)

        exports.qbx_density:ResetToDefaults()
        Wait(1000)
        lib.notify({ title = 'Density Control', description = 'Test 3/3: Back to 0.00ms', type = 'success' })
    end)
end)

--- Menu is opened from server command (/density) for security
RegisterNetEvent('qbx_density:openMenu', function()
    openDensityMenu()
end)
