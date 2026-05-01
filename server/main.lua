CreateThread(function()
    if GetResourceState(Config.MDTResource) == 'missing' then
        print(('[hbs-tow] notice: MDT resource %s not present. Boot exports still available.'):format(Config.MDTResource))
    end
    if GetResourceState(Config.XPResource) == 'missing' then
        print(('[hbs-tow] warning: XP resource %s not present. Payouts will use base values.'):format(Config.XPResource))
    end
end)
