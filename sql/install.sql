-- hbs-tow schema. Run once on install.

CREATE TABLE IF NOT EXISTS `hbs_tow_boots` (
    `plate` VARCHAR(8) NOT NULL,
    `applied_by` VARCHAR(50) NOT NULL,
    `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `fine` INT NOT NULL DEFAULT 0,
    `reason` VARCHAR(255),
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `hbs_tow_stats` (
    `citizenid` VARCHAR(50) NOT NULL,
    `jobs_completed` INT NOT NULL DEFAULT 0,
    `total_earned` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
