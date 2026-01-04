Config = {}

-- ============================================
-- PERMISSION CONFIGURATION
-- ============================================

-- Admin permissions (manage all shops, categories, items)
Config.AdminPermissions = {
    groups = { 'admin', 'god' },
    jobs = {},
    minGrade = 0,
    onDuty = false,
    convar = 'rpa:admins',
    resourceConvar = 'admin'
}

-- ============================================
-- SHOP CATEGORIES (Templates)
-- Categories allow quick creation of similar shop types
-- ============================================

Config.Categories = {
    ['247'] = {
        label = '24/7 Convenience Store',
        icon = 'fas fa-store',
        pedModel = 'mp_m_shopkeep_01',
        blip = { sprite = 52, color = 2, scale = 0.7 },
        defaultItems = {
            { name = 'sandwich', price = 5, label = 'Sandwich' },
            { name = 'water', price = 2, label = 'Water Bottle' },
            { name = 'coffee', price = 3, label = 'Coffee' },
            { name = 'donut', price = 3, label = 'Donut' },
            { name = 'bandage', price = 50, label = 'Bandage' },
            { name = 'phone', price = 500, label = 'Phone' },
            { name = 'radio', price = 250, label = 'Radio' },
            { name = 'lighter', price = 5, label = 'Lighter' },
        }
    },
    ['liquor'] = {
        label = 'Liquor Store',
        icon = 'fas fa-wine-bottle',
        pedModel = 'a_m_m_hillbilly_01',
        blip = { sprite = 93, color = 17, scale = 0.7 },
        defaultItems = {
            { name = 'beer', price = 5, label = 'Beer' },
            { name = 'whiskey', price = 15, label = 'Whiskey' },
            { name = 'vodka', price = 12, label = 'Vodka' },
            { name = 'wine', price = 20, label = 'Wine' },
            { name = 'cigarettes', price = 10, label = 'Cigarettes' },
        }
    },
    ['hardware'] = {
        label = 'Hardware Store',
        icon = 'fas fa-tools',
        pedModel = 's_m_m_autoshop_01',
        blip = { sprite = 566, color = 46, scale = 0.7 },
        defaultItems = {
            { name = 'repairkit', price = 250, label = 'Repair Kit' },
            { name = 'cleaningkit', price = 150, label = 'Cleaning Kit' },
            { name = 'lockpick', price = 100, label = 'Lockpick' },
            { name = 'binoculars', price = 50, label = 'Binoculars' },
        }
    },
    ['clothing'] = {
        label = 'Clothing Store',
        icon = 'fas fa-tshirt',
        pedModel = 's_f_y_shop_low',
        blip = { sprite = 73, color = 4, scale = 0.7 },
        defaultItems = {}
    },
    ['ammunition'] = {
        label = 'Ammunition Store',
        icon = 'fas fa-crosshairs',
        pedModel = 's_m_y_ammucity_01',
        blip = { sprite = 110, color = 1, scale = 0.8 },
        defaultItems = {
            { name = 'pistol_ammo', price = 100, label = 'Pistol Ammo (x12)' },
            { name = 'smg_ammo', price = 150, label = 'SMG Ammo (x30)' },
            { name = 'rifle_ammo', price = 200, label = 'Rifle Ammo (x30)' },
            { name = 'shotgun_ammo', price = 100, label = 'Shotgun Ammo (x8)' },
        }
    },
    ['electronics'] = {
        label = 'Electronics Store',
        icon = 'fas fa-laptop',
        pedModel = 's_m_m_strvend_01',
        blip = { sprite = 521, color = 3, scale = 0.7 },
        defaultItems = {
            { name = 'phone', price = 500, label = 'Phone' },
            { name = 'radio', price = 250, label = 'Radio' },
            { name = 'gps', price = 150, label = 'GPS' },
            { name = 'camera', price = 300, label = 'Camera' },
        }
    },
    ['restaurant'] = {
        label = 'Restaurant',
        icon = 'fas fa-utensils',
        pedModel = 's_f_y_sweatshop_01',
        blip = { sprite = 93, color = 1, scale = 0.7 },
        defaultItems = {
            { name = 'burger', price = 10, label = 'Burger' },
            { name = 'fries', price = 5, label = 'Fries' },
            { name = 'soda', price = 3, label = 'Soda' },
            { name = 'water', price = 2, label = 'Water' },
        }
    },
    ['custom'] = {
        label = 'Custom Shop',
        icon = 'fas fa-shopping-bag',
        pedModel = 'mp_m_shopkeep_01',
        blip = { sprite = 52, color = 0, scale = 0.7 },
        defaultItems = {}
    },
}

-- ============================================
-- DEFAULT SHOP INSTANCES
-- These are loaded if database is empty
-- ============================================

Config.DefaultShops = {
    {
        id = '247_strawberry',
        category = '247',
        label = '24/7 Strawberry',
        coords = vector3(25.7, -1347.0, 29.4),
        heading = 270.0,
        owner = nil, -- nil = NPC owned, or citizenid for player owned
        ownerJob = nil, -- Job that owns this shop (for job-owned shops)
        customItems = nil, -- nil = use category defaults
    },
    {
        id = '247_grove',
        category = '247',
        label = '24/7 Grove Street',
        coords = vector3(-47.0, -1758.0, 29.4),
        heading = 45.0,
        owner = nil,
        ownerJob = nil,
        customItems = nil,
    },
    {
        id = 'liquor_mirror',
        category = 'liquor',
        label = 'Mirror Park Liquor',
        coords = vector3(1135.0, -982.0, 46.4),
        heading = 0.0,
        owner = nil,
        ownerJob = nil,
        customItems = nil,
    },
}

-- ============================================
-- SHOP SETTINGS
-- ============================================

Config.Settings = {
    -- Distance to interact with shop
    interactDistance = 2.5,
    
    -- Tax on purchases (percentage)
    purchaseTax = 0,
    
    -- Max items per purchase
    maxPurchaseQuantity = 100,
    
    -- Enable shop robbery (requires additional setup)
    robberyEnabled = false,
    
    -- Save purchases to logs
    logPurchases = true,
    
    -- Admin command
    adminCommand = 'shopadmin',
    
    -- Debug mode
    debug = false,
}

-- ============================================
-- PLAYER-OWNED SHOP SETTINGS
-- ============================================

Config.PlayerShops = {
    enabled = true,
    
    -- Jobs that can own shops
    ownerJobs = {
        'realestate',
        'business',
    },
    
    -- Max shops a player can own
    maxShopsPerPlayer = 3,
    
    -- Shop purchase price
    purchasePrice = 50000,
    
    -- Daily upkeep cost
    dailyUpkeep = 500,
    
    -- Owner gets this percentage of sales
    ownerCut = 70, -- 70%
}

-- ============================================
-- JOB-OWNED SHOPS
-- Shops that are managed by job employees
-- ============================================

Config.JobShops = {
    enabled = true,
    
    -- Jobs that can manage their shops' inventory
    managerGrade = 3, -- Grade 3+ can manage items
    
    -- Jobs and their shop categories
    jobCategories = {
        ['burgershot'] = {
            category = 'restaurant',
            customItems = {
                { name = 'burger', price = 10, label = 'Burger Shot Burger' },
                { name = 'bleeder', price = 15, label = 'Heart Stopper' },
                { name = 'fries', price = 5, label = 'Freedom Fries' },
                { name = 'soda', price = 3, label = 'eCola' },
            }
        },
        ['pizzathis'] = {
            category = 'restaurant',
            customItems = {
                { name = 'pizza', price = 15, label = 'Pizza' },
                { name = 'soda', price = 3, label = 'Sprunk' },
            }
        },
    }
}
