# rpa-shops

<div align="center">

![GitHub Release](https://img.shields.io/github/v/release/RP-Alpha/rpa-shops?style=for-the-badge&logo=github&color=blue)
![GitHub commits](https://img.shields.io/github/commits-since/RP-Alpha/rpa-shops/latest?style=for-the-badge&logo=git&color=green)
![License](https://img.shields.io/github/license/RP-Alpha/rpa-shops?style=for-the-badge&color=orange)
![Downloads](https://img.shields.io/github/downloads/RP-Alpha/rpa-shops/total?style=for-the-badge&logo=github&color=purple)

**Config-Driven Shop System**

</div>

---

## ✨ Features

- ⚙️ **Config Driven** - Add shops via simple Lua config
- 🧑 **Ped Spawning** - Automatic shopkeeper NPCs
- 🎨 **Modern UI** - Clean grid-based item display
- 🎯 **Target Integration** - Third Eye to interact

---

## 📥 Installation

1. Download the [latest release](https://github.com/RP-Alpha/rpa-shops/releases/latest)
2. Extract to your `resources` folder
3. Add to `server.cfg`:
   ```cfg
   ensure rpa-shops
   ```

---

## ⚙️ Configuration

Add shops in `config.lua`:

```lua
Config.Shops = {
    ['247supermarket'] = {
        label = "24/7 Supermarket",
        coords = vector3(x, y, z),
        ped = 'mp_m_shopkeep_01',
        items = {
            { name = 'water', price = 5 },
            { name = 'bread', price = 3 }
        }
    }
}
```

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

<div align="center">
  <sub>Built with ❤️ by <a href="https://github.com/RP-Alpha">RP-Alpha</a></sub>
</div>
