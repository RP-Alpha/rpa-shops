-- RP-Alpha Shop System Database Schema
-- Tables are auto-created by the resource

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
);

CREATE TABLE IF NOT EXISTS `rpa_shop_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `shop_id` VARCHAR(50) NOT NULL,
    `item_name` VARCHAR(50) NOT NULL,
    `item_label` VARCHAR(100) NOT NULL,
    `price` INT NOT NULL,
    UNIQUE KEY `shop_item` (`shop_id`, `item_name`),
    FOREIGN KEY (`shop_id`) REFERENCES `rpa_shops`(`id`) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_shop_category ON rpa_shops(category);
CREATE INDEX IF NOT EXISTS idx_shop_owner ON rpa_shops(owner_citizenid);
CREATE INDEX IF NOT EXISTS idx_shop_job ON rpa_shops(owner_job);
