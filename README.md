# qbx_density
Semi-loopless population management with admin menu for Qbox.

## Features
- **Zero-loop optimization**: Runs at 0.00ms when all values are at defaults (1.0)
- **Smart density control**: Only activates control loop when values differ from defaults
- **Persistent settings**: Settings automatically save to JSON and persist across server restarts
- **Calm AI**: Adjusts NPC/gang NPC aggressiveness via relationship groups
- **Flexible density adjustment**: Control vehicle, parked vehicle, random vehicle, ped, and scenario densities
- **Admin/Mod menu**: Beautiful ox_lib context menu with presets and live controls
- **ACE permission system**: Restrict access to admins and moderators
- **Configurable relationships**: Customize NPC relationship groups via config

## Installation
### Manual
- Download the script and put it in the `[qbx]` directory
- Add the following code to your server.cfg/resources.cfg:
```
ensure qbx_density
```

## Dependencies
- [ox_lib](https://github.com/CommunityOx/ox_lib) - Required for callbacks and UI

## Configuration

### Client Config (`config/client.lua`)
```lua
Config.relationships = {
    -- Customize NPC groups that respect the player
    "AMBIENT_GANG_HILLBILLY",
    "AMBIENT_GANG_BALLAS",
    -- ... add or remove groups as needed
}

return {
    parked = 1.0,         -- Parked vehicle density (0.0 - 1.0)
    vehicle = 1.0,        -- Traffic density (0.0 - 1.0)
    randomvehicles = 1.0, -- Random vehicle spawns (0.0 - 1.0)
    peds = 1.0,           -- Pedestrian density (0.0 - 1.0)
    scenario = 1.0,       -- Scenario ped density (0.0 - 1.0)
}
```

**Note**: These are initial default values. Once you change settings via the menu or exports, they will be saved to `density_settings.json` and automatically loaded on subsequent restarts. Keeping all values at `1.0` ensures **0.00ms idle resource usage**. The control loop only runs when values are modified.

### Persistent Storage
Settings are automatically saved to `density_settings.json` in the resource directory. This file is created automatically when you first change any density value. You can manually edit this file if needed, but it's recommended to use the in-game menu or exports.

### Permissions (`permissions.cfg`)
Add these to your server's permissions configuration:
```cfg
# Allow admin group to use density controls
add_ace group.admin command.densityadmin allow

# Allow mod group to use density controls
add_ace group.mod command.densityadmin allow

# Assign players to groups (replace XXXX with player identifiers)
add_principal identifier.fivem:XXXX group.admin
add_principal identifier.fivem:YYYY group.mod
```

## Commands

| Command | Permission | Description |
|---------|-----------|-------------|
| `/density` | Admin/Mod only | Server-side command to open the menu (ACE-restricted) |

## API Exports

### SetDensity
Set a specific density value at runtime. **Settings are automatically saved and persist across restarts.**
```lua
exports.qbx_density:SetDensity(type, value)
```
**Parameters:**
- `type` (string): One of `"vehicle"`, `"parked"`, `"randomvehicles"`, `"peds"`, `"scenario"`
- `value` (number): Density multiplier from `0.0` to `1.0`

**Example:**
```lua
-- Reduce traffic to 50% (automatically saved)
exports.qbx_density:SetDensity('vehicle', 0.5)

-- Disable all pedestrians (automatically saved)
exports.qbx_density:SetDensity('peds', 0.0)
```

### ResetToDefaults
Reset all density values to 1.0 and stop the control loop (0.00ms idle). **This also saves the reset state.**
```lua
exports.qbx_density:ResetToDefaults()
```

**Example:**
```lua
-- Reset everything back to normal (automatically saved)
exports.qbx_density:ResetToDefaults()
```

### GetStatus
Get current density status and values.
```lua
local status = exports.qbx_density:GetStatus()
```

**Returns:**
```lua
{
    isRunning = false,        -- Whether control loop is active
    needsControl = false,     -- Whether any value differs from default
    values = {
        parked = 1.0,
        vehicle = 1.0,
        randomvehicles = 1.0,
        peds = 1.0,
        scenario = 1.0
    }
}
```

**Example:**
```lua
local status = exports.qbx_density:GetStatus()
if status.isRunning then
    print("Density control is active")
end
print("Current vehicle density:", status.values.vehicle)
```

### StartDensityControl
Manually start the density control loop (usually called automatically).
```lua
exports.qbx_density:StartDensityControl()
```

### StopDensityControl
Manually stop the density control loop (usually called automatically).
```lua
exports.qbx_density:StopDensityControl()
```

## Usage Examples

### Script Integration
```lua
-- During a race event, reduce traffic
RegisterNetEvent('race:started', function()
    exports.qbx_density:SetDensity('vehicle', 0.1)
    exports.qbx_density:SetDensity('peds', 0.0)
end)

-- After race, restore defaults
RegisterNetEvent('race:ended', function()
    exports.qbx_density:ResetToDefaults()
end)
```

### Check Current Status
```lua
RegisterCommand('checkdensity', function()
    local status = exports.qbx_density:GetStatus()
    print("Loop running:", status.isRunning)
    print("Vehicle density:", status.values.vehicle)
end)
```

## Performance

- **0.00ms** when all values are at default (1.0)
- **~0.03ms** when control loop is active (any value modified)
- Automatic loop management - starts/stops as needed
- No unnecessary processing

## Admin Menu Features

- **Live status display**: See loop status and resource usage in real-time
- **Individual controls**: Adjust each density type with sliders
- **Quick presets**: City Life, Event Mode, Racing Mode, Ghost Town, Rush Hour, RP Server
- **Performance test**: Built-in benchmark to verify 0.00ms optimization
- **Visual feedback**: Color-coded status indicators
- **Auto-save**: All changes made through the menu are automatically saved and synced to all clients

## How Persistence Works

1. **Automatic saving**: Any change made via the menu or exports is automatically saved to `density_settings.json`
2. **Server restart**: On resource start, the server loads saved settings from the JSON file
3. **Client sync**: All clients receive the saved settings when they connect or when the resource starts
4. **Manual editing**: You can edit `density_settings.json` directly if needed (restart resource to apply changes)

**Example JSON structure:**
```json
{
  "parked": 0.5,
  "vehicle": 0.3,
  "randomvehicles": 0.4,
  "peds": 0.2,
  "scenario": 0.2
}
```

## License
GNU General Public License v3.0
