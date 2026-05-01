local migrationsReady = false

local function runMigrations()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/install.sql')
    if not sql then
        print('[hbs-tow] missing sql/install.sql; database tables may not exist.')
        return
    end
    local count = 0
    for stmt in sql:gmatch('([^;]+);') do
        local trimmed = stmt:match('^%s*(.-)%s*$')
        if trimmed and #trimmed > 0 and not trimmed:match('^%-%-') then
            local ok, err = pcall(MySQL.query.await, trimmed)
            if not ok then
                print(('[hbs-tow] migration statement failed: %s'):format(err))
            else
                count = count + 1
            end
        end
    end
    print(('[hbs-tow] applied %d migration statement(s)'):format(count))
end

-- Other server modules wait on this before touching DB-backed state.
function HBS_TOW_AwaitMigrations()
    while not migrationsReady do Wait(50) end
end

CreateThread(function()
    local mode = GetConvar('onesync', 'off')
    if mode == 'off' then
        print('[hbs-tow] WARNING: OneSync is off. Server-side vehicle spawning (CreateVehicleServerSetter) will fail.')
    end
    if GetResourceState(Config.MDTResource) == 'missing' then
        print(('[hbs-tow] notice: MDT resource %s not present. Boot exports still available.'):format(Config.MDTResource))
    end
    if GetResourceState(Config.XPResource) == 'missing' then
        print(('[hbs-tow] warning: XP resource %s not present. Payouts will use base values.'):format(Config.XPResource))
    end

    runMigrations()
    migrationsReady = true
end)
