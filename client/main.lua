local currentShop = nil

RegisterNetEvent('rpa-shops:client:open', function(shopId)
    local shop = Config.Shops[shopId]
    if not shop then return end
    currentShop = shopId

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        label = shop.label,
        items = shop.items
    })
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    currentShop = nil
    cb('ok')
end)

RegisterNUICallback('buy', function(data, cb)
    if not currentShop then return end
    TriggerServerEvent('rpa-shops:server:buy', currentShop, data.item)
    cb('ok')
end)

-- Init
CreateThread(function()
    for id, shop in pairs(Config.Shops) do
        -- Spawning Peds would go here (using rpa-lib or native)
        -- For now, just adding target to the coord zone basically
        
        -- Create Ped (Simplified: ideally use a ped manager)
        local hash = GetHashKey(shop.model)
        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(10) end
        
        local ped = CreatePed(4, hash, shop.coords.x, shop.coords.y, shop.coords.z - 1.0, 0.0, false, true)
        SetEntityHeading(ped, 0.0) -- Needs heading in config
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        
        -- Target
        exports['rpa-lib']:AddTargetModel({shop.model}, {
            {
                label = "Open Shop",
                icon = "fas fa-shopping-basket",
                action = function(entity)
                    TriggerEvent('rpa-shops:client:open', id)
                end
            }
        })

        -- Blip
        if shop.blip then
            local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
            SetBlipSprite(blip, shop.blip.sprite)
            SetBlipColour(blip, shop.blip.color)
            SetBlipScale(blip, shop.blip.scale)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(shop.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)
