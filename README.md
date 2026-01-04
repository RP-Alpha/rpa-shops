# rpa-shops

<div align="center">

![GitHub Release](https://img.shields.io/github/v/release/RP-Alpha/rpa-shops?style=for-the-badge&logo=github&color=blue)
![GitHub commits](https://img.shields.io/github/commits-since/RP-Alpha/rpa-shops/latest?style=for-the-badge&logo=git&color=green)
![License](https://img.shields.io/github/license/RP-Alpha/rpa-shops?style=for-the-badge&color=orange)
![Downloads](https://img.shields.io/github/downloads/RP-Alpha/rpa-shops/total?style=for-the-badge&logo=github&color=purple)

**Dynamic Shop System with Categories & Player-Owned Shops**

</div>

---

## ✨ Features

- 📂 **Shop Categories** - 24/7, Liquor, Hardware, Clothing, Ammunition, Electronics, Restaurant
- 🏪 **Player-Owned Shops** - Purchase and manage shops by job
- 💰 **Revenue Tracking** - Owners earn percentage of all sales
- 🛠️ **In-Game Item Editing** - Add, remove, and price items without restart
- 👨‍💼 **Admin Menu** - Create/edit/delete shops in-game
- 🧑 **Ped Spawning** - Automatic shopkeeper NPCs
- 🎯 **Target Integration** - Third Eye to interact
- 💾 **Database Persistence** - All shops and items stored in MySQL
- 🔐 **Permission System** - Role-based management access

---

## 📦 Dependencies

- `rpa-lib` (Required)
- `ox_lib` (Required)
- `oxmysql` (Required)
- `ox_target` or `qb-target` (Recommended)

---

## 📥 Installation

1. Download the [latest release](https://github.com/RP-Alpha/rpa-shops/releases/latest)
2. Extract to your `resources` folder
3. Import the database:
   ```sql
   source sql/install.sql
   ```
4. Add to `server.cfg`:
   ```cfg
   ensure rpa-lib
   ensure rpa-shops
   ```

---

## 🗄️ Database Setup

Run the SQL file to create:
- `rpa_shops` - Shop locations, owners, and settings
- `rpa_shop_items` - Items available at each shop

---

## ⚙️ Configuration

### Shop Categories

Categories define default items for new shops:

```lua
Config.Categories = {
    ['247'] = {
        label = "24/7 Convenience",
        ped = 'mp_m_shopkeep_01',
        defaultItems = {
            { name = 'water', price = 5, stock = -1 },
            { name = 'sandwich', price = 8, stock = -1 },
            { name = 'bandage', price = 50, stock = 10 }
        }
    }
}
```

### Player-Owned Shops

```lua
Config.PlayerShops = {
    enabled = true,
    ownerJobs = { 'realestate', 'government' },
    maxShopsPerPlayer = 3,
    purchasePrice = 50000,
    ownerCut = 70  -- Owner gets 70% of sales
}
```

### Admin Permissions

```lua
Config.AdminPermissions = {
    groups = { 'admin', 'god' },
    jobs = {},
    convar = 'rpa:admins',
    resourceConvar = 'admin'
}
```

---

## ⌨️ Commands

| Command | Description |
|---------|-------------|
| `/shopsadmin` | Open admin shop management menu |
| `/manageshop` | Open owner shop management (at owned shop) |

---

## 📂 Available Categories

| Category | Default Items |
|----------|---------------|
| `247` | Water, food, bandages, phone |
| `liquor` | Beer, wine, whiskey, vodka |
| `hardware` | Flashlight, binoculars, lighter, lockpick |
| `clothing` | Various clothing items |
| `ammunition` | Ammo types (job-restricted) |
| `electronics` | Phone, radio, camera |
| `restaurant` | Food and drink items |
| `custom` | Empty (for custom shops) |

---

## 🔐 Permissions

- **Admin** - Create/delete shops, manage all items
- **Shop Owner** - Manage items and prices at owned shops
- **Job-Based** - Some categories restricted by job

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

<div align="center">
  <sub>Built with ❤️ by <a href="https://github.com/RP-Alpha">RP-Alpha</a></sub>
</div>
