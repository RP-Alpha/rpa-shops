-- Server logic (Abstract Framework)
local function GetPlayer(source)
    local fw = exports['rpa-lib']:GetFramework()
    local fwName = exports['rpa-lib']:GetFrameworkName()
    
    if fwName == 'qb-core' then
        return fw.Functions.GetPlayer(source)
    elseif fwName == 'qbox' then
        return exports.qbx_core:GetPlayer(source)
    end
    return nil
end

RegisterNetEvent('rpa-shops:server:buy', function(shopId, itemName)
    local src = source
    local shop = Config.Shops[shopId]
    if not shop then return end
    
    local itemData = nil
    for _, item in ipairs(shop.items) do
        if item.name == itemName then
            itemData = item
            break
        end
    end

    if not itemData then return end

    local player = GetPlayer(src)
    if not player then return end

    if player.Functions.RemoveMoney('cash', itemData.price) then
        player.Functions.AddItem(itemData.name, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, exports['rpa-lib']:GetFramework().Shared.Items[itemData.name], "add") -- QB specific?
        exports['rpa-lib']:Notify(src, "Bought " .. itemData.label, "success")
    else
        exports['rpa-lib']:Notify(src, "Not enough cash!", "error")
    end
end)
