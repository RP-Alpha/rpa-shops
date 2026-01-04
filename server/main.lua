-- RP-Alpha Shop System - Server Side
-- Categories, player-owned shops, database persistence

local Shops = {}
local ShopItems = {} -- Cache: shopId -> items array

-- ============================================
-- INITIALIZATION
-- ============================================

CreateThread(function()
    -- Create database tables
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `rpa_shops` (
            `id` VARCHAR(50) PRIMARY KEY,
            `category` VARCHAR(50) NOT NULL,
            `label` VARCHAR(100) NOT NULL,
            `coords_x` FLOAT NOT NULL,
            `coords_y` FLOAT NOT NULL,
            `coords_z` FLOAT NOT NULL,
            `heading` FLOAT DEFAULT 0,
            `owner_citizenid` VARCHAR(50),
            `owner_job` VARCHAR(50),
            `ped_model` VARCHAR(50),
            `blip_sprite` INT,
            `blip_color` INT,
            `blip_scale` FLOAT,
            `revenue` INT DEFAULT 0,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `rpa_shop_items` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `shop_id` VARCHAR(50) NOT NULL,
            `item_name` VARCHAR(50) NOT NULL,
            `item_label` VARCHAR(100) NOT NULL,
            `price` INT NOT NULL,
            UNIQUE KEY `shop_item` (`shop_id`, `item_name`),
            FOREIGN KEY (`shop_id`) REFERENCES `rpa_shops`(`id`) ON DELETE CASCADE
        )
    ]])
    
    Wait(500)
    LoadShops()
end)

-- Load shops from database
function LoadShops()
    local result = MySQL.query.await('SELECT * FROM rpa_shops')
    
    Shops = {}
    
    if result and #result > 0 then
        for _, row in ipairs(result) do
            Shops[row.id] = {
                id = row.id,
                category = row.category,
                label = row.label,
                coords = vector3(row.coords_x, row.coords_y, row.coords_z),
                heading = row.heading,
                owner = row.owner_citizenid,
                ownerJob = row.owner_job,
                pedModel = row.ped_model,
                blip = row.blip_sprite and {
                    sprite = row.blip_sprite,
                    color = row.blip_color,
                    scale = row.blip_scale
                } or nil,
                revenue = row.revenue or 0
            }
        end
        print('[rpa-shops] Loaded ' .. #result .. ' shops from database')
    else
        -- Load defaults
        for _, shop in ipairs(Config.DefaultShops) do
            Shops[shop.id] = shop
            SaveShopToDatabase(shop)
        end
        print('[rpa-shops] Loaded ' .. #Config.DefaultShops .. ' default shops')
    end
    
    -- Load items for each shop
    LoadAllShopItems()
end

function LoadAllShopItems()
    local result = MySQL.query.await('SELECT * FROM rpa_shop_items')
    
    ShopItems = {}
    
    if result then
        for _, row in ipairs(result) do
            if not ShopItems[row.shop_id] then
                ShopItems[row.shop_id] = {}
            end
            table.insert(ShopItems[row.shop_id], {
                name = row.item_name,
                label = row.item_label,
                price = row.price
            })
        end
    end
    
    -- Fill missing shops with category defaults
    for id, shop in pairs(Shops) do
        if not ShopItems[id] or #ShopItems[id] == 0 then
            local category = Config.Categories[shop.category]
            if category and category.defaultItems then
                ShopItems[id] = {}
                for _, item in ipairs(category.defaultItems) do
                    table.insert(ShopItems[id], {
                        name = item.name,
                        label = item.label,
                        price = item.price
                    })
                end
                -- Save to database
                SaveShopItems(id, ShopItems[id])
            end
        end
    end
end

function SaveShopToDatabase(shop)
    local blip = shop.blip or (Config.Categories[shop.category] and Config.Categories[shop.category].blip)
    
    MySQL.query([[
        INSERT INTO rpa_shops (id, category, label, coords_x, coords_y, coords_z, heading, owner_citizenid, owner_job, ped_model, blip_sprite, blip_color, blip_scale)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            category = VALUES(category),
            label = VALUES(label),
            coords_x = VALUES(coords_x),
            coords_y = VALUES(coords_y),
            coords_z = VALUES(coords_z),
            heading = VALUES(heading),
            owner_citizenid = VALUES(owner_citizenid),
            owner_job = VALUES(owner_job),
            ped_model = VALUES(ped_model),
            blip_sprite = VALUES(blip_sprite),
            blip_color = VALUES(blip_color),
            blip_scale = VALUES(blip_scale)
    ]], {
        shop.id,
        shop.category or 'custom',
        shop.label,
        shop.coords.x,
        shop.coords.y,
        shop.coords.z,
        shop.heading or 0,
        shop.owner,
        shop.ownerJob,
        shop.pedModel,
        blip and blip.sprite,
        blip and blip.color,
        blip and blip.scale
    })
end

function SaveShopItems(shopId, items)
    -- Delete existing items
    MySQL.query('DELETE FROM rpa_shop_items WHERE shop_id = ?', { shopId })
    
    -- Insert new items
    for _, item in ipairs(items) do
        MySQL.insert('INSERT INTO rpa_shop_items (shop_id, item_name, item_label, price) VALUES (?, ?, ?, ?)', {
            shopId,
            item.name,
            item.label,
            item.price
        })
    end
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function GetPlayer(source)
    local Framework = exports['rpa-lib']:GetFramework()
    if Framework then
        return Framework.Functions.GetPlayer(source)
    end
    return nil
end

local function HasAdminPermission(source)
    return exports['rpa-lib']:HasPermission(source, Config.AdminPermissions, 'shops')
end

local function CanManageShop(source, shop)
    -- Admin can manage all
    if HasAdminPermission(source) then
        return true
    end
    
    local player = GetPlayer(source)
    if not player then return false end
    
    -- Owner can manage
    if shop.owner and shop.owner == player.PlayerData.citizenid then
        return true
    end
    
    -- Job manager can manage job shops
    if shop.ownerJob and Config.JobShops.enabled then
        local playerJob = player.PlayerData.job
        if playerJob.name == shop.ownerJob and playerJob.grade.level >= Config.JobShops.managerGrade then
            return true
        end
    end
    
    return false
end

-- ============================================
-- SYNC EVENTS
-- ============================================

RegisterNetEvent('rpa-shops:server:requestShops', function()
    local src = source
    TriggerClientEvent('rpa-shops:client:syncShops', src, Shops)
    
    local isAdmin = HasAdminPermission(src)
    TriggerClientEvent('rpa-shops:client:setAdmin', src, isAdmin)
    
    local player = GetPlayer(src)
    if player then
        TriggerClientEvent('rpa-shops:client:setJob', src, player.PlayerData.job)
    end
end)

RegisterNetEvent('rpa-shops:server:reloadShops', function()
    local src = source
    if not HasAdminPermission(src) then return end
    
    LoadShops()
    TriggerClientEvent('rpa-shops:client:syncShops', -1, Shops)
    exports['rpa-lib']:Notify(src, 'Shops reloaded', 'success')
end)

RegisterNetEvent('rpa-shops:server:checkAdmin', function()
    local src = source
    if HasAdminPermission(src) then
        TriggerClientEvent('rpa-shops:client:openAdminMenu', src)
    else
        exports['rpa-lib']:Notify(src, 'No permission', 'error')
    end
end)

-- ============================================
-- SHOP ITEMS
-- ============================================

RegisterNetEvent('rpa-shops:server:getShopItems', function(shopId)
    local src = source
    local shop = Shops[shopId]
    
    if not shop then
        exports['rpa-lib']:Notify(src, 'Shop not found', 'error')
        return
    end
    
    local items = ShopItems[shopId] or {}
    local canManage = CanManageShop(src, shop)
    
    TriggerClientEvent('rpa-shops:client:openShopMenu', src, shopId, items, canManage)
end)

-- ============================================
-- PURCHASE
-- ============================================

RegisterNetEvent('rpa-shops:server:buy', function(shopId, itemName, quantity)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    local shop = Shops[shopId]
    if not shop then
        exports['rpa-lib']:Notify(src, 'Shop not found', 'error')
        return
    end
    
    local items = ShopItems[shopId] or {}
    local itemData = nil
    
    for _, item in ipairs(items) do
        if item.name == itemName then
            itemData = item
            break
        end
    end
    
    if not itemData then
        exports['rpa-lib']:Notify(src, 'Item not found', 'error')
        return
    end
    
    quantity = quantity or 1
    local total = itemData.price * quantity
    
    -- Apply tax
    if Config.Settings.purchaseTax > 0 then
        total = math.ceil(total * (1 + Config.Settings.purchaseTax / 100))
    end
    
    -- Check money
    local cash = player.PlayerData.money.cash or 0
    local bank = player.PlayerData.money.bank or 0
    
    local paymentType = nil
    if cash >= total then
        paymentType = 'cash'
    elseif bank >= total then
        paymentType = 'bank'
    else
        exports['rpa-lib']:Notify(src, 'Not enough money ($' .. total .. ' required)', 'error')
        return
    end
    
    -- Process payment
    player.Functions.RemoveMoney(paymentType, total, 'shop-purchase')
    
    -- Give item
    local success = player.Functions.AddItem(itemName, quantity)
    
    if success then
        TriggerClientEvent('inventory:client:ItemBox', src, exports['rpa-lib']:GetFramework().Shared.Items[itemName], 'add', quantity)
        exports['rpa-lib']:Notify(src, 'Purchased ' .. quantity .. 'x ' .. itemData.label .. ' for $' .. total, 'success')
        
        -- Add to shop revenue (for player/job owned shops)
        if shop.owner or shop.ownerJob then
            local ownerCut = math.floor(total * (Config.PlayerShops.ownerCut / 100))
            MySQL.update('UPDATE rpa_shops SET revenue = revenue + ? WHERE id = ?', { ownerCut, shopId })
            Shops[shopId].revenue = (Shops[shopId].revenue or 0) + ownerCut
        end
        
        -- Log purchase
        if Config.Settings.logPurchases then
            print('[rpa-shops] Player ' .. src .. ' bought ' .. quantity .. 'x ' .. itemName .. ' from ' .. shop.label .. ' for $' .. total)
        end
    else
        -- Refund if failed
        player.Functions.AddMoney(paymentType, total, 'shop-refund')
        exports['rpa-lib']:Notify(src, 'Purchase failed - inventory full?', 'error')
    end
end)

-- ============================================
-- ITEM MANAGEMENT
-- ============================================

RegisterNetEvent('rpa-shops:server:addItem', function(shopId, itemData)
    local src = source
    local shop = Shops[shopId]
    
    if not shop then return end
    if not CanManageShop(src, shop) then
        exports['rpa-lib']:Notify(src, 'No permission', 'error')
        return
    end
    
    -- Validate item exists in framework
    local Framework = exports['rpa-lib']:GetFramework()
    if Framework and Framework.Shared and Framework.Shared.Items then
        if not Framework.Shared.Items[itemData.name] then
            exports['rpa-lib']:Notify(src, 'Item "' .. itemData.name .. '" does not exist', 'error')
            return
        end
    end
    
    -- Add to cache
    if not ShopItems[shopId] then
        ShopItems[shopId] = {}
    end
    
    -- Check if already exists
    for _, item in ipairs(ShopItems[shopId]) do
        if item.name == itemData.name then
            exports['rpa-lib']:Notify(src, 'Item already exists in shop', 'error')
            return
        end
    end
    
    table.insert(ShopItems[shopId], itemData)
    
    -- Save to database
    MySQL.insert('INSERT INTO rpa_shop_items (shop_id, item_name, item_label, price) VALUES (?, ?, ?, ?)', {
        shopId,
        itemData.name,
        itemData.label,
        itemData.price
    })
    
    exports['rpa-lib']:Notify(src, 'Item added to shop', 'success')
    
    -- Refresh menu
    TriggerClientEvent('rpa-shops:client:openShopMenu', src, shopId, ShopItems[shopId], true)
end)

RegisterNetEvent('rpa-shops:server:updateItem', function(shopId, itemName, updates)
    local src = source
    local shop = Shops[shopId]
    
    if not shop then return end
    if not CanManageShop(src, shop) then
        exports['rpa-lib']:Notify(src, 'No permission', 'error')
        return
    end
    
    -- Update cache
    for i, item in ipairs(ShopItems[shopId]) do
        if item.name == itemName then
            if updates.price then
                ShopItems[shopId][i].price = updates.price
            end
            if updates.label then
                ShopItems[shopId][i].label = updates.label
            end
            break
        end
    end
    
    -- Update database
    if updates.price then
        MySQL.update('UPDATE rpa_shop_items SET price = ? WHERE shop_id = ? AND item_name = ?', { updates.price, shopId, itemName })
    end
    if updates.label then
        MySQL.update('UPDATE rpa_shop_items SET item_label = ? WHERE shop_id = ? AND item_name = ?', { updates.label, shopId, itemName })
    end
    
    exports['rpa-lib']:Notify(src, 'Item updated', 'success')
end)

RegisterNetEvent('rpa-shops:server:removeItem', function(shopId, itemName)
    local src = source
    local shop = Shops[shopId]
    
    if not shop then return end
    if not CanManageShop(src, shop) then
        exports['rpa-lib']:Notify(src, 'No permission', 'error')
        return
    end
    
    -- Remove from cache
    for i, item in ipairs(ShopItems[shopId]) do
        if item.name == itemName then
            table.remove(ShopItems[shopId], i)
            break
        end
    end
    
    -- Remove from database
    MySQL.query('DELETE FROM rpa_shop_items WHERE shop_id = ? AND item_name = ?', { shopId, itemName })
    
    exports['rpa-lib']:Notify(src, 'Item removed', 'success')
    
    -- Refresh menu
    TriggerClientEvent('rpa-shops:client:openShopMenu', src, shopId, ShopItems[shopId], true)
end)

-- ============================================
-- SHOP MANAGEMENT
-- ============================================

RegisterNetEvent('rpa-shops:server:createShop', function(shopData)
    local src = source
    
    if not HasAdminPermission(src) then
        exports['rpa-lib']:Notify(src, 'No permission', 'error')
        return
    end
    
    if Shops[shopData.id] then
        exports['rpa-lib']:Notify(src, 'Shop ID already exists', 'error')
        return
    end
    
    local newShop = {
        id = shopData.id,
        category = shopData.category,
        label = shopData.label,
        coords = shopData.coords,
        heading = shopData.heading or 0,
        owner = nil,
        ownerJob = nil,
        revenue = 0
    }
    
    Shops[shopData.id] = newShop
    SaveShopToDatabase(newShop)
    
    -- Add default items from category
    local category = Config.Categories[shopData.category]
    if category and category.defaultItems then
        ShopItems[shopData.id] = {}
        for _, item in ipairs(category.defaultItems) do
            table.insert(ShopItems[shopData.id], {
                name = item.name,
                label = item.label,
                price = item.price
            })
        end
        SaveShopItems(shopData.id, ShopItems[shopData.id])
    end
    
    TriggerClientEvent('rpa-shops:client:syncShops', -1, Shops)
    exports['rpa-lib']:Notify(src, 'Shop "' .. shopData.label .. '" created', 'success')
end)

RegisterNetEvent('rpa-shops:server:deleteShop', function(shopId)
    local src = source
    
    if not HasAdminPermission(src) then
        exports['rpa-lib']:Notify(src, 'No permission', 'error')
        return
    end
    
    if not Shops[shopId] then
        exports['rpa-lib']:Notify(src, 'Shop not found', 'error')
        return
    end
    
    local label = Shops[shopId].label
    
    -- Remove from database (cascade will delete items)
    MySQL.query('DELETE FROM rpa_shops WHERE id = ?', { shopId })
    
    -- Remove from cache
    Shops[shopId] = nil
    ShopItems[shopId] = nil
    
    TriggerClientEvent('rpa-shops:client:syncShops', -1, Shops)
    exports['rpa-lib']:Notify(src, 'Shop "' .. label .. '" deleted', 'success')
end)

RegisterNetEvent('rpa-shops:server:moveShop', function(shopId, coords, heading)
    local src = source
    
    if not HasAdminPermission(src) then
        exports['rpa-lib']:Notify(src, 'No permission', 'error')
        return
    end
    
    if not Shops[shopId] then return end
    
    Shops[shopId].coords = coords
    Shops[shopId].heading = heading
    
    MySQL.update('UPDATE rpa_shops SET coords_x = ?, coords_y = ?, coords_z = ?, heading = ? WHERE id = ?', {
        coords.x, coords.y, coords.z, heading, shopId
    })
    
    TriggerClientEvent('rpa-shops:client:syncShops', -1, Shops)
    exports['rpa-lib']:Notify(src, 'Shop moved', 'success')
end)

RegisterNetEvent('rpa-shops:server:updateShopSettings', function(shopId, settings)
    local src = source
    local shop = Shops[shopId]
    
    if not shop then return end
    if not CanManageShop(src, shop) then
        exports['rpa-lib']:Notify(src, 'No permission', 'error')
        return
    end
    
    if settings.label then
        Shops[shopId].label = settings.label
        MySQL.update('UPDATE rpa_shops SET label = ? WHERE id = ?', { settings.label, shopId })
    end
    
    if settings.heading then
        Shops[shopId].heading = settings.heading
        MySQL.update('UPDATE rpa_shops SET heading = ? WHERE id = ?', { settings.heading, shopId })
    end
    
    TriggerClientEvent('rpa-shops:client:syncShops', -1, Shops)
    exports['rpa-lib']:Notify(src, 'Shop settings updated', 'success')
end)

RegisterNetEvent('rpa-shops:server:getRevenue', function(shopId)
    local src = source
    local shop = Shops[shopId]
    
    if not shop then return end
    if not CanManageShop(src, shop) then
        exports['rpa-lib']:Notify(src, 'No permission', 'error')
        return
    end
    
    exports['rpa-lib']:Notify(src, 'Shop Revenue: $' .. (shop.revenue or 0), 'info')
end)

-- ============================================
-- PLAYER JOIN
-- ============================================

AddEventHandler('playerJoining', function()
    local src = source
    Wait(3000)
    TriggerClientEvent('rpa-shops:client:syncShops', src, Shops)
end)

print('[rpa-shops] Server loaded')
