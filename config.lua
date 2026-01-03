Config = {}

Config.Shops = {
    ['247_supermarket'] = {
        label = "24/7 Supermarket",
        type = "shop", -- or 'bar', 'weapon'
        coords = vector3(25.7, -1347.0, 29.4),
        model = 'mp_m_shopkeep_01', -- Ped model
        blip = { label = '24/7', sprite = 52, color = 2, scale = 0.8 },
        items = {
            { name = "sandwich", price = 5, label = "Sandwich" },
            { name = "water", price = 2, label = "Water Bottle" },
            { name = "phone", price = 500, label = "Smartphone" },
        }
    }
}
