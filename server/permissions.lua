--- Server glue for admin/mod permission checks

--- ox_lib callback: check if player has admin or mod permissions
---@param source number Player source ID
---@return boolean hasPermission
lib.callback.register('qbx_density:checkAdmin', function(source)
    -- Accept admin, mod groups, or explicit command privilege
    local sourceStr = tostring(source)
    if IsPlayerAceAllowed(sourceStr, 'group.admin') or
       IsPlayerAceAllowed(sourceStr, 'group.mod') or
       IsPlayerAceAllowed(sourceStr, 'command.densityadmin') then
        return true
    end
    return false
end)

--- Server-side command gated by ACE permissions (secure)
--- Add to permissions.cfg:
---   add_ace group.admin command.density allow
---   add_ace group.mod command.density allow
---   add_principal identifier.fivem:XXXX group.admin
---   add_principal identifier.fivem:YYYY group.mod
---@param src number Player source ID
---@param _ table Command arguments (unused)
RegisterCommand('density', function(src, _)
    if src <= 0 then return end
    local srcStr = tostring(src)
    if IsPlayerAceAllowed(srcStr, 'group.admin') or
       IsPlayerAceAllowed(srcStr, 'group.mod') or
       IsPlayerAceAllowed(srcStr, 'command.density') then
        TriggerClientEvent('qbx_density:openMenu', src)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Density Control',
            description = "You don't have permission to use this.",
            type = 'error'
        })
    end
end, true) -- true => creates ACE "command.density"
