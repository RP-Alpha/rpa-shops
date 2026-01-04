-- RP-Alpha Shop System
-- Categories, player-owned shops, in-game management

local Shops = {}
local ShopPeds = {}
local ShopBlips = {}
local CurrentShop = nil
local IsAdmin = false
local PlayerJob = nil

-- ============================================
-- INITIALIZATION
-- ============================================

local function GetCategoryData(categoryId)
    return Config.Categories[categoryId] or Config.Categories['custom']
end

local function SpawnShopPed(shop)
    local category = GetCategoryData(shop.category)
    local model = shop.pedModel or category.pedModel
    
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(hash) then
        print('[rpa-shops] Failed to load model: ' .. model)
        return nil
    end
    
    local ped = CreatePed(4, hash, shop.coords.x, shop.coords.y, shop.coords.z - 1.0, shop.heading or 0.0, false, true)
    SetEntityHeading(ped, shop.heading or 0.0)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    return ped
end

local function CreateShopBlip(shop)
    local category = GetCategoryData(shop.category)
    local blipConfig = shop.blip or category.blip
    
    if not blipConfig then return nil end
    
    local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
    SetBlipSprite(blip, blipConfig.sprite or 52)
    SetBlipColour(blip, blipConfig.color or 0)
    SetBlipScale(blip, blipConfig.scale or 0.7)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(shop.label)
    EndTextCommandSetBlipName(blip)
    
    return blip
end

local function InitializeShops()
    -- Clean up existing
    for _, ped in pairs(ShopPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    for _, blip in pairs(ShopBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    ShopPeds = {}
    ShopBlips = {}
    
    -- Create new
    for id, shop in pairs(Shops) do
        ShopPeds[id] = SpawnShopPed(shop)
        ShopBlips[id] = CreateShopBlip(shop)
        
        -- Add target interaction
        if ShopPeds[id] then
            exports['rpa-lib']:AddTargetModel({GetEntityModel(ShopPeds[id])}, {
                {
                    label = 'Browse ' .. shop.label,
                    icon = 'fas fa-shopping-cart',
                    action = function()
                        OpenShop(id)
                    end,
                    canInteract = function(entity)
                        return #(GetEntityCoords(PlayerPedId()) - shop.coords) < Config.Settings.interactDistance + 1
                    end
                }
            })
        end
    end
end

-- ============================================
-- SYNC FROM SERVER
-- ============================================

RegisterNetEvent('rpa-shops:client:syncShops', function(shops)
    Shops = shops
    InitializeShops()
end)

RegisterNetEvent('rpa-shops:client:setAdmin', function(status)
    IsAdmin = status
end)

RegisterNetEvent('rpa-shops:client:setJob', function(job)
    PlayerJob = job
end)

-- ============================================
-- SHOP MENU
-- ============================================

function OpenShop(shopId)
    local shop = Shops[shopId]
    if not shop then return end
    
    CurrentShop = shopId
    
    -- Request items from server (in case of updates)
    TriggerServerEvent('rpa-shops:server:getShopItems', shopId)
end

RegisterNetEvent('rpa-shops:client:openShopMenu', function(shopId, items, canManage)
    local shop = Shops[shopId]
    if not shop then return end
    
    local options = {}
    
    -- Owner/Manager options
    if canManage then
        table.insert(options, {
            title = '⚙️ Manage Shop',
            description = 'Edit inventory, prices, etc.',
            icon = 'fas fa-cog',
            arrow = true,
            onSelect = function()
                OpenShopManageMenu(shopId, items)
            end
        })
    end
    
    -- Shop items
    if items and #items > 0 then
        for _, item in ipairs(items) do
            table.insert(options, {
                title = item.label,
                description = '$' .. item.price,
                icon = 'fas fa-box',
                onSelect = function()
                    OpenBuyMenu(shopId, item)
                end
            })
        end
    else
        table.insert(options, {
            title = 'No items available',
            description = 'This shop has no items for sale',
            icon = 'fas fa-times',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'rpa_shops_main_' .. shopId,
        title = '🛒 ' .. shop.label,
        options = options
    })
    
    lib.showContext('rpa_shops_main_' .. shopId)
end)

function OpenBuyMenu(shopId, item)
    local input = lib.inputDialog('Buy ' .. item.label, {
        {
            type = 'number',
            label = 'Quantity',
            description = 'Price per unit: $' .. item.price,
            default = 1,
            min = 1,
            max = Config.Settings.maxPurchaseQuantity
        }
    })
    
    if input and input[1] then
        local quantity = math.floor(input[1])
        local total = quantity * item.price
        
        local confirm = lib.alertDialog({
            header = 'Confirm Purchase',
            content = 'Buy ' .. quantity .. 'x ' .. item.label .. ' for $' .. total .. '?',
            centered = true,
            cancel = true
        })
        
        if confirm == 'confirm' then
            TriggerServerEvent('rpa-shops:server:buy', shopId, item.name, quantity)
        end
    end
end

-- ============================================
-- SHOP MANAGEMENT (Owner/Manager)
-- ============================================

function OpenShopManageMenu(shopId, items)
    local shop = Shops[shopId]
    if not shop then return end
    
    lib.registerContext({
        id = 'rpa_shops_manage_' .. shopId,
        title = '⚙️ Manage: ' .. shop.label,
        menu = 'rpa_shops_main_' .. shopId,
        options = {
            {
                title = '📦 Edit Items',
                description = 'Add, remove, or modify items',
                icon = 'fas fa-boxes',
                arrow = true,
                onSelect = function()
                    OpenEditItemsMenu(shopId, items)
                end
            },
            {
                title = '💰 View Revenue',
                description = 'Check shop earnings',
                icon = 'fas fa-chart-line',
                onSelect = function()
                    TriggerServerEvent('rpa-shops:server:getRevenue', shopId)
                end
            },
            {
                title = '📋 Shop Settings',
                description = 'Edit shop name, ped, etc.',
                icon = 'fas fa-sliders-h',
                arrow = true,
                onSelect = function()
                    OpenShopSettingsMenu(shopId)
                end
            }
        }
    })
    
    lib.showContext('rpa_shops_manage_' .. shopId)
end

function OpenEditItemsMenu(shopId, items)
    local options = {}
    
    -- Add new item
    table.insert(options, {
        title = '➕ Add New Item',
        description = 'Add an item to this shop',
        icon = 'fas fa-plus-circle',
        onSelect = function()
            AddNewItem(shopId)
        end
    })
    
    -- Existing items
    for _, item in ipairs(items) do
        table.insert(options, {
            title = item.label,
            description = '$' .. item.price .. ' | Item: ' .. item.name,
            icon = 'fas fa-box',
            arrow = true,
            onSelect = function()
                EditItemMenu(shopId, item)
            end
        })
    end
    
    lib.registerContext({
        id = 'rpa_shops_items_' .. shopId,
        title = '📦 Shop Items',
        menu = 'rpa_shops_manage_' .. shopId,
        options = options
    })
    
    lib.showContext('rpa_shops_items_' .. shopId)
end

function AddNewItem(shopId)
    local input = lib.inputDialog('Add New Item', {
        { type = 'input', label = 'Item Name (Database name)', required = true, placeholder = 'e.g., sandwich' },
        { type = 'input', label = 'Display Label', required = true, placeholder = 'e.g., Delicious Sandwich' },
        { type = 'number', label = 'Price', required = true, min = 1 }
    })
    
    if input then
        TriggerServerEvent('rpa-shops:server:addItem', shopId, {
            name = input[1],
            label = input[2],
            price = input[3]
        })
    end
end

function EditItemMenu(shopId, item)
    lib.registerContext({
        id = 'rpa_shops_edit_item_' .. item.name,
        title = '✏️ Edit: ' .. item.label,
        menu = 'rpa_shops_items_' .. shopId,
        options = {
            {
                title = '💲 Change Price',
                description = 'Current: $' .. item.price,
                icon = 'fas fa-dollar-sign',
                onSelect = function()
                    local input = lib.inputDialog('Change Price', {
                        { type = 'number', label = 'New Price', default = item.price, min = 1 }
                    })
                    if input then
                        TriggerServerEvent('rpa-shops:server:updateItem', shopId, item.name, { price = input[1] })
                    end
                end
            },
            {
                title = '📝 Change Label',
                description = 'Current: ' .. item.label,
                icon = 'fas fa-tag',
                onSelect = function()
                    local input = lib.inputDialog('Change Label', {
                        { type = 'input', label = 'New Label', default = item.label }
                    })
                    if input then
                        TriggerServerEvent('rpa-shops:server:updateItem', shopId, item.name, { label = input[1] })
                    end
                end
            },
            {
                title = '🗑️ Remove Item',
                description = 'Remove from shop',
                icon = 'fas fa-trash',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Remove Item',
                        content = 'Remove ' .. item.label .. ' from shop?',
                        centered = true,
                        cancel = true
                    })
                    if confirm == 'confirm' then
                        TriggerServerEvent('rpa-shops:server:removeItem', shopId, item.name)
                    end
                end
            }
        }
    })
    
    lib.showContext('rpa_shops_edit_item_' .. item.name)
end

function OpenShopSettingsMenu(shopId)
    local shop = Shops[shopId]
    
    local input = lib.inputDialog('Shop Settings', {
        { type = 'input', label = 'Shop Name', default = shop.label },
        { type = 'number', label = 'Heading', default = shop.heading or 0, min = 0, max = 360 }
    })
    
    if input then
        TriggerServerEvent('rpa-shops:server:updateShopSettings', shopId, {
            label = input[1],
            heading = input[2]
        })
    end
end

-- ============================================
-- ADMIN MENU
-- ============================================

function OpenAdminMenu()
    lib.registerContext({
        id = 'rpa_shops_admin',
        title = '🛠️ Shop Admin',
        options = {
            {
                title = '➕ Create New Shop',
                description = 'Create a shop at your location',
                icon = 'fas fa-plus-circle',
                onSelect = function()
                    CreateNewShop()
                end
            },
            {
                title = '📋 Manage Existing Shops',
                description = 'Edit or delete shops',
                icon = 'fas fa-list',
                arrow = true,
                onSelect = function()
                    OpenShopListMenu()
                end
            },
            {
                title = '📂 Manage Categories',
                description = 'View and edit shop categories',
                icon = 'fas fa-folder',
                arrow = true,
                onSelect = function()
                    OpenCategoryListMenu()
                end
            },
            {
                title = '🔄 Reload All Shops',
                description = 'Refresh shops from database',
                icon = 'fas fa-sync',
                onSelect = function()
                    TriggerServerEvent('rpa-shops:server:reloadShops')
                end
            }
        }
    })
    
    lib.showContext('rpa_shops_admin')
end

function CreateNewShop()
    local categoryOptions = {}
    for id, cat in pairs(Config.Categories) do
        table.insert(categoryOptions, { value = id, label = cat.label })
    end
    
    local input = lib.inputDialog('Create New Shop', {
        { type = 'input', label = 'Shop ID (unique)', required = true, placeholder = 'my_shop_01' },
        { type = 'input', label = 'Shop Label', required = true, placeholder = 'My Shop' },
        { type = 'select', label = 'Category', options = categoryOptions, required = true },
        { type = 'select', label = 'Position', options = {
            { value = 'current', label = 'Use Current Position' },
            { value = 'manual', label = 'Enter Manually' }
        }, default = 'current' }
    })
    
    if not input then return end
    
    local coords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    
    if input[4] == 'manual' then
        local coordInput = lib.inputDialog('Enter Coordinates', {
            { type = 'number', label = 'X', default = coords.x },
            { type = 'number', label = 'Y', default = coords.y },
            { type = 'number', label = 'Z', default = coords.z },
            { type = 'number', label = 'Heading', default = heading, min = 0, max = 360 }
        })
        if coordInput then
            coords = vector3(coordInput[1], coordInput[2], coordInput[3])
            heading = coordInput[4]
        end
    end
    
    TriggerServerEvent('rpa-shops:server:createShop', {
        id = input[1],
        label = input[2],
        category = input[3],
        coords = coords,
        heading = heading
    })
end

function OpenShopListMenu()
    local options = {}
    
    -- Group by category
    local byCategory = {}
    for id, shop in pairs(Shops) do
        local cat = shop.category or 'custom'
        if not byCategory[cat] then
            byCategory[cat] = {}
        end
        table.insert(byCategory[cat], { id = id, shop = shop })
    end
    
    for catId, shops in pairs(byCategory) do
        local catData = GetCategoryData(catId)
        table.insert(options, {
            title = catData.label,
            description = #shops .. ' shop(s)',
            icon = catData.icon,
            arrow = true,
            onSelect = function()
                OpenCategoryShopsMenu(catId, shops)
            end
        })
    end
    
    if #options == 0 then
        table.insert(options, {
            title = 'No shops found',
            icon = 'fas fa-info-circle',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'rpa_shops_list',
        title = '📋 All Shops',
        menu = 'rpa_shops_admin',
        options = options
    })
    
    lib.showContext('rpa_shops_list')
end

function OpenCategoryShopsMenu(catId, shops)
    local options = {}
    
    for _, data in ipairs(shops) do
        table.insert(options, {
            title = data.shop.label,
            description = 'ID: ' .. data.id,
            icon = 'fas fa-store',
            arrow = true,
            onSelect = function()
                OpenAdminShopMenu(data.id)
            end
        })
    end
    
    lib.registerContext({
        id = 'rpa_shops_cat_' .. catId,
        title = '📂 ' .. GetCategoryData(catId).label,
        menu = 'rpa_shops_list',
        options = options
    })
    
    lib.showContext('rpa_shops_cat_' .. catId)
end

function OpenAdminShopMenu(shopId)
    local shop = Shops[shopId]
    
    lib.registerContext({
        id = 'rpa_shops_admin_shop_' .. shopId,
        title = '🏪 ' .. shop.label,
        menu = 'rpa_shops_list',
        options = {
            {
                title = '📦 Edit Items',
                description = 'Manage shop inventory',
                icon = 'fas fa-boxes',
                onSelect = function()
                    TriggerServerEvent('rpa-shops:server:getShopItems', shopId)
                end
            },
            {
                title = '📍 Move to Position',
                description = 'Relocate shop',
                icon = 'fas fa-map-marker-alt',
                onSelect = function()
                    local coords = GetEntityCoords(PlayerPedId())
                    local heading = GetEntityHeading(PlayerPedId())
                    TriggerServerEvent('rpa-shops:server:moveShop', shopId, coords, heading)
                end
            },
            {
                title = '🧭 Teleport to Shop',
                description = 'Go to shop location',
                icon = 'fas fa-location-arrow',
                onSelect = function()
                    exports['rpa-lib']:Teleport(shop.coords)
                    exports['rpa-lib']:Notify('Teleported to ' .. shop.label, 'success')
                end
            },
            {
                title = '🗑️ Delete Shop',
                description = 'Remove this shop',
                icon = 'fas fa-trash',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Delete Shop',
                        content = 'Permanently delete "' .. shop.label .. '"?',
                        centered = true,
                        cancel = true
                    })
                    if confirm == 'confirm' then
                        TriggerServerEvent('rpa-shops:server:deleteShop', shopId)
                    end
                end
            }
        }
    })
    
    lib.showContext('rpa_shops_admin_shop_' .. shopId)
end

function OpenCategoryListMenu()
    local options = {}
    
    for id, cat in pairs(Config.Categories) do
        table.insert(options, {
            title = cat.label,
            description = 'Model: ' .. cat.pedModel,
            icon = cat.icon,
            metadata = {
                { label = 'Default Items', value = tostring(#cat.defaultItems) },
                { label = 'Blip', value = 'Sprite ' .. (cat.blip.sprite or 0) }
            }
        })
    end
    
    lib.registerContext({
        id = 'rpa_shops_categories',
        title = '📂 Categories',
        menu = 'rpa_shops_admin',
        options = options
    })
    
    lib.showContext('rpa_shops_categories')
end

-- ============================================
-- COMMANDS
-- ============================================

RegisterCommand(Config.Settings.adminCommand, function()
    TriggerServerEvent('rpa-shops:server:checkAdmin')
end, false)

RegisterNetEvent('rpa-shops:client:openAdminMenu', function()
    OpenAdminMenu()
end)

-- ============================================
-- INITIALIZATION
-- ============================================

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('rpa-shops:server:requestShops')
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, ped in pairs(ShopPeds) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
        for _, blip in pairs(ShopBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
    end
end)

print('[rpa-shops] Client loaded')
